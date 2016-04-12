function dRDMs = dnn_layer_dRDMs(distance_type)

    if ~exist('distance_type', 'var'), distance_type = 'correlation'; end

    node_activations.L2   = load('/Users/cai/Desktop/scratch/py_out/hidden_layer_2_activations.mat');
    node_activations.L3   = load('/Users/cai/Desktop/scratch/py_out/hidden_layer_3_activations.mat');
    node_activations.L4   = load('/Users/cai/Desktop/scratch/py_out/hidden_layer_4_activations.mat');
    node_activations.L5   = load('/Users/cai/Desktop/scratch/py_out/hidden_layer_5_activations.mat');
    node_activations.L6   = load('/Users/cai/Desktop/scratch/py_out/hidden_layer_6_activations.mat');
    node_activations.L7BN = load('/Users/cai/Desktop/scratch/py_out/hidden_layer_7BN_activations.mat');
    
    layer_names = fieldnames(node_activations);
    n_layers = numel(layer_names);
    
    words = fieldnames(node_activations.(layer_names{1}));
    n_words = numel(words);
    
    % Only need this once
    shortest_word_length = inf;
    for word_i = 1:n_words
        word = words{word_i};
        [word_length, n_nodes] = size(node_activations.(layer_names{1}).(word));
        shortest_word_length = min(shortest_word_length, word_length);
    end
    
    dRDMs = struct();
    for l = 1:n_layers
        layer_name = layer_names{l};
        n_nodes_this_layer = size(node_activations.(layer_name).(words{1}), 2);
        for t = 1:shortest_word_length
           data_this_timepoint = nan(n_words, n_nodes_this_layer);
           for word_i = 1:n_words
               word = words{word_i};
               word_activation = node_activations.(layer_name).(word);
               data_this_timepoint(word_i, :) = word_activation(t, :);
           end
           RDM_this_timepoint = pdist(data_this_timepoint, distance_type);
           dRDMs(t).(layer_name).RDM = RDM_this_timepoint;
           dRDMs(t).(layer_name).Name = sprintf('%s,t=%02d', layer_name, t);
        end
    end

end%function
