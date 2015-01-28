clear;

%% Load in the features

features = load('Features.mat');
condition_names = fieldnames(features);

%% Rearrange into feature vectors per frame

[frame_count, feature_count] = size(features.(condition_names{1}));
condition_count = length(condition_names);

% Preallocate
RDMs_per_frame = NaN(condition_count, condition_count, frame_count);

for frame_i = 1:frame_count
    
    % Preallocate
    % TODO: move this outside loop
    patterns = NaN(condition_count, feature_count);
    
    for condition_i = 1:condition_count
        condition = condition_names{condition_i};
        patterns(condition_i,:) = features.(condition)(frame_i,:);
    end
    
    RDMs_per_frame(:,:,frame_i) = squareform(pdist(patterns, 'Correlation'));
end

%% Display RDMs

showRDMs(RDMs_per_frame(:,:,1));
