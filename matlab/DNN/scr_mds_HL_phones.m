function [] = scr_mds_HL_phones()

    %% Paths

    load_dir  = fullfile('/Users', 'cai', 'Desktop', 'scratch', 'py_out');
    
    
    %% Load the necessary data
    
    phone_segmentations = load(fullfile(load_dir, 'triphone_boundaries.mat'));
    phone_segmentations = orderfields(phone_segmentations);
    
    layers = { ...
        'FBK', ...
        '2', ...
        '3', ...
        '4', ...
        '5', ...
        '6', ...
        '7BN', ...
        };
    n_layers = numel(layers);
    
    %% Constants

    words = fieldnames(phone_segmentations);
    n_words = numel(words);

    phones = get_used_phones(phone_segmentations);
    n_phones = numel(phones);

    framestep_ms = 10;
    framewidth_ms = 25;
    
    for layer_i = 1:n_layers
        
        layer = layers{layer_i};
    
        layer_activations = load(fullfile(load_dir, sprintf('hidden_layer_%s_activations.mat', layer)));
        layer_activations = orderfields(layer_activations);

        n_nodes = size(layer_activations.(words{1}), 2);
        
        rsa.util.prints('Layer %s', layer);


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
        
        figure;
        
        % 1 = sammon
        % 2 = t-sne
        kind = 2;
        
        if kind == 1

            D = pdist(phone_activations, 'correlation');
        
            figure_title = sprintf('Sammon MDS for layer %s', layer);

            if layer_i == 1
                % First time random initial positions
                prev_mds_position = 'random';
            end

            [Y] = mdscale(D, 2, ...
                'Criterion', 'sammon', ...
                'Start', prev_mds_position);

            % Reuse previous position next time
            prev_mds_position = Y;
            
        elseif kind == 2
        
            figure_title = sprintf('t-SNE for layer %s', layer);
            
            labels = [];
            no_dims = 2;
            init_dims = 25;
            Y = tsne(phone_activations, labels, no_dims, init_dims);
            
        end

        plot(Y(:,1),Y(:,2), '.', 'Marker','none');
        text(Y(:,1),Y(:,2), phones, 'Color','b', ...
            'FontSize',12,'FontWeight','bold', 'HorizontalAlignment','center');
        h_gca = gca;
        h_gca.XTickLabel = [];
        h_gca.YTickLabel = [];
        
        title(figure_title);
        
        
%         %% Dendrogram
%         
%         figure;
%         
%         tree = linkage(D, 'single');
%         leaf_order = optimalleaforder(tree, D);
%         
%         dendrogram( ...
%             tree, n_phones, ...
%             ...%'Reorder', leaf_order, ...
%             'Labels', phones);
        

    end
    
end%function
