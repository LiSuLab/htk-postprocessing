function activations_per_phone = average_bn26_activations_over_phones()

    %% Paths

    load_dir  = fullfile('/Users', 'cai', 'Desktop', 'scratch', 'py_out');
    words_dir = fullfile('/Users', 'cai', 'Desktop', 'scratch', 'the_400_used_stimuli');
    save_dir  = fullfile('/Users', 'cai', 'Desktop', 'scratch', 'figures_activations', 'words');
    
    %% Load the necessary data
    
    segmentations = load(fullfile(load_dir, 'triphone_boundaries.mat'));
    segmentations = orderfields(segmentations);
    
    bn26 = load(fullfile(load_dir, 'bn26_activations.mat'));
    bn26 = orderfields(bn26);
    
    %% Constants
    
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
        
        rsa.util.prints('Working on word %s...', word);
        
        this_word_segmentation = segmentations.(word);
        
        n_segments_this_word = size(this_word_segmentation, 2);
        
        for segment_i = 1:n_segments_this_word
           
            % Get the segment of this word
            
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
    
    %% Average over instances of a phone
    
    for phone_i = 1:n_phones
        phone = phones{phone_i};
        activations_per_phone.(phone) = mean(activations_per_phone.(phone), 1);
    end

end%function
