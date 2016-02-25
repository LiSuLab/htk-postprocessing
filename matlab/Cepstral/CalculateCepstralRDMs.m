function models = CalculateCepstralRDMs

    % Can skip the actual display to save a bit of time.
    show_RDMs = false;

    %% Paths

    % Change these values
    input_dir  = fullfile('/Users', 'cai', 'Desktop', 'scratch', 'py_out', 'cepstral-coefficients');
    output_dir = fullfile('/Users', 'cai', 'Desktop', 'scratch', 'RDMs');


    %% UserOptions
    userOptions = struct();
    userOptions.saveFiguresJpg = true;
    userOptions.displayFigures = false;
    userOptions.analysisName = 'cepstral';
    userOptions.rootPath = '';


    %% Load in the features

    
    N_coeffs_per_type = 12;
    for coeff_type = 'CDA'
        for coeff_i_within_type = 1:N_coeffs_per_type
            
            coeff_name = sprintf('%s%02d', coeff_type, coeff_i_within_type);
            
            file_name = sprintf('cepstral-coefficients-%s.mat', coeff_name);
            file_path = fullfile(input_dir, file_name);
            
            coeffs.(coeff_name) = load(file_path);
            
        end 
    end
    
    word_list = fieldnames(coeffs.C01);
    n_words = numel(word_list);    
    n_frames = numel(coeffs.C01.(word_list{1}));


    %% Produce RDMs
    
    coeff_types_for_model = 'C';
    coeff_indices_for_model = 1:12;
    n_coeffs_for_model = numel(coeff_types_for_model) * numel(coeff_indices_for_model);

    % Frames per window. For HTK, each frame is 10ms.
    window_width_in_frames = 2;
    
    window_width_ms = window_width_in_frames * 10;

    n_windows = n_frames - window_width_in_frames + 1;

    % We scan over the coefficients with a sliding window
    for frame_i = 1:n_windows
        
        % The window of indices relative to the coefficient timelines
        window = frame_i:frame_i+window_width_in_frames-1;
        
        % preallocate data for this frame
        % should eventually be a words-by-(window_width*n_coeffs) data matrix
        data_this_frame = nan(n_words, window_width_in_frames * n_coeffs_for_model);
        for word_i = 1:n_words
            word = word_list{word_i};
            
            data_this_word = [];
            
            overall_coeff_i = 1;
            for coeff_type = coeff_types_for_model
                for coeff_i_within_type = coeff_indices_for_model
                    coeff_name = sprintf('%s%02d', coeff_type, coeff_i_within_type);
                    data_this_word = [ ...
                        data_this_word, ...
                        coeffs.(coeff_name).(word)(window)];
                    overall_coeff_i = overall_coeff_i + 1;
                end
            end
            
            data_this_frame(word_i, :) = data_this_word;
        end
        
        RDM_this_frame = pdist(data_this_frame, 'correlation');
        
        models(frame_i).RDM = RDM_this_frame;

    end%for
    
    models_file_name = sprintf('cepstral_models_win%d_%s%02d-%s%02d.mat', window_width_ms, coeff_types_for_model, coeff_indices_for_model(1), coeff_types_for_model, coeff_indices_for_model(end));
    models_file_path = fullfile(output_dir, models_file_name);

    save(models_file_path, 'models');

end
