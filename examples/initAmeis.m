function ameisHandler = initAmeis(dataFolders, threshold)
%INITAMEIS initializes object for data processing
%   two parameters are needed:
%   - data-folder name or cell array of multiple folders
%   - threshold for peak detection (signed)
%   - all fields set in this function can be user overwritten but are
%   required for peak detection

narginchk(2,2);

ameisHandler = [];
ameisHandler.threshold = threshold;

ameisHandler.samplesPerChunk = 1e5;
ameisHandler.maxChunks = inf;
ameisHandler.freqs = 1:8;
ameisHandler.skipInitialSamples = 100;
ameisHandler.peakDetectionFreqIndex = 3;
ameisHandler.minPeakDistS = 0.5;
ameisHandler.AcSmoothLengthS = 0;
ameisHandler.DcSmoothLengthS = 0;
ameisHandler.multiPeak = 0;
ameisHandler.debugOn = 1;
ameisHandler.startChunkIndex = 0;
ameisHandler.folderTimeOffsetsS = 0;
ameisHandler.dataFolders = dataFolders;

end
