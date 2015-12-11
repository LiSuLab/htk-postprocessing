function [feature_averages, activations_per_phone] = average_bn26_activations_over_phones()

    %% Paths

    load_dir  = fullfile('/Users', 'cai', 'Desktop', 'scratch', 'py_out');
    save_dir  = fullfile('/Users', 'cai', 'Desktop', 'scratch', 'figures_activations', 'nodes_per_feature');
    
    
    %% Load the necessary data
    
    segmentations = load(fullfile(load_dir, 'triphone_boundaries.mat'));
    segmentations = orderfields(segmentations);
    
    bn26 = load(fullfile(load_dir, 'bn26_activations.mat'));
    bn26 = orderfields(bn26);
    
    
    %% Constants
    
    DO_DISPLAY = true;

    words = fieldnames(segmentations);
    n_words = numel(words);
    
    phones = get_used_phones(segmentations);
    n_phones = numel(phones);
    
    MS_per_frame = 10;
    
    
    %% The loop
    
    % We want to average together the BN nodes at every occurence of each
    % phone.
    %
    % We will create a phone-indexed struct of activations
    
    % Initialise
    activations_per_phone = struct();
    for phone_i = 1:n_phones
        phone = phones{phone_i};
        activations_per_phone.(phone) = [];
    end

    for word_i = 1:n_words
        word = words{word_i};
        
        this_word_segmentation = segmentations.(word);
        
        n_segments_this_word = size(this_word_segmentation, 2);
        
        for segment_i = 1:n_segments_this_word
           
            %% Get the segment of this word
            
            this_segment_phone = this_word_segmentation(segment_i).label;
            
            if strcmpi(this_segment_phone, 'sil')
                continue;
            end
            
            
            %% Get frames in this segment
            
            segment_ms = [nan, nan];
            segment_ms(1) = this_word_segmentation(segment_i).onset;
            segment_ms(2) = this_word_segmentation(segment_i).offset;
            % to ms
            segment_ms = double(segment_ms) / 10000;
            
            segment_frames = segment_ms ./ MS_per_frame;
            
            for segment_frame = segment_frames + 1
                activations_per_phone.(this_segment_phone) = [ ...
                    activations_per_phone.(this_segment_phone); ...
                    bn26.(word)(segment_frame, :)];     
            end
        end
    end
    
    
    %% Average over features
    
    % Get feature matrix
    
    feature_matrix = phonetic_feature_matrix();
    features = fieldnames(feature_matrix);
    n_features = numel(features);
    
    
    % Prepare struct
    
    feature_averages = struct();
    feature_sds = struct();
    
    for feature_i = 1:n_features
        feature = features{feature_i};
        
        phone_is_this_feature = find(feature_matrix.(feature));
        
        % Collect data for this feature
        
        data_this_feature = [];
        for phone_i = phone_is_this_feature
            phone = phones{phone_i};
            data_this_feature = [ ...
                data_this_feature; ...
                activations_per_phone.(phone)];
        end
        
        % Average and store in feature struct
        feature_averages.(feature) = mean(data_this_feature, 1);
        feature_sds.(feature) = std(data_this_feature, 1);
        
        
        %% Make a bar graph
        
        if DO_DISPLAY
            
            % Make figure
            
            this_figure = figure;
            bar(feature_averages.(feature));
            this_axis = gca;
            
            % error bars
            hold on;
            errorbar(feature_averages.(feature), feature_sds.(feature), 'k.');
            hold off;
            
            % label figure
            
            title(feature);
            set(this_axis, 'XTickLabel', features);

            % Save figure
            
            this_frame = getframe(this_figure);
            file_path = fullfile(save_dir, sprintf('feature_activation_%s', feature));
            imwrite(this_frame.cdata, [file_path, '.png'], 'png');

            close(this_figure);
            
        end
        
    end
    
end%function
