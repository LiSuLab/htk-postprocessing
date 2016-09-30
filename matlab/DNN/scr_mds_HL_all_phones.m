function [] = scr_mds_HL_all_phones()

    %% Params

    % 1 = sammon
    % 2 = t-sne
    kind = 2;

    
    %% Paths

    load_dir  = fullfile('/Users', 'cai', 'Desktop', 'scratch', 'py_out');
    save_dir = fullfile('/Users', 'cai', 'Desktop', 'temp');
    
    
    %% Load segmentation data
    
    phone_segmentations = load(fullfile(load_dir, 'triphone_boundaries.mat'));
    phone_segmentations = orderfields(phone_segmentations);
    
    
    %% Constants

    words = fieldnames(phone_segmentations);
    n_words = numel(words);
    
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
    
    
    %% 
    
    for layer_i = 1:n_layers
        
        layer = layers{layer_i};
        
        % Save path
        if kind == 1
            Y_path = fullfile(save_dir, sprintf('Y_Sammon_%s', layer));
        elseif kind == 2
            Y_path = fullfile(save_dir, sprintf('Y_t-SNE_%s', layer));
        end
        labels_path = fullfile(save_dir, sprintf('labels_t-SNE_%s', layer));
        
        
        %% Check if positional data already exists
        
        if ~exist([Y_path '.mat'], 'file')
            
            % MDS data doesn't exist, so we have to create it
    
            layer_activations = load(fullfile(load_dir, sprintf('hidden_layer_%s_activations.mat', layer)));
            layer_activations = orderfields(layer_activations);

            n_nodes = size(layer_activations.(words{1}), 2);

            rsa.util.prints('Layer %s', layer);


            %% Initialise
            activations = nan(22510, n_nodes);
            labels = cell(22510,1);
            overall_frame_i = 0;


            %% Stack up data

            for word_i = 1:n_words
                word = words{word_i};

                this_word_segmentation = phone_segmentations.(word);

                n_frames_this_word = size(layer_activations.(word), 1);

                for frame_i = 1:n_frames_this_word
                    overall_frame_i = overall_frame_i + 1;

                    activations(overall_frame_i, :) = layer_activations.(word)(frame_i, :);
                    labels{overall_frame_i} = this_frame_label(this_word_segmentation, frame_i);
                end
            end
            
            % Save the labels
            save(labels_path, 'labels', '-v7.3');


            %% MDS

            if kind == 1

                D = pdist(activations, 'correlation');
                Y = mdscale(D, 2, ...
                    'Criterion', 'sammon');

                % Save Y
                save(Y_path, 'Y', '-v7.3')

            elseif kind == 2
                
                lab = [];
                no_dims = 2;
                init_dims = 25;

                Y = fast_tsne(activations, lab, no_dims, init_dims);

                % Save Y
                save(Y_path, 'Y', '-v7.3')

            end
            
        else
            
            % MDS data has been previously calculated, so we can just load
            % it
            
            Y = rsa.util.directLoad(Y_path);
            labels = rsa.util.directLoad(labels_path);
            
        end
        
        
        %% Overall figure
        
        if kind == 1
            figure_title = sprintf('Sammon MDS for layer %s', layer);
        elseif kind == 2
            figure_title = sprintf('t-SNE for layer %s', layer);
        end
        
        f = figure;
        
        area = 2;
        colours = labels_to_colours(labels);
        scatter(Y(:,1),Y(:,2), area, colours, 'filled');
        
        feature_title = figure_title;
        title(feature_title);
        
        % Get axis limits for coregistration
        x_limits = get(gca,'XLim');
        y_limits = get(gca,'YLim');
        
        % save fig
        fig_path = fullfile(save_dir, rsa.util.spacesToUnderscores(feature_title));
        saveas(f, fig_path, 'epsc');

        close(f);
        
        %% Images per feature
        
        FEATURES = phonetic_feature_matrix_for_dnn_mds();
        feature_names = fieldnames(FEATURES);
        n_features = numel(feature_names);
        
        for feature_i = 1:n_features
            
            f = figure;
            
            feature_name = feature_names{feature_i};
            feature_profile = FEATURES.(feature_name);
        
            point_select = select_points_by_feature(labels, feature_profile);
            
            scatter(Y(point_select,1),Y(point_select,2), area, 'filled');
            
            % Set ais limits for coregistration
            xlim(x_limits);
            ylim(y_limits);
            
            feature_title = sprintf('%s (%s)', figure_title, feature_name);
            title(feature_title);
            
            % save fig
            fig_path = fullfile(save_dir, rsa.util.spacesToUnderscores(feature_title));
            saveas(f, fig_path, 'epsc');
            
            close(f);
            
        end
        
        
        %% Per phone
        PHONES = fieldnames(label_index_dictionary());
        n_phones = numel(PHONES);
        
        for phone_i = 1:n_phones
            phone = PHONES{phone_i};
           
            f = figure;
            
            point_select = select_points_by_phone(labels, phone);
            
            scatter(Y(point_select,1),Y(point_select,2), area, 'filled');
            
            % Set ais limits for coregistration
            xlim(x_limits);
            ylim(y_limits);
            
            feature_title = sprintf('%s (phone %s)', figure_title, phone);
            title(feature_title);
            
            % save fig
            fig_path = fullfile(save_dir, rsa.util.spacesToUnderscores(feature_title));
            saveas(f, fig_path, 'epsc');
            
            close(f);
            
        end
    end
    
