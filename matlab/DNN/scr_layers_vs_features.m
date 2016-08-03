function [cf_features] = scr_layers_vs_features()

    %% Paths

    load_dir  = fullfile('/Users', 'cai', 'Desktop', 'scratch', 'py_out');
    
    
    %% Load the necessary data
    
    phone_segmentations = load(fullfile(load_dir, 'triphone_boundaries.mat'));
    phone_segmentations = orderfields(phone_segmentations);
    
    layers = { ...
        '2', ...
        '3', ...
        '4', ...
        '5', ...
        '6', ...
        '7BN'};%, ...
        %'FBK'};
    n_layers = numel(layers);
    
    %% Constants

    words = fieldnames(phone_segmentations);
    n_words = numel(words);

    phones = get_used_phones(phone_segmentations);
    n_phones = numel(phones);

    framestep_ms = 10;
    framewidth_ms = 25;
    
    feature_D = shared_feature_distance_matrix(phones);
    
    cf_features = nan(1, n_layers);
    
    for layer_i = 1:n_layers
        
        layer = layers{layer_i};
    
        layer_activations = load(fullfile(load_dir, sprintf('hidden_layer_%s_activations.mat', layer)));
        layer_activations = orderfields(layer_activations);

        n_nodes = size(layer_activations.(words{1}), 2);


        %% Initialise
        
        activations_per_phone = struct();
        for phone_i = 1:n_phones
            phone = phones{phone_i};
            activations_per_phone.(phone) = [];
        end
        
        
        %% The loop

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
                        layer_activations.(word)(segment_frame, :)];     
                end
            end
        end


        %% Average over phones

        % Prepare structs
        phone_counts   = struct();
        phone_averages = struct();

        for phone_i = 1:n_phones
            phone = phones{phone_i};

            phone_counts.(phone)   = size(activations_per_phone.(phone), 1);
            phone_averages.(phone) = mean(activations_per_phone.(phone), 1);

        end

        %% MDS

        % Stack struct into matrix
        phone_activations = nan(n_phones, n_nodes);
        for phone_i = 1:n_phones
           phone = phones{phone_i};
           phone_activations(phone_i, :) = phone_averages.(phone);
        end

        D = pdist(phone_activations, 'correlation');
        
        cf_features(layer_i) = corr(D', feature_D', 'type', 'Spearman');

    end
    
end%function

%%

function D = shared_feature_distance_matrix(phones)
    
    features = local_phonetic_feature_matrix();
    n_features = numel(features.(phones{1}));
    
    n_phones = numel(phones);
    
    phones_data = nan(n_phones, n_features);
    for phone_i = 1:n_phones
       phones_data(phone_i, :) = features.(phones{phone_i}); 
    end
    
    D = pdist(phones_data, 'euclidean');

end

%%

function D = triphone_phone_distance_matrix(phones)

    

end

%%

