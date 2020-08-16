function D = disparityList2Map(x,y,t,d,interval)
%% D = disparityList2Map(x,y,t,d,interval��
%   x/y - list of event pixel locations
%   t - list of event times, starting with 0 for the first event
%   d - list of event disparities
%   interval - raster scan interval

    % Calculate which frame each event should go into depending on interval
    frame = floor(t/interval) + 1;  
    
    % Accumulate all the events into a 240x180xframes disparity sequence
    %����ÿһ֡����ÿһ����ͬ��x������ƽ��ֵ 
    D = accumarray([x y frame],d,[],@mean);
end