end%function


function colours = labels_to_colours(labels)

    label_indices = label_index_dictionary();
    
    n_labels = numel(fieldnames(label_indices));
    
    cmap = hsv(n_labels);

    n_labels_overall = numel(labels);
    
    colours = nan(n_labels_overall, 3);
    
    for label_i = 1:n_labels_overall
       label = labels{label_i};
       colours(label_i, :) = cmap(label_indices.(label), :);
    end
end


function point_select = select_points_by_feature(labels, feature_profile)

    n_labels_overall = numel(labels);

    label_indices = label_index_dictionary();
    
    point_select = zeros(n_labels_overall, 1);
    for label_i = 1:n_labels_overall
       label = labels{label_i};
       point_select(label_i) = feature_profile(label_indices.(label));
    end
    
    point_select = logical(point_select);
end


function point_select = select_points_by_phone(labels, phone)

    n_labels_overall = numel(labels);
    
    point_select = zeros(n_labels_overall, 1);
    for label_i = 1:n_labels_overall
       label = labels{label_i};
       if strcmpi(label, phone)
           point_select(label_i) = 1;
       end
    end
    
    point_select = logical(point_select);
end


function label_indices = label_index_dictionary()
    label_indices.aa 	= 2;
    label_indices.ae 	= 3;
    label_indices.ah 	= 4;
    label_indices.ao 	= 5;
    label_indices.aw 	= 6;
    label_indices.ay 	= 7;
    label_indices.b 	= 8;
    label_indices.ch 	= 9;
    label_indices.d 	= 10;
    label_indices.ea 	= 11;
    label_indices.eh 	= 12;
    label_indices.er 	= 13;
    label_indices.ey 	= 14;
    label_indices.f 	= 15;
    label_indices.g 	= 16;
    label_indices.hh 	= 17;
    label_indices.ia 	= 18;
    label_indices.ih 	= 19;
    label_indices.iy 	= 20;
    label_indices.jh 	= 21;
    label_indices.k 	= 22;
    label_indices.l 	= 23;
    label_indices.m 	= 24;
    label_indices.n 	= 25;
    label_indices.ng 	= 26;
    label_indices.oh 	= 27;
    label_indices.ow 	= 28;
    label_indices.oy 	= 29;
    label_indices.p 	= 30;
    label_indices.r 	= 31;
    label_indices.s 	= 32;
    label_indices.sh 	= 33;
    label_indices.t 	= 34;
    label_indices.th 	= 35;
    label_indices.ua 	= 36;
    label_indices.uh 	= 37;
    label_indices.uw 	= 38;
    label_indices.v 	= 39;
    label_indices.w 	= 40;   
    label_indices.y 	= 41;
    label_indices.z 	= 42;
    label_indices.sil   = 1;
end


function label = this_frame_label(word_segmentation, frame_i)

    FRAME_STEP_ms = 10;
    FRAME_WIDTH_ms = 25;

    % -1 because frame_i=1 means 0ms
    frame_onset_ms = (frame_i - 1) * FRAME_STEP_ms;
    frame_offset_ms = frame_onset_ms + FRAME_WIDTH_ms;

    n_segments_this_word = size(word_segmentation, 2);
    
    label = nan;
    
    for segment_i = 1:n_segments_this_word
       
        segment_onset_ms = double(word_segmentation(segment_i).onset) / 10000;
        segment_offset_ms = double(word_segmentation(segment_i).offset) / 10000;
        
        overlap = get_interval_overlap([frame_onset_ms, frame_offset_ms], [segment_onset_ms, segment_offset_ms]);
        
        if overlap < 0.5
            
            %fix for final frame
            if (frame_offset_ms > segment_offset_ms) && (segment_i == n_segments_this_word)
                label = word_segmentation(n_segments_this_word).label;
                break;
            else
                continue;
            end
        elseif overlap >= 0.5
            label = word_segmentation(segment_i).label;
            break;
        end
        
    end

end
