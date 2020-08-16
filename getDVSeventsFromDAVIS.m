function [x,y,t]=getDVSeventsFromDAVIS(allAddr, allT, interval)
%% function [x,y,t]=getDVSeventsFromDAVIS(allAddr,allT,interval)
% reads in events from the DAVIS events and returns only the DVS events
%
% Input:
% allAddr: all DAVIS address from jAER data
% allT: all DAVIS time from jAER data
% interval: scan speed
%
% Output:
% x: dvs event coordinates
% y: dvs event coordinates
% t: dvs event time

typemask = hex2dec('80000000');
triggerevent = hex2dec('00000400');

ids = find(~bitand(allAddr,typemask));
dvsAddr = allAddr(ids);
dvsT = allT(ids);

ids = find(~bitand(dvsAddr,triggerevent));
dvsAddr = dvsAddr(ids);
dvsT = dvsT(ids);

fprintf('Getting DVS events from DAVIS finished.\n');

% Extract event locations and polarities from event addresses
[x,y,pol] = extractRetinaEventsFromAddr(dvsAddr);

% Select events that have ON polarity after timeoffset
valid = find(pol == 1); 

% Shift event times to selected events
t = double(dvsT(valid) - dvsT(1));

% Set pixel locations to selected events only, shift by one pixel for Matlab
% since locations are indexed 0-239 on the DVS

x = x(valid) + 1;
y = y(valid) + 1;

end