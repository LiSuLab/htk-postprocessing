clear;
close all;


%% Paths

% Change these values
input_dir = fullfile('C:', 'Users', 'cai', 'analyses', 'Lexpro', 'Cepstral_models', 'filtered-cepstral-coefficients');
output_dir = fullfile('C:', 'Users', 'cai', 'analyses', 'Lexpro', 'Cepstral_models', 'cepstral-band-rdms');

% These values are automatic
cd(output_dir);
mkdir('Figures');
figures_dir = fullfile(output_dir, 'Figures');


%% UserOptions
userOptions = struct();
userOptions.saveFiguresJpg = true;
userOptions.analysisName = 'cepstral';
userOptions.rootPath = '';


%% Load in the features

coeffs = struct();

% There is one feature file for each cepstral coefficient
feature_file_list = dir(fullfile(input_dir, '*.mat'));

% Get the names of the available cepstral coefficients
coeff_names = {};
for file_i = 1 : length(feature_file_list)
    % quick and dirty way to get the name of this coefficient
    coeff_names{file_i} = feature_file_list(file_i).name(23:25);
    coeffs.(coeff_names{file_i}) = load(fullfile(input_dir, feature_file_list(file_i).name));
end%for

word_list = fieldnames(coeffs.(coeff_names{1}));
n_frames = length(coeffs.(coeff_names{file_i}).(word_list{1}));


%% Produce RDMs

% We want to have one RDM for each cepstral coefficient, and for
% consecutive groups of three frames.

% Frames per window
fw = 3;

n_windows = n_frames / fw;

for window_i = 1 : n_windows
    
    % Clear out any old values
    RDMs_this_frame = struct();
    
    for coeff_i = 1 : length(coeff_names)
        this_coeff = coeff_names{coeff_i};
        
        % Preallocate the feature matrix
        this_feature_matrix = nan(length(word_list), fw);
        
        % Iterate over frame per window
        for frame_i = 1 : fw
            this_frame = ((window_i - 1) * fw) + frame_i;
            
            % Iterate over words
            for word_i = 1 : length(word_list)
                this_word = word_list{word_i};
                this_feature_matrix(word_i, this_frame) = coeffs.(this_coeff).(this_word)(this_frame);
            end%for
        end%for
        
        %% Calculate the RDM
        this_RDM = pdist(this_feature_matrix, 'Correlation');
        this_RDM = scale01(tiedrank(this_RDM));
        this_RDM = squareform(this_RDM);
        this_RDM_name = sprintf('%s (window%02d)', this_coeff, window_i);
        RDMs_this_frame(coeff_i).RDM = this_RDM;
        RDMs_this_frame(coeff_i).name = this_RDM_name;
        
    end%for
    
    %% Display RDMs
    
    % Quick and dirty way to split into Cs, Ds, As
    for c_i = 1:3
        showRDMs(RDMs_this_frame, window_i, false, [], false, 3/4, [], 'Jet');
        handleCurrentFigure(fullfile(figures_dir, sprintf('window%02d', window_i)), userOptions);
    end%for
    
    showRDMs(RDMs_this_frame, window_i, false, [], false, 3/4, [], 'Jet');
    handleCurrentFigure(fullfile(figures_dir, sprintf('window%02d', window_i)), userOptions);
    
end%for
