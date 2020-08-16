function [ x0,y0,z0,rErr] = fitSphere( x,y,z,rFixed)
% 
% xyzMask=x.*y.*z;
% ptTmp=zeros(size(find(xyzMask~=0),1),3);
% j=0;
% for i=1:size(xyzMask,1)*size(xyzMask,2)
%     if xyzMask(i)~=0
%         j=j+1;
%         ptTmp(j,:)=[x(i) y(i) z(i)];
%     end
% end


xyzMask=x.*y.*z;
ptTmp=zeros(size(find(~isnan(xyzMask)),1),3);
j=0;
for i=1:size(xyzMask,1)*size(xyzMask,2)
    if ~isnan(xyzMask(i))
        j=j+1;
        ptTmp(j,:)=[x(i) y(i) z(i)];
    end
end

% pt=pointCloud([x(:),y(:),z(:)]);
% sampleIndices = findPointsInROI(pt,roi);
% 
% [model,inlierIndices,outlierIndices,fitError] = pcfitsphere(pt,maxDis,...
%             'SampleIndices',sampleIndices,'MaxNumTrials',10000,'Confidence' ,99);
%          
% x0=model.Center(1);
% y0=model.Center(2);
% z0=model.Center(3);
% radius=model.Radius;

%use this for finding an initial value
[centerInitial rInitial]=fitSphere2(ptTmp);

[center]=fitSphere3(ptTmp,centerInitial,rFixed);

x0=center(1);
y0=center(2);
z0=center(3);


rFitted=sqrt((x-x0).^2+(y-y0).^2+(z-z0).^2);%每个测量点到拟合球心的距离
rErr=rFitted-rFixed; %每个测量点到球体表面的误差距离


end








