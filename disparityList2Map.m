function D = disparityList2Map(x,y,t,d,interval)
%% D = disparityList2Map(x,y,t,d,interval）
%   x/y - list of event pixel locations
%   t - list of event times, starting with 0 for the first event
%   d - list of event disparities
%   interval - raster scan interval

    % Calculate which frame each event should go into depending on interval
    frame = floor(t/interval) + 1;  
    
    % Accumulate all the events into a 240x180xframes disparity sequence
    %对于每一帧对于每一个相同的x坐标求平均值 
    D = accumarray([x y frame],d,[],@mean);
end