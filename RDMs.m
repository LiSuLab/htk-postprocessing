clear;
close all;

here = pwd;
mkdir('Figures');

%% Load in the features

features = load('Features.mat');
condition_names = fieldnames(features);

userOptions = struct();
userOptions.saveFiguresJpg = true;
userOptions.analysisName = 'cepstral';
userOptions.rootPath = here;

%% Rearrange into feature vectors per frame

[frame_count, feature_count] = size(features.(condition_names{1}));
condition_count = length(condition_names);

% Preallocate
RDMs_per_frame = NaN(condition_count, condition_count, frame_count);
patterns = NaN(condition_count, feature_count);

for frame_i = 1:frame_count
    for condition_i = 1:condition_count
        condition = condition_names{condition_i};
        patterns(condition_i,:) = features.(condition)(frame_i,:);
    end
    
    RDMs_per_frame(:,:,frame_i) = squareform(pdist(patterns, 'Correlation'));
end

%% Display RDMs

for rdm_i = 1:size(RDMs_per_frame, 3)
    this_RDM = squareform(RDMs_per_frame(:,:,rdm_i));
    this_RDM = scale01(tiedrank(this_RDM));
    rdm_title = sprintf('frame%03d', rdm_i-1);
    % make into struct to add a title
    s_RDM = struct('name', rdm_title, 'RDM', squareform(this_RDM));
    % we've pre-rank-transformed them for speed
    showRDMs(s_RDM, rdm_i, false, [], true, 2/3, [], 'Jet');
    handleCurrentFigure(fullfile(here, 'Figures', rdm_title), userOptions)
end
