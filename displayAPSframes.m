function pic_array = displayAPSframes(frames, time_interval)
%% function pic_array = displayAPSframes(frames,time_interval)
% diplay frames with a fixed time interval
% frames - obtained from getAPSframesFromDAVIS
% time_interval  - optional param. time interval between frames

if nargin < 2
   time_interval = 0.1;
end

[chan, x, y, numFrames] = size(frames);     %get infos on frames
bw_cdsSignal = 3;                           %here are stored the bw values (resetbuffer - readbuffer)
max_gray = 512;  
    
% figure(1)
% imshow(rot90(squeeze(frames(bw_cdsSignal,:,:,1))),[0,max_gray]);
% hold on

for i=1:numFrames
  
    %check cdsSignal is non negative, set cdsSignal = 0 if neg
    index_neg = frames(bw_cdsSignal,:,:,i) < 0;
    temp=squeeze(frames(bw_cdsSignal,:,:,i));
    temp(index_neg) = 0; 
    
    %imshow(rot90(squeeze(frames(bw_cdsSignal,:,:,i))),[0,max_gray]);
    pause(time_interval);
end

pic_array = rot90(squeeze(frames(bw_cdsSignal,:,:,round(numFrames/2))));
%imshow(pic_array,[0,max_gray]);
end
