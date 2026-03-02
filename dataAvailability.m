%% Get list of available hydrophone audio data
% Author: Brendan Smith (ONC)
% Date: February 27, 2026
clear all; close all; clc

%----------REQUIRED USER INPUTS----------%
token = 'xxxxx-xxxxx-xxxxxx-xxxxxx'; % enter your Oceans 3.0 API token here
onc = Onc(token);

% define start and end dates/times in ISO 8601 date time format
startDate = "2023-09-01T00:00:00.000Z";
endDate = "2026-02-27T00:00:00.000Z";

locCode = "KEMFH.H1"; % enter hydrophone location code
%----------------------------------------%

% convert start/end dates to date times and create monthly date vector
% note: the date vector is required because for a long time period (e.g.
% many months or years) the API will reach a limit of the number of files
% it will return and will not show you all files. Breaking the request into
% smaller date ranges ensures all available files over your target range
% are returned.
startDate_dt = datetime(startDate,'InputFormat','yyyy-MM-dd''T''HH:mm:ss.SSS''Z');
endDate_dt = datetime(endDate,'InputFormat','yyyy-MM-dd''T''HH:mm:ss.SSS''Z');
dateVector = startDate_dt:calmonths(1):endDate_dt; % create date vector with monthly resolution, this can be modified into different resolutions, for example days(1) instead of calmonths(1)

[files,timestamps] = getFileList(dateVector,locCode,onc); % get list of available hydrophone audio files and their timestamps in datetime format

%% Get file list from ONC
function [files,timestamps] = getFileList(dateVector,locCode,onc)
    files = {}; % instantiate empty file cell
    for i = 1:length(dateVector)-1 % loop over all dates in vector
        disp(['Checking batch ' num2str(i) ' of ' num2str(length(dateVector)-1)])
        
        % convert dates to string format for API request
        start_date = string(dateVector(i),'yyyy-MM-dd''T''HH:mm:ss.SSS''Z');
        end_date = string(dateVector(i+1),'yyyy-MM-dd''T''HH:mm:ss.SSS''Z');
        
        % define parameters for API request
        params = {"deviceCategoryCode", "HYDROPHONE", ...
            "locationCode", locCode, ...
            "extension", "flac", ...
            "dateFrom", start_date, ...
            "dateTo", end_date};
        
        result = onc.getListByLocation(params); % get file list based on location code
        
        files = [files; result.files]; % concatenate results from each iteration
    end

    % get file time stamps
    disp('Extracting file time stamps')
    timestamps = [];
    for i = 1:length(files)
        timestamps{i,1} = files{i}(16:34);
    end
    timestamps = datetime(timestamps,'InputFormat','yyyyMMdd''T''HHmmss.SSS');
end