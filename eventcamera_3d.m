%% calibration
frequency_0 = 1;
interval_0 = 1e6/frequency_0;
calibrateImagesNum = 16;
squareSize = 12.5;

[allAddr_v,allT_v] = loadaerdat('F:\THU\DAVIS\recording\20191209\vertical6s\DAVIS240C-2019-12-09T14-55-36+0800-02460093-0.aedat'); % vertical scan
[allAddr_h,allT_h] = loadaerdat('F:\THU\DAVIS\recording\20191209\horizontal6s\DAVIS240C-2019-12-09T15-05-13+0800-02460093-0.aedat'); % horizontal scan
[stereo_params,imageSize] = calibrate(interval_0,calibrateImagesNum,squareSize,allAddr_v,allT_v,allAddr_h,allT_h);

%% Calculate disparity

frequency_1 = 1;  % plane
frequency_2 = 1;  % david

interval_1 = 1e6 / frequency_1; % plane
interval_2 = 1e6 / frequency_2; % david

% Load events from file
% allAddr表示所有DAVIS事件地址 allTs表示所有DAVIS事件时间 均为32bit
%[allAddr_p,allT_p] = loadaerdat('F:\THU\DAVIS\recording\20190805\vertical1s\DAVIS240C-2019-08-05T10-02-58+0800-02460093-0.aedat'); % plane sigle-scan
[allAddr,allT] = loadaerdat('F:\THU\DAVIS\recording\20191213\700lux\DAVIS240C-2019-12-13T22-03-05+0800-02460093-0.aedat'); % david

% Seperate DVS events from DAVIS 
[x_,y_,t_] = getDVSeventsFromDAVIS(allAddr_v,allT_v,interval_1);
[x,y,t] = getDVSeventsFromDAVIS(allAddr,allT,interval_2);

% Calculate the disparity for each event - 锯齿波
d_ = 240*mod(t_,interval_1)/interval_1-x_;  % plane
%d = -7+255*mod(t,interval_2)/interval_2-x;     % ball  %系数调整考虑的是记录数据的初始偏差 下面还加入了偏差矩阵
d = -10+240*mod(t,interval_2)/interval_2-x; % david

% Compile events into a disparity sequence
D_ = disparityList2Map(x_,y_,t_,d_,interval_1);
D = disparityList2Map(x,y,t,d,interval_2);

% Obtain the single disparity map D1_ & D1 by single sweep/average multiple scan/median multiple scan
% single sweep
D1 = D(:,:,1);
% multiple scan - average
D1_=mean(D_(:,:,1:end-1),3);

% 将D1中无数据的点用D1_相应点补充
k=find(~D1);
for i=1:length(k)
    D1(k(i))=D1_(k(i));
end 

% Calculate bias array from D1_ and apply it to D1
m_=median(median(D1_));
bias_=D1_-m_;
D1=D1-bias_;

% Median filtering is performed on the single biased disparity map D1
D2=medfilt2(D1,[5,5]); 

% % 去除视差图中为零的点
[p,q]=find(~D2);
for i=1:length(p)
    if(q(i)==1)
        for k=2:180
            if(D2(p(i),k))
                D2(p(i),q(i))=D2(p(i),k);
                break;
            end
        end
    else
        D2(p(i),q(i))=D2(p(i),q(i)-1);
    end
end

% figure
% imagesc(D2);
% colorbar
% title('D2 - mediflt2 biased single disparity map');

% 3d reconstruction, using the modified function
[Hleft,Hright,Q,xBounds,yBounds] = computeRectificationParameters(stereo_params,imageSize,'full');
[X3,Y3,Z3] = reconstruct_Scene(D2,stereo_params,Q);
original_pointCloud = cat(3, X3, Y3, Z3);

% Visualization and save
% 将点云放到240*180的xy区域上面
dd=reshape(Z3,240*180,1);
temp=[];
for i1=1:180
    for i2=1:240
        temp=[temp;[i2 i1 Z3(i2,i1)]];
    end
end

%原始点云
pre_pointCloud = pointCloud(temp);
% figure
% pcshow(pre_pointCloud)
% xlabel('X(mm)')
% ylabel('Y(mm)')
% zlabel('Z(mm)')
% title('Original Point Cloud')

% 感兴趣部分点云
%roi = [30 240 40 180 -155 -105]; % ball
%roi=[30 110 60 120 -200 -80];
roi=[5 180 10 170 -170 0];
sampleIndices = findPointsInROI(pre_pointCloud,roi);
sample = select(pre_pointCloud,sampleIndices);
figure('Color','white')
pcshow(sample)
% view(-30,80)
% axis off
% set(gca,'unit','centimeters','position',[0,0,4,4])
% set(gcf,'unit','centimeters','position',[0,0,4,4])
% fig = gcf;
% fig.PaperPositionMode = 'auto'
% fig_pos = fig.PaperPosition;
% fig.PaperSize=[fig_pos(3) fig_pos(4)];
% print(fig,'Figure','-dpdf')

% 储存感兴趣部分点云
% txt_path = ['./' 'world_coordinates' '/txt/'];
% if exist(txt_path)~=7
%     mkdir(txt_path);
% end
% txt_name = [txt_path 'XYZ_''.txt'];
% fop=fopen(txt_name,'wt');
% N=length(sample.Location);
% for m=1:N
%     fprintf(fop,'%s %s %s\n',mat2str(sample.Location(m,1)),mat2str(sample.Location(m,2)),mat2str(sample.Location(m,3)));
%     fprintf(fop,'\n');
% end
% fclose(fop);
% disp(['save' txt_path 'XYZ_''.txt finished']);

