function [stereo_params,imageSize] = calibrate(interval,calibrateImagesNum,squareSize,allAddr_v,allT_v,allAddr_h,allT_h)
%% function [stereo_params,imageSize] = calibrate(interval,calibrateImagesNum,squareSize)
% interval - scan speed of calibrate images
% calibrateImagesNum - number of checkerboard images for calibration
% squareSize - checkerboard size

% This is a new idea for event camera DAVIS calibration.
% 1）通过横向和纵向的两次扫描分别确定两个时间t1和t2
% 2）这两次扫描需要得到一个平滑的较好的坐标时间图
% 3）采集棋盘图，不同的视野采集一段时间并恢复成图像帧
% 4）检测棋盘角点，通过之前的坐标时间图将camera的角点映射到projector
% 5）相机标定以及投影仪标定
% 6）联合标定
% Copyright 2019.4 ChenchenFeng, Tsinghua University. All rights reserved.

%% 通过vertical和horizontal的扫描 将相机像素的两个方向扫描时间放入D1 D2
% 将vertical scan得到的时间标签放到t1中 
[x1,y1,t1] = getDVSeventsFromDAVIS(allAddr_v,allT_v,interval);

% multiple-scan
frame1=floor(t1/interval)+1;
D1=accumarray([x1 y1 frame1],t1,[],@mean);

% single-scan
% D1 = accumarray([x1,y1],t1,[],@mean);

% 将horizontal scan得到的时间标签放到t2中 
[x2,y2,t2] = getDVSeventsFromDAVIS(allAddr_h,allT_h,interval);
frame2=floor(t2/interval)+1;
D2=accumarray([x2 y2 frame2],t2,[],@mean);
% D2 = accumarray([x2,y2],t2,[],@mean);

% 消除D1和D2中每个帧时间为零的点 对最后一帧不做处理
% 要保证D1和D2在第三维度是相等的 
for i=1:size(D1,3) -1               
    % 对于纵向的扫描 用同一列（共240列）上前面的时间值代替零值
    [m,n]=find(~D1(:,:,i));
    for j=1:length(m)
        if(n(j)==1)
            for k1=2:180
                if(D1(m(j),k1,i))
                    D1(m(j),n(j),i)=D1(m(j),k1,i);
                    break;
                end
            end
        else
            D1(m(j),n(j),i)=D1(m(j),n(j)-1,i);
        end
    end
    % 对于横向扫描 用同一行上前后的时间值代替零值
    [p,q]=find(~D2(:,:,i));
    for j=1:length(p)
        if(p(j)==1)
            for k2=2:240
                if(D2(k2,q(j),i))
                    D2(p(j),q(j),i)=D2(k2,q(j),i);
                    break;
                end
            end
        else
            D2(p(j),q(j),i)=D2(p(j)-1,q(j),i);
        end
    end
    % 对于多次扫描 需要把时间调整成0-1s之间的值
    D1(:,:,i)=D1(:,:,i)-(i-1)*1e6;            
    D2(:,:,i)=D2(:,:,i)-(i-1)*1e6;
end
% 时间单位为us 
D1=mean(D1(:,:,1:end-1),3);
D2=mean(D2(:,:,1:end-1),3);

%% Seperate APS from DAVIS and obtain frames
filename = fullfile('position.txt');
fileID = fopen(filename);
position = textscan(fileID,'%s');
for i =1:length(position{1,1})
    [frames] = getAPSframesFromDAVIS(char(position{1,1}(i,1)));
    pic_array{i} = displayAPSframes(frames);   
    save_image = sprintf('chessboard%d.png',i);
    imwrite(mat2gray(pic_array{i},[0,512]),save_image);   % 将图像矩阵生成.png格式保存
end

%% Detect Checkerboard in a Set of Image Files
% Create a cell array of file names of calibration images
for i = 1:calibrateImagesNum
    imageFileName = sprintf('chessboard%d.png',i);
    imageFileNames{i} = fullfile(imageFileName);
end

% 获取图像尺寸大小
szImage = imread(imageFileNames{1});
imageSize = [size(szImage,1)+1,size(szImage,2)+1];

% Detect calibration pattern
[imagePoints,boardSize,imagesUsed] = detectCheckerboardPoints(imageFileNames);

% Display detected points
% imageFileNames = imageFileNames(imagesUsed);
% for i = 1:length(imageFileNames)
%     I = imread(imageFileNames{i});
%     subplot(3,7,i);
%     title(sprintf('Detected a %d x %d Checkerboard',boardSize));
%     imshow(I);
%     hold on;
%     plot(imagePoints(:,1,i),imagePoints(:,2,i),'ro','MarkerSize',5);
%     hold off
% end


