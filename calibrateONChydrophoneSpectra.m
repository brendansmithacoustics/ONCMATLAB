function [spectData] = calibrateONChydrophoneSpectra(Y,Fs,calPath,df,overlapFactor,specType)
    %---------------------------------------------------------------------
    % calibrateONChydrophoneSpectra
    % Process Ocean Networks Canada single-channel hydrophone audio data to get calibrated power spectrum or power spectral density
    % Draft, validation still to be completed
    %
    % Syntax:
    % [spectData] = calibrateONChydrophoneData(audioPath,calPath,overlapFactor,specType)
    %
    % Input:    Y: audio time series [counts] - note this must be scaled to digital counts for the result to be calibrated properly
    %           Fs: audio sample rate [Hz]
    %           calPath: full path to sensitivity file (.txt)
    %           df: desired frequency bin spacing [Hz]. Sensitivity file will be interpolated if necessary.
    %           overlapFactor: ratio of overlap between adjacent time windows, typically 0 or 0.5
    %           specType: either 'power' for power spectrum [dB re 1µPa^2] or 'psd' for power spectral densitiy [dB re 1µPa^2/Hz]
    %
    % Output:   spectData structure containing
    %           T: Time vector [s] corresponding to time steps in P
    %           F: Frequency vector [Hz]
    %           P: calibrated power spectrum [dB re 1µPa^2] or power spectral density [dB re 1µPa^2/Hz] depending on specified specType
    %           Pavg: time-average over all windows of P, units same as P
    %           specType: 'power spectrum' or 'power spectral density' depending on specified specType
    %           specUnits: units of P and Pavg, either 'dB re 1µPa^2' for power spectrum or 'dB re 1µPa^2/Hz' for power spectral density, depending on specified specType
    %
    % References:   Merchant et al. (2015) Measuring acoustic habitats, Appendix S1. (https://besjournals.onlinelibrary.wiley.com/doi/10.1111/2041-210X.12330)
    %               Cerna, M. & Harvey, A.F. (2000) The fundamentals of FFT-based signal analysis and measurements, Application Note 041. Tech. rep. (https://www.sjsu.edu/people/burford.furman/docs/me120/FFT_tutorial_NI.pdf)
    %
    % Date/Author:  2026-03-25, Brendan Smith
    %---------------------------------------------------------------------

    % code for converting audio data to counts (for reference only - keep commented out)
    % [Y,Fs] = audioread(audioPath); % read audio file scaled to +/- 1. Do not use 'native' argument. The conversion to bits is done manually below.
    % aui = audioinfo(audioPath); % extract audio information
    % bitDepth = aui.BitsPerSample; % audio bit depth [bits]
    % Y = Y * 2^(bitDepth-1); % convert Y to counts [counts]
    
    % read in raw calibration .txt file (denoting as "raw" because this is before any interpolation is applied to achieved a desired frequency bin spacing)
    Sraw = table2array(readtable(calPath,'VariableNamingRule', 'Preserve')); % first column is frequency [Hz], second column is sensitivity calibration for each bin [dB re Counts/uPa]
    Sraw = [0, Sraw(1,2); Sraw]; % copy a sensitivity entry for 0 Hz to match up with power spectrum calculation below, note this is not an accurate value for 0 Hz, but just an approximation in the absence of a measured value.
    
    % calculate spectral analysis parameters and define constants
    Slin = 10.^(Sraw(:,2)./20); % convert sensitivity values to linear space for interpolation [counts/µPa]
    Ftarget = Sraw(1,1):df:Sraw(end,1); % new sensitivity frequency vector based on desired spectral resolution [Hz]
    Sinterp_lin = interp1(Sraw(:,1),Slin,Ftarget); % interpolated sensitivity values in linear space [counts/µPa]
    S(:,1) = Ftarget; % assign interpolated frequency vector to new sensitivity array [Hz]
    S(:,2) = 20*log10(Sinterp_lin); % assign interpolated sensitivity values (converted to dB) to new sensitivity array [dB re counts/µPa]
    NFFT = round(Fs/df); % FFT size [samples]
    windowFn = hann(NFFT,'periodic'); % window function
    alpha = 0.5; % coherent gain factor (scaling factor) of hann window, which corrects for the reduction in amplitude introduced by the window function (Cerna & Harvey, 2000)
    
    % divide signal into time segments
    Ywin = buffer(Y,NFFT,round(overlapFactor*NFFT),'nodelay'); % ** Check how this handles multichannel files
    Ywin = Ywin .* windowFn / alpha; % multiply each segment by the window function, and divide by window scaling factor
    
    % compute power spectrum
    X = fft(Ywin,NFFT,1); % discrete Fourier transform (DFT) of windowed data, operating on each column
    P = abs(X/NFFT).^2; % power spectrum
    Pss = P(1:floor(NFFT/2),:); % single-sided power spectrum
    Pss(2:end,:) = 2*Pss(2:end,:); % double values of single-sided power spectrum except for DC
    F = 0:df:(Fs/2 - df); % frequency vector corresponding to single-sided power spectrum [Hz]
    B = 1/NFFT * sum((windowFn/alpha).^2); % noise power bandwidth of the window function
    
    % crop frequency range to match sensitivity file and compute time vector
    maxF = min([max(S(:,1)) max(F)]); % find highest common frequency between sensitivity curve and FFT frequency vector [Hz]
    [~,maxFidx(1)] = min(abs(S(:,1) - maxF)); % find index of sensitivity file frequency corresponding to maxF
    [~,maxFidx(2)] = min(abs(F - maxF)); % find index of FFT frequency vector corresponding to maxF
    S = S(1:maxFidx(1),:); % crop sensitivity to maximum common frequency limit
    Pss = Pss(1:maxFidx(2),:); % crop power spectrum to maximum common frequency limit
    F = F(1:maxFidx(2)); % crop frequency vector to maximum common frequency limit
    dt = (1-overlapFactor)/df; % time step [s]
    T = 0:dt:((size(Pss,2)*dt) - dt); % time vector [s]
    
    % build spectData structure
    spectData.T = T;
    spectData.F = F;

    % compute power spectrum (PS) or power spectral density (PSD) depending on specified specType
    if strcmp(specType,'power')
        % note that the factor 1/B corrects for the noise power bandwidth of the window function B
        PS = 10*log10(1/B * Pss) - S(:,2); % power spectrum in decibels [dB re 1µPa^2] ** Check that dividing by B is actually appropriate - Parseval's theorem vs. Merchant
        PSavg = 10*log10(mean(10.^(PS/10),2)); % time-averaged power spectrum [dB re 1µPa^2] 
        spectData.P = PS;
        spectData.Pavg = PSavg;
        spectData.specType = 'Power Spectrum'; % record that P is 'power spectrum'
        spectData.specUnits = 'dB re 1µPa^2'; % units of P
    elseif strcmp(specType,'psd')
        % note that the factor 1/(B*df) corrects for the noise power bandwidth of the window function B, and stanardizes the results to the levels which would result from a 1 Hz bin spacing by dividing by the frequency bin spacing df
        PSD = 10*log10(1/(B*df) * Pss) - S(:,2); % power spectral density in decibels [dB re 1µPa^2/Hz]
        PSDavg = 10*log10(mean(10.^(PSD/10),2)); % time-averaged power spectrum [dB re 1µPa^2/Hz] 
        spectData.P = PSD;
        spectData.Pavg = PSDavg;
        spectData.specType = 'Power Spectral Density'; % record that P is 'power spectral density'
        spectData.specUnits = 'dB re 1µPa^2/Hz'; % units of P
    end
end