% 计算重建精度——球体拟合
% % 以固定的半径拟合球体 x0,y0,z0：拟合球心；rErr：每个测量点的误差
% [x0,y0,z0,rErr]=fitSphere(sample.Location(:,1),sample.Location(:,2),sample.Location(:,3),45);
% meanError = mean(rErr);
% RMSE=sqrt(sum(rErr.^2,'all')./length(rErr));
% 
% zMin = min(sample.Location(:,3));
% zMax = max(sample.Location(:,3));
% xMin = min(sample.Location(:,1));
% xMax = max(sample.Location(:,1));
% yMin = min(sample.Location(:,2));
% yMax = max(sample.Location(:,2));
% 
% error_zMin = min(rErr);
% error_zMax = max(rErr);

% 球体拟合的可视化结果——用于论文
% [Y,X] = meshgrid(1:180,1:240);
% DDepth=griddata(sample.Location(:,1),sample.Location(:,2),sample.Location(:,3),X,Y,'linear');
% errormap=griddata(sample.Location(:,1),sample.Location(:,2),rErr,X,Y,'linear');
% DDepth=medfilt2(DDepth,[3,3]);

% figure
% surf(X,Y,DDepth,'FaceColor','interp','EdgeColor','none','FaceLighting','gouraud');
% shading interp;
% set(gca,'DataAspectRatio',[1,1,1])
% axis off
% colormap(jet);
% %colormap(flipud(jet));
% material([0.3 0.6 0.5])
% view(2)
% disp(['drawing 3d finished.']);
% fig1 = gcf;
% fig1.PaperPositionMode = 'auto'
% fig_pos1 = fig1.PaperPosition;
% fig1.PaperSize=[fig_pos1(3) fig_pos1(4)];
% print(fig1,'proposed_colorful','-dpdf')

% figure
% color = zeros(240,180,3);
% color(:,:,1)=117/255;
% color(:,:,2)=202/255;
% color(:,:,3)=255/255;
% surf(X,Y,DDepth,color);
% shading interp;
% set(gca, 'DataAspectRatio', [1, 1, 1])
% axis off
% material([0.28 0.48 0.25])
% view(2)
% camlight right
% fig2 = gcf;
% fig2.PaperPositionMode = 'auto'
% fig_pos2 = fig2.PaperPosition;
% fig2.PaperSize=[fig_pos2(3) fig_pos2(4)];
% print(fig2,'proposed_blue','-dpdf')
% set(gcf,'position',[0 0 460 460],'PaperSize',[13,13])
% print('proposed_blue','-dpdf');

% error map
% figure
% surf(X,Y,errormap,'FaceColor','interp','EdgeColor','none','FaceLighting','gouraud');
% shading interp;
% set(gca,'DataAspectRatio',[1,1,1])
% axis off;
% colormap(jet);
% c = colorbar;
% c.Ticks=floor(linspace(-10,10,5));
% caxis([-10 10])
% c.FontSize = 15;
% xlabel(c,'(mm)');
% material([0.3 0.6 0.5])
% view(2)
% disp(['drawing 3d finished.']);
% fig3 = gcf;
% fig3.PaperPositionMode = 'auto'
% fig_pos3 = fig3.PaperPosition;
% fig3.PaperSize=[fig_pos3(3) fig_pos3(4)];
% print(fig3,'proposed_errormap','-dpdf')
% % set(gcf,'position',[0 0 500 500],'PaperSize',[13,13])
% % print('proposed_errormap','-dpdf');

% 人脸重建可视化
zMin = min(sample.Location(:,3));
zMax = max(sample.Location(:,3));
xMin = min(sample.Location(:,1));
xMax = max(sample.Location(:,1));
yMin = min(sample.Location(:,2));
yMax = max(sample.Location(:,2));

temp1=zeros(yMax-yMin+1,xMax-xMin+1)*nan;
for i = 1:length(sample.Location(:,3))
    p=sample.Location(i,1)-xMin+1;
    q=sample.Location(i,2)-yMin+1;
    temp1(q,p)=sample.Location(i,3);
end
temp1=medfilt2(temp1,[5,5]);

figure
color = zeros(yMax-yMin+1,xMax-xMin+1,3);
color(:,:,1)=117/255;
color(:,:,2)=202/255;
color(:,:,3)=255/255;
surf(temp1,color)
shading interp;
set(gca, 'DataAspectRatio', [1, 1, 1])
axis off
material([0.28 0.48 0.25])
view(2)
camlight right
fig4 = gcf;
fig4.PaperPositionMode = 'auto'
fig_pos4 = fig4.PaperPosition;
fig4.PaperSize=[fig_pos4(3) fig_pos4(4)];
print(fig4,'face_proposed','-dpdf')

% 储存感兴趣部分点云
txt_path = ['./' 'world_coordinates' '/txt/'];
if exist(txt_path)~=7
    mkdir(txt_path);
end
txt_name = [txt_path 'face_proposed''.txt'];
mat2txt(txt_name,temp1);