%% 将检测到的角点映射到MEMS Mirror得到投影仪上的角点坐标projectorPoints
% 将检测到的角点坐标取整 根据时间标签映射到MEMS Mirror
Int_imagePoints = round(imagePoints);
projectorPoints = zeros(size(Int_imagePoints,1),2,size(Int_imagePoints,3));
for j = 1:size(Int_imagePoints,3)
    for i = 1:size(Int_imagePoints,1)
        projectorPoints_x = 240*D1(Int_imagePoints(i,1,j),Int_imagePoints(i,2,j))/interval;
        projectorPoints_y = 180*D2(Int_imagePoints(i,1,j),180-Int_imagePoints(i,2,j))/interval;
        projectorPoints(i,1,j) = projectorPoints_x;
        projectorPoints(i,2,j) = projectorPoints_y;
    end
end 

%% Calibrate camera and projector
% Generate world coordinates of the corners of the checkerboard
worldPoints = generateCheckerboardPoints(boardSize,squareSize);

% Calibrate the camera
camera_params = estimateCameraParameters(imagePoints,worldPoints);
% Calibrate the projector
projector_params = estimateCameraParameters(projectorPoints,worldPoints);

% Visualize calibration accuracy
% figure;
% subplot(1,2,1);
% showReprojectionErrors(camera_params);
% title('camera-reprojection errors');
% subplot(1,2,2)
% showReprojectionErrors(projector_params);
% title('projector-reprojection errors');

% % Visualize camera extrinsics
% figure;
% subplot(1,2,1);
% showExtrinsics(camera_params, 'cameraCentric');
% title('camera-extrinsics');
% % Visualize projector extrinsics
% subplot(1,2,2);
% showExtrinsics(projector_params, 'cameraCentric');
% title('projector-extrinsics');
% drawnow;

% Plot detected and reprojected points
% figure;
% for i = 1:length(imageFileNames)
%     I = imread(imageFileNames{i});
%     subplot(3,7,i);
%     imshow(I);
%     hold on;
%     plot(imagePoints(:,1,i),imagePoints(:,2,i),'go','MarkerSize',5);
%     plot(camera_params.ReprojectedPoints(:,1,i),camera_params.ReprojectedPoints(:,2,i),'r+','MarkerSize',5);
%     xlabel('X (pixel)','FontSize',25)
%     ylabel('Y (pixel)','FontSize',25)
%     set(gca,'FontSize',25)
%     hold off
%     
%     fig3 = gcf;
%     fig3.PaperPositionMode = 'auto'
%     fig_pos2 = fig3.PaperPosition;
%     fig3.PaperSize=[fig_pos2(3) fig_pos2(4)];
%     print(fig3,'Figure_ori','-dpdf')
% end
% legend('Detected Points','ReprojectedPoints');

% figure
% for i = 10%:length(imageFileNames)
%     %subplot(3,7,i);
%     hold on;
%     plot(projectorPoints(:,1,i),projectorPoints(:,2,i),'go','LineWidth',2,'MarkerSize',10);
%     plot(projector_params.ReprojectedPoints(:,1,i),projector_params.ReprojectedPoints(:,2,i),'r+','LineWidth',2,'MarkerSize',10);
%     xlabel('X (pixel)','FontSize',25)
%     ylabel('Y (pixel)','FontSize',25)
%     set(gca,'Xlim',[20,180]);
%     set(gca,'Ylim',[40,140]);
%     set(gca,'FontSize',25)
%     hold off
%     fig2 = gcf;
%     fig2.PaperPositionMode = 'auto'
%     fig_pos2 = fig2.PaperPosition;
%     fig2.PaperSize=[fig_pos2(3) fig_pos2(4)];
%    print(fig2,'Figure-','-dpdf')
% end


%% Stereo calibration
stereo_imagePoints = cat(4,projectorPoints,imagePoints);
stereo_params = estimateCameraParameters(stereo_imagePoints,worldPoints);

% % Visualize calibration accuracy
figure
showReprojectionErrors(stereo_params);
xlabel('Checkerboard','FontSize',12)
ylabel('Reprojection Error (pixel)','FontSize',12)
set(gca,'Ylim',[0,1]);
legend('Galvanometer','Camera','Overall Mean Error','location','northeast')
% set(gca,'FontSize',12)
% %set(gcf,'PaperSize',[19 19])
% fig4 = gcf;
% fig4.PaperPositionMode = 'auto'
% fig_pos2 = fig4.PaperPosition;
% fig4.PaperSize=[fig_pos2(3) fig_pos2(4)];
% print(fig4,'Figure2','-dpdf')

% % Visualize camera extrinsics
% figure;
% showExtrinsics(stereo_params);
% title('stereo-extrinsics');

end
