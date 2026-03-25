%% Example script to produce calibrated spectral data outputs using Ocean Networks Canada hydrophone data
% 2026-03-25, Brendan Smith
% Draft, validation still to be completed
clear all; close all; clc

% -------------------------------USER INPUTS-------------------------------

% directory containing audio files for analysis and sensitivity .txt file
fdir = 'C:\Users\bsmithacoustics\Documents\ONClocal\Code\MATLAB\ONC\ONCMATLAB\';

% path to audio file
audioPath = [fdir '\ICLISTENHF6324_20250815T000000.000Z.flac'];

% path to calibration .txt file
calPath = [fdir '\ICLISTENHF6324_20240208T191300.000Z-hydrophoneCalibration.txt'];

df = 10; % target frequency bin spacing [Hz], sensitivity file will be interpolated over frequency if necessary
overlapFactor = 0.5; % ratio of overlap between adjacent time windows
specType = 'psd'; % specify either 'power' for power spectrum [dB re 1µPa^2] or 'psd' for power spectral densitiy [dB re 1µPa^2/Hz]

% -------------------------------------------------------------------------

% read audio data
[Y,Fs] = audioread(audioPath); % read audio file scaled to +/- 1. Do not use 'native' argument. The conversion to bits is done manually below.
aui = audioinfo(audioPath); % extract audio information
bitDepth = aui.BitsPerSample; % audio bit depth [bits]
Y = Y * 2^(bitDepth-1); % convert Y to counts [counts]

% compute calibrated ONC hydrophone spectral data
[spectData] = calibrateONChydrophoneSpectra(Y,Fs,calPath,df,overlapFactor,specType);

% spectData contains a time vector: T [s], frequency vector: F [Hz], power
% spectral density or power spectrum matrix: P and Pavg (time average) [units specified in specUnits variable of structure]

%% Plot spectrogram and time-average of all spectra
close all

fSize = 16; % font size
lw = 1.5; % line width

freqLim = [10 25600]; % frequency axis limits [Hz]
levelLim = [30 140]; % psd or power axis limits [dB with same reference as P]

fh = figure;
fh.Position = [100 100 1400 600];
tiledlayout(1,2,'Padding','compact')
nexttile
pcolor(spectData.T,spectData.F,spectData.P)
shading flat
xlabel('Time [s]')
ylabel('Frequency [Hz]')
colormap turbo
ylim(freqLim) % frequency limits [Hz]
clim(levelLim) % colorbar axis limits [same units as P]
ch = colorbar;
if strcmp(specType,'psd')
    ch.Label.String = 'Power spectral density [dB re 1 μPa^{2}/Hz]';
elseif strcmp(specType,'power')
    ch.Label.String = 'Power spectrum [dB re 1 μPa^{2}]';
end
ch.Label.FontSize = fSize;
title('Spectrogram')
set(gca,'YScale','log')
set(gca,'FontSize',fSize)

nexttile
semilogx(spectData.F,spectData.Pavg,'LineWidth',lw)
grid on
xlim(freqLim) % frequency limits [Hz]
ylim(levelLim) % colorbar axis limits [dB with same reference as P]
xlabel('Frequency [Hz]')
if strcmp(specType,'psd')
    ylabel('Power spectral density [dB re 1 μPa^{2}/Hz]');
elseif strcmp(specType,'power')
    ylabel('Power spectrum [dB re 1 μPa^{2}]');
end
title('Time-average of all spectra')
set(gca,'FontSize',fSize)