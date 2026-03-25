**Data availability**
dataAvailability.m is a MATLAB script using Ocean Networks Canada's MATLAB API client to check hydrophone data availability and convert the file time stamps to a MATLAB datetime format. Note the data search time frame must be within the time frame that the hydrophone was deployed.

**Computed calibrated spectra**
calibrateONChydrophoneSpectra.m is a MATLAB function which takes hydrophone audio data (in counts) and calibration files, along with some user-specified parameters, and returns calibrated spectral data.
hydrophoneCalibration_master.m is an example MATLAB script which calls this function and plots the result as a spectrogram and time-averaged spectrum.
The .flac audio file and .txt sensitivity files are provided for example use with this script and function.
