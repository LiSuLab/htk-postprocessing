function [] = scr_mds_L7_triphones()

    %% Paths

    load_dir  = fullfile('/Users', 'cai', 'Desktop', 'scratch', 'py_out');
    save_dir  = fullfile('/Users', 'cai', 'Desktop', 'scratch', 'figures_mds', 'phone_by_l7');
    
    
    %% Load the necessary data
    
    phone_segmentations = load(fullfile(load_dir, 'triphone_boundaries.mat'));
    phone_segmentations = orderfields(phone_segmentations);
    
    bn26_activations = load(fullfile(load_dir, 'hidden_layer_7BN_activations.mat'));
    bn26_activations = orderfields(bn26_activations);
    
    
    %% Constants

    words = fieldnames(phone_segmentations);
    n_words = numel(words);
    
    n_nodes = size(bn26_activations.(words{1}), 2);
    
    phones = get_used_phones(phone_segmentations);
    n_phones = numel(phones);
    
    framestep_ms = 10;
    framewidth_ms = 25;
    
    
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
        
        this_word_segmentation = phone_segmentations.(word);
        
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
            
            % The first frame starts at 0, and move in framestep_ms jumps,
            % so we can use floor to find the index of the frame which
            % contans the onset and offset of the segment.
            first_frame_i_in_segment = floor(segment_ms(1) / framestep_ms);
            last_frame_i_in_segment = floor(segment_ms(2) / framestep_ms);
            
            segment_frames = (first_frame_i_in_segment:last_frame_i_in_segment);
            
            % +1 here because we're changing the frame_is (which are
            % 0-indexed) into matlab 1-indexed frame indices
            for segment_frame = segment_frames + 1
                activations_per_phone.(this_segment_phone) = [ ...
                    activations_per_phone.(this_segment_phone); ...
                    bn26_activations.(word)(segment_frame, :)];     
            end
        end
    end
    
    
    %% Average over phones
    
    % Prepare structs
    phone_counts   = struct();
    phone_averages = struct();
    phone_stds     = struct();
    phone_sems     = struct();
    
    for phone_i = 1:n_phones
        phone = phones{phone_i};
        
        phone_counts.(phone)   = size(activations_per_phone.(phone), 1);
        phone_averages.(phone) = mean(activations_per_phone.(phone), 1);
        phone_stds.(phone)     = std(activations_per_phone.(phone),  1);
        phone_sems.(phone) = phone_stds.(phone) / sqrt(phone_counts.(phone));
        
    end
        
    %% MDS
    
    % Stack struct into matrix
    phone_activations = nan(n_phones, n_nodes);
    for phone_i = 1:n_phones
       phone = phones{phone_i};
       phone_activations(phone_i, :) = phone_averages.(phone);
    end
    
    D = pdist(phone_activations, 'correlation');
    
    [Y] = mdscale(D, 2, 'Criterion', 'sammon');
    
    plot(Y(:,1),Y(:,2), '.', 'Marker','none');
    text(Y(:,1),Y(:,2), phones, 'Color','b', ...
        'FontSize',12,'FontWeight','bold', 'HorizontalAlignment','center');
    h_gca = gca;
    h_gca.XTickLabel = [];
    h_gca.YTickLabel = [];
    
end%function
