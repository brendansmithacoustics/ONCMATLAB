%% Get list of available hydrophone audio data
% Author: Brendan Smith (ONC)
% Date: September 22, 2026
clear all; close all; clc

%----------REQUIRED INPUTS----------%
token = 'xxxxx-xxxxx-xxxxxx-xxxxxx'; % enter your Oceans 3.0 API token here

% define start and end dates/times in ISO 8601 date time format
startDate_full = "2025-08-01T00:00:00.000Z";
endDate_full = "2025-08-03T00:00:00.000Z";

locCode = "ECHO3.H2"; % enter hydrophone location code (ECHO.H2 is Strait of Georgia East, hydrophone array element B)

saveFolder = 'C:\AudioStorageLocation\';
%----------------------------------------%
onc = Onc(token, 'outPath', saveFolder);

startDate_dt = datetime(startDate_full,'InputFormat','yyyy-MM-dd''T''HH:mm:ss.SSS''Z');
endDate_dt = datetime(endDate_full,'InputFormat','yyyy-MM-dd''T''HH:mm:ss.SSS''Z');
fullDuration = days(endDate_dt - startDate_dt);

% if target duration is longer than 1 day, split up the downloads into 1 day chunks (helps avoid the download failing mid-way and doesn't overload ONC servers)
if fullDuration > days(1)
    dateVector = startDate_dt:days(1):endDate_dt; % create date vector with 1-day resolution
    for i = 1:length(dateVector)-1
        % convert dates to string format for API request
        startDate = string(dateVector(i),'yyyy-MM-dd''T''HH:mm:ss.SSS''Z');
        endDate = string(dateVector(i+1),'yyyy-MM-dd''T''HH:mm:ss.SSS''Z');

        params = struct(...
            'locationCode', locCode, ...
            'deviceCategoryCode', 'HYDROPHONE',...
            'dateFrom', startDate,...
            'dateTo', endDate, ...
            'extension', 'flac' ...
            );
    
        onc.getDirectFiles(params) % download files
    end
else
    params = struct(...
        'locationCode', locCode, ...
        'deviceCategoryCode', 'HYDROPHONE',...
        'dateFrom', startDate_full,...
        'dateTo', endDate_full, ...
        'extension', 'flac' ...
        );

    onc.getDirectFiles(params) % download files
end
