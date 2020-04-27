function [db_features, db_phones, db_features_tsne, db_phones_tsne] = scr_mds_HL_db_indices()

    %% Paths

    activations_dir = fullfile('/Users', 'cai', 'Desktop', 'scratch', 'py_out');
    tsne_dir = fullfile('/Users', 'cai', 'Desktop', 't-sne');
    
    
    %% Load segmentation data
    
    phone_segmentations = load(fullfile(activations_dir, 'triphone_boundaries.mat'));
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
        '7BN' ...
        };
    n_layers = numel(layers);
    
    PHONES = fieldnames(label_index_dictionary());
    n_phones = numel(PHONES);
    
    FEATURES = phonetic_feature_matrix_for_dnn_mds();
    feature_names = fieldnames(FEATURES);
    n_features = numel(feature_names);
    
    
    %% 
    
    db_features = nan(n_layers, 1);
    db_phones = nan(n_layers, 1);
    db_features_tsne = nan(n_layers, 1);
    db_phones_tsne = nan(n_layers, 1);
    
    for layer_i = 1:n_layers
        
        layer = layers{layer_i};

        layer_activations = load(fullfile(activations_dir, sprintf('hidden_layer_%s_activations.mat', layer)));
        layer_activations = orderfields(layer_activations);

        dims = size(layer_activations.(words{1}), 2);
        n_points = 22510;

        rsa.util.prints('Layer %s', layer);


        %% Initialise
        activations = nan(n_points, dims);
        overall_frame_i = 0;


        %% Stack up data

        for word_i = 1:n_words
            word = words{word_i};

            n_frames_this_word = size(layer_activations.(word), 1);

            for frame_i = 1:n_frames_this_word
                overall_frame_i = overall_frame_i + 1;

                activations(overall_frame_i, :) = layer_activations.(word)(frame_i, :);
            end
        end
        
        
        %% DB-indices
        
        Y_path = fullfile(tsne_dir, sprintf('Y_t-SNE_%s', layer));
        labels_path = fullfile(tsne_dir, sprintf('labels_t-SNE_%s', layer));
        Y = rsa.util.directLoad(Y_path);
        labels = rsa.util.directLoad(labels_path);
        
        feature_labels = ones(n_points, 1);
        for feature_i = 1:n_features
            feature_name = feature_names{feature_i};
            feature_profile = FEATURES.(feature_name);
            
            point_select = select_points_by_feature(labels, feature_profile);
            % use ones() in the feature labels and +1 here so that silence
            % phones get their own feature (labelled 1)
            feature_labels(point_select) = feature_i+1;
            
        end
        
        phone_labels = zeros(n_points, 1);
        for phone_i = 1:n_phones
            phone = PHONES{phone_i};
            point_select = select_points_by_phone(labels, phone);
            phone_labels(point_select) = phone_i;
            
        end
        
        % DB-indices per feature
        db_features(layer_i) = db_index(activations, feature_labels);
        
        % DB-indices per phone
        db_phones(layer_i) = db_index(activations, phone_labels);
        
        % DB-indices per feature (tsne)
        db_features_tsne(layer_i) = db_index(Y, feature_labels);
        
        % DB-indices per phone (tsne)
        db_phones_tsne(layer_i) = db_index(Y, phone_labels);
        
        
        
    end%for:layers
    
end%function


%% PRIVATE FUNCITONS %%

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
