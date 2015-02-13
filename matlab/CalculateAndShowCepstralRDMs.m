clear;
close all;


%% Possible analyses
% MFCC - one model for each coefficient
% CDA - one model for all Cs, one for all Ds, one for all As.

chosen_analysis = 'MFCC';

%% Paths

% Change these values
input_dir = fullfile('C:', 'Users', 'cai', 'analyses', 'Lexpro', 'Cepstral_models', 'filtered-cepstral-coefficients');
output_dir = fullfile('C:', 'Users', 'cai', 'analyses', 'Lexpro', 'Cepstral_models', 'cepstral-band-rdms', '60ms-window');

% These values are automatic
cd(output_dir);
mkdir('Figures');
figures_dir = fullfile(output_dir, 'Figures');


%% UserOptions
userOptions = struct();
userOptions.saveFiguresJpg = true;
userOptions.displayFigures = false;
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
fw = 6;

% Coeffs per class
cc = 12;

n_windows = n_frames - fw + 1;

fig_i = 1;

%% MFCC
if strcmp(chosen_analysis, 'MFCC')
    for window_i = 1 : n_windows

        % Clear out any old values
        RDMs_this_frame = struct();

        for coeff_i = 1 : length(coeff_names)
            this_coeff = coeff_names{coeff_i};

            % Preallocate the feature matrix
            this_feature_matrix = nan(length(word_list), fw);

            % Iterate over words
            for word_i = 1 : length(word_list)
                this_word = word_list{word_i};
                this_feature_matrix(word_i, :) = coeffs.(this_coeff).(this_word)(window_i:window_i + fw - 1);
            end%for


            %% Calculate the RDM

            this_RDM = pdist(this_feature_matrix, 'Correlation');
            this_RDM = scale01(tiedrank(this_RDM));
            this_RDM = squareform(this_RDM);
            this_RDM_name = sprintf('%s (window%02d)', this_coeff, window_i);
            RDMs_this_frame(coeff_i).RDM = this_RDM;
            RDMs_this_frame(coeff_i).name = this_RDM_name;


            %% Display RDMs

            showRDMs(RDMs_this_frame(coeff_i), fig_i, false, [], false, 3/4, [], 'Jet');
            handleCurrentFigure(fullfile(figures_dir, sprintf('%s-window%02d', this_coeff, window_i)), userOptions);

            fig_i = fig_i + 1;

        end%for


        %% Save RDMs
        cd(output_dir);
        save(sprintf('RDMs-window%02d.mat', window_i), 'RDMs_this_frame');

    end%for

%% CDA
elseif strcmp(chosen_analysis, 'CDA')
    
    %% Split coefficients into classes
    coeffs_per_class = struct();
    coeffs_per_class.C = { ...
        'C01', ...
        'C02', ...
        'C03', ...
        'C04', ...
        'C05', ...
        'C06', ...
        'C07', ...
        'C08', ...
        'C09', ...
        'C10', ...
        'C11', ...
        'C12' ...
    };
    coeffs_per_class.D = { ...
        'D01', ...
        'D02', ...
        'D03', ...
        'D04', ...
        'D05', ...
        'D06', ...
        'D07', ...
        'D08', ...
        'D09', ...
        'D10', ...
        'D11', ...
        'D12' ...
    };
    coeffs_per_class.A = { ...
        'A01', ...
        'A02', ...
        'A03', ...
        'A04', ...
        'A05', ...
        'A06', ...
        'A07', ...
        'A08', ...
        'A09', ...
        'A10', ...
        'A11', ...
        'A12' ...
    };

    
    %% Iterate over windows
    fig_i = 1;
    for window_i = 1 : n_windows
        
        coeff_classes = 'CDA';
        for coeff_class_i = 1 : length(coeff_classes)
            coeff_class = coeff_classes(coeff_class_i);
            
            this_feature_matrix = nan(length(word_list), fw * cc);
            
            % Iterate over words
            for word_i = 1 : length(word_list)
                this_word = word_list{word_i};
                
                % Collect the feature vector
                feature_vector = [];
                feature_i = 1;
                for coeff_this_class_i = 1 : cc
                    this_coeff_name = coeffs_per_class.(coeff_class){coeff_this_class_i};
                    
                    % Iterate over frames per window
                    for frame_i = 1:fw
                        % Add the value for this word, for this coeff, for
                        % this frame
                        feature_vector(feature_i) = coeffs.(this_coeff_name).(this_word)(window_i + frame_i - 1);
                        feature_i = feature_i + 1;
                    end%for
                end%for
                
                %% Add the feature vector to the feature matrix
                this_feature_matrix(word_i, :) = feature_vector(:);
            end%for
            
            %% Calculate the RDM

            this_RDM = pdist(this_feature_matrix, 'Correlation');
            this_RDM = scale01(tiedrank(this_RDM));
            this_RDM = squareform(this_RDM);
            this_RDM_name = sprintf('%ss (window%02d)', coeff_class, window_i);
            RDMs_this_frame(coeff_class_i).RDM = this_RDM;
            RDMs_this_frame(coeff_class_i).name = this_RDM_name;
            
            showRDMs(RDMs_this_frame(coeff_class_i), fig_i, false, [], false, 1, [], 'Jet');
            handleCurrentFigure(fullfile(figures_dir, sprintf('%ss-window%02d', coeff_class, window_i)), userOptions);

            fig_i = fig_i + 1;

            %% Save RDMs
            cd(output_dir);
            save(sprintf('RDMs-window%02d.mat', window_i), 'RDMs_this_frame');
            
        end%for:CDA
    end%for
    
    %% Nothing
else
    prints('Doing nothing....');
end%if
