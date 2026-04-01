function regularlasertime = GetRegularLaser(lasertime, laseronsetinterval)
% input：
%   lasertime        - original laser timestamp array
%   laseronsetinterval - preset laser trigger interval
% output：
%   regularlasertime - filtered regular laser timestamp array

regularlasertime = [];
tol = 0.05; % tolerance threshold for time intervals
len = length(lasertime);

% perform filtering only when laser timestamps are non-empty and count > 10
if ~isempty(lasertime) && len > 10
    % traverse laser timestamps and select valid points by time interval
    for i = 1:len-1
        interval_i = lasertime(i+1) - lasertime(i);
        is_valid_i = abs(interval_i - laseronsetinterval) < tol;
        
        if isempty(regularlasertime)
            % initial state: include if current interval is valid
            if is_valid_i
                regularlasertime = [regularlasertime; lasertime(i)];
            end
        else
            % non-initial state: select one from the two valid conditions
            interval_last = lasertime(i) - regularlasertime(end);
            is_valid_last = abs(interval_last - laseronsetinterval) < tol;
            
            if is_valid_last || is_valid_i
                regularlasertime = [regularlasertime; lasertime(i)];
            end
        end
    end
    
    % check if the last laser timestamp meets the interval requirement; add it if valid
    if ~isempty(regularlasertime)
        interval_end = lasertime(end) - regularlasertime(end);
        if abs(interval_end - laseronsetinterval) < tol
            regularlasertime = [regularlasertime; lasertime(end)];
        end
    end
end
end