function features = local_phonetic_feature_matrix()

    features.aa	= [1 1 1 0  0 0 0  0 0 0 0 0 0  0 0 1  0 0 0 1  0];
    features.ae	= [1 1 1 0  0 0 0  0 0 0 0 0 0  1 0 0  0 0 1 0  0];
    features.ah	= [1 1 1 0  0 0 0  0 0 0 0 0 0  0 0 1  0 0 1 0  0];
    features.ao	= [1 1 1 0  0 0 0  0 0 0 0 0 0  0 0 1  0 0 1 0  1];
    features.aw	= [1 1 1 0  0 0 0  0 0 0 0 0 0  0 1 1  0 1 0 1  1];
    features.ay	= [1 1 1 0  0 0 0  0 0 0 0 0 0  1 1 0  1 0 0 1  0];
    features.b	= [0 1 0 1  1 0 0  1 0 0 0 0 0  0 0 0  0 0 0 0  0];
    features.ch	= [0 0 0 1  0 1 0  0 1 0 1 0 0  0 0 0  0 0 0 0  0];
    features.d	= [0 1 0 1  0 1 0  1 0 0 0 0 0  0 0 0  0 0 0 0  0];
    features.ea	= [1 1 1 0  0 0 0  0 0 0 0 0 0  1 1 0  0 0 1 0  0];
    features.eh	= [1 1 1 0  0 0 0  0 0 0 0 0 0  1 0 0  0 0 1 0  0];
    features.er	= [1 1 1 0  0 0 0  0 0 0 0 0 0  0 1 0  0 0 1 0  0];
    features.ey	= [1 1 1 0  0 0 0  0 0 0 0 0 0  1 0 0  0 1 1 0  0];
    features.f	= [0 0 0 1  1 0 0  0 0 1 0 0 0  0 0 0  0 0 0 0  0];
    features.g	= [0 1 0 1  0 0 1  1 0 0 0 0 0  0 0 0  0 0 0 0  0];
    features.hh	= [0 0 0 1  0 0 0  0 0 1 0 1 0  0 0 0  0 0 0 0  0];
    features.ia	= [1 1 1 0  0 0 0  0 0 0 0 0 0  1 1 0  1 1 0 0  0];
    features.ih	= [1 1 1 0  0 0 0  0 0 0 0 0 0  1 0 0  1 0 0 0  0];
    features.iy	= [1 1 1 0  0 0 0  0 0 0 0 0 0  1 0 0  1 0 0 0  0];
    features.jh	= [0 1 0 1  0 1 0  0 1 0 1 0 0  0 0 0  0 0 0 0  0];
    features.k	= [0 0 0 1  0 0 1  1 0 0 0 0 0  0 0 0  0 0 0 0  0];
    features.l	= [1 1 0 1  0 1 0  0 0 0 0 1 0  0 0 0  0 0 0 0  0];
    features.m	= [1 1 0 1  1 0 0  0 0 0 0 0 1  0 0 0  0 0 0 0  0];
    features.n	= [1 1 0 1  0 1 0  0 0 0 0 0 1  0 0 0  0 0 0 0  0];
    features.ng	= [1 1 0 1  0 0 1  0 0 0 0 0 1  0 0 0  0 0 0 0  0];
    features.oh	= [1 1 1 0  0 0 0  0 0 0 0 0 0  0 0 1  0 0 0 1  1];
    features.ow	= [1 1 1 0  0 0 0  0 0 0 0 0 0  0 1 1  0 1 1 0  1];
    features.oy	= [1 1 1 0  0 0 0  0 0 0 0 0 0  0 1 1  0 1 1 0  1];
    features.p	= [0 0 0 1  1 0 0  1 0 0 0 0 0  0 0 0  0 0 0 0  0];
    features.r	= [1 1 0 1  0 1 0  0 0 0 0 1 0  0 0 0  0 0 0 0  0];
    features.s	= [0 0 0 1  0 1 0  0 0 1 1 0 0  0 0 0  0 0 0 0  0];
    features.sh	= [0 0 0 1  0 1 0  0 0 1 1 0 0  0 0 0  0 0 0 0  0];
    features.t	= [0 0 0 1  0 1 0  1 0 0 0 0 0  0 0 0  0 0 0 0  0];
    features.th	= [0 0 0 1  0 1 0  0 0 1 0 0 0  0 0 0  0 0 0 0  0];
    features.ua	= [1 1 1 0  0 0 0  0 0 0 0 0 0  0 1 1  0 1 0 0  1];
    features.uh	= [1 1 1 0  0 0 0  0 0 0 0 0 0  0 0 1  1 0 0 0  1];
    features.uw	= [1 1 1 0  0 0 0  0 0 0 0 0 0  0 0 1  1 0 0 0  1];
    features.v	= [0 1 0 1  1 0 0  0 0 1 0 0 0  0 0 0  0 0 0 0  0];
    features.w	= [1 1 0 0  1 0 1  0 0 0 0 1 0  0 0 1  1 0 0 0  1];
    features.y	= [1 1 0 0  0 1 0  0 0 0 0 1 0  1 0 0  1 0 0 0  0];
    features.z	= [0 1 0 1  0 1 0  0 0 1 1 0 0  0 0 0  0 0 0 0  0];

end


