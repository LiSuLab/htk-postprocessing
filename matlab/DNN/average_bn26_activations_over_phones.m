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
    
    framestep_ms = 10;
    framewidth_ms = 110;
    
    
    %% The loop
    
    % Initialise
    activations_per_phone = struct();
    for phone_i = 1:n_phones
        phone = phones{phone_i};
        activations_per_phone.(phone) = [];
    end
    
    % We want to average together the BN nodes at every occurence of each
    % phone.
    %
    % We will create a phone-indexed struct of activations

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
            
            segment_ms = double([ ...
                this_word_segmentation(segment_i).onset, ...
                this_word_segmentation(segment_i).offset]) ...
                / 10000;
            
            % Figure out which frames are in this segment
            
            frame_i = floor(segment_ms / framestep_ms);
            segment_frames = [];
            
            frame_i_in_segment = true;
            while frame_i_in_segment
                % First frame in the segment we add automatically
                segment_frames = [segment_frames, frame_i];
                
                % Now check if the next frame will be in the segment
                frame_i = frame_i + 1;
                
                frame_offset = (frame_i * framestep_ms) + framewidth_ms;
                
                frame_i_in_segment = (frame_offset <= segment_ms(2));
            end
            
            % +1 here because we're changing the frame_is (which are
            % 0-indexed) into matlab 1-indexed frame indices
            for segment_frame = segment_frames + 1
                activations_per_phone.(this_segment_phone) = [ ...
                    activations_per_phone.(this_segment_phone); ...
                    bn26.(word)(segment_frame, :)];     
            end
        end
    end
    
    
    %% Average over phones
    
    % Prepare structs
    phone_count    = struct();
    phone_averages = struct();
    phone_stds     = struct();
    phone_sems     = struct();
    
    for phone_i = 1:n_phones
        phone = phones{phone_i};
        
        phone_count.(phone)    = size(activations_per_phone.(phone), 1);
        phone_averages.(phone) = mean(activations_per_phone.(phone), 1);
        phone_stds.(phone)     = std(activations_per_phone.(phone),  1);
        phone_sems.(phone) = phone_stds.(phone) / sqrt(phone_count.(phone));
        
        rsa.util.prints('Averaging together %d items for phone "%s"', phone_count.(phone), phone);
        
        %% Make a bar graph
        
        if DO_DISPLAY
            
             % Make figure
            
            this_figure = figure;
            bar(phone_averages.(phone));
            
            % This is a quick hack because I can't be bothered to
            % programatically figure out the limits.
            ylim([-5,5]);
            
            % error bars
            hold on;
            errorbar(phone_averages.(phone), phone_sems.(phone), 'k.');
            hold off;
            
            % label figure
            
            title(phone);
            set(gca,'XTick', 1:26);

            % Save figure
            
            this_frame = getframe(this_figure);
            file_path = fullfile(save_dir, sprintf('activation_phone_%d_%s', phone_i, phone));
            imwrite(this_frame.cdata, [file_path, '.png'], 'png');

            close(this_figure);
        end
    end
    
    
    %% Average over features
    
    % Get feature matrix
    
    feature_matrix = phonetic_feature_matrix();
    features = fieldnames(feature_matrix);
    n_features = numel(features);
    
    
    % Prepare structs
    feature_count    = struct();
    feature_averages = struct();
    feature_stds     = struct();
    feature_sems     = struct();
    
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
        feature_count.(feature)    = size(data_this_feature, 1);
        feature_averages.(feature) = mean(data_this_feature, 1);
        feature_stds.(feature)     = std(data_this_feature,  1);
        feature_sems.(feature) = feature_stds.(feature) / sqrt(feature_count.(feature));
        
        % Just keep a record of how many frames represent each feature.
        rsa.util.prints('Averaging together %d items for feature "%s"', feature_count.(feature), feature);
        
        
        %% Make a bar graph
        
        if DO_DISPLAY
            
            % Make figure
            
            this_figure = figure;
            bar(feature_averages.(feature));
            
            % This is a quick hack because I can't be bothered to
            % programatically figure out the limits.
            ylim([-5,5]);
            
            % error bars
            hold on;
            errorbar(feature_averages.(feature), feature_sems.(feature), 'k.');
            hold off;
            
            % label figure
            
            title(feature);
            set(gca,'XTick', 1:26);

            % Save figure
            
            this_frame = getframe(this_figure);
            file_path = fullfile(save_dir, sprintf('activation_feature_%d_%s', feature_i, feature));
            imwrite(this_frame.cdata, [file_path, '.png'], 'png');

            close(this_figure);
            
        end
        
    end
    
end%function
