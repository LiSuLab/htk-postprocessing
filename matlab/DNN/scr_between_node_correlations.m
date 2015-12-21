load_dir = fullfile('/Users', 'cai', 'Desktop', 'scratch', 'py_out');
save_dir = fullfile('/Users', 'cai', 'Desktop', 'scratch', 'figures_activations');

bn26 = load(fullfile(load_dir, 'bn26_activations.mat'));
bn26 = orderfields(bn26);

words = fieldnames(bn26);
n_words = numel(words);
n_nodes = size(bn26.(words{1}), 2);

% Get largest number of frames
n_frames = 0;
for word_i = 1:n_words
    word = words{word_i};
    word_data_size = size(bn26.(word));
    n_frames = max(n_frames, word_data_size(1));
    n_bn_nodes = word_data_size(2); % this should always be 26
end

% Get node data into matrix
node_data = nan(n_words, n_frames, n_nodes);
for node_i = 1:n_nodes
    for word_i = 1:n_words
        word = words{word_i};
        word_length = size(bn26.(word), 1);
        % Add to matrix, leaving nans where the word is too short.
        node_data(word_i, 1:word_length, node_i) = bn26.(word)(:, node_i)';
    end
end

%node_data = rand(n_words, round(n_frames/4), n_nodes);

node_corr = nan(n_nodes);
max_corr = -inf;
min_corr = inf;
for node_i = 1:n_nodes
    node_i_data = node_data(:, :, node_i);
    node_i_data = node_i_data(:);
    node_i_data = node_i_data(~isnan(node_i_data));
    for node_j = 1:n_nodes
        if node_i == node_j
            % Set diagonal as 1
            node_corr(node_i, node_j) = 1;
        else
            % otherwise get the actual correlation
            node_j_data = node_data(:, :, node_j);
            node_j_data = node_j_data(:);
            node_j_data = node_j_data(~isnan(node_j_data));
            r = corr(node_i_data, node_j_data);
            node_corr(node_i, node_j) = r;
            max_corr = max(max_corr, r);
            min_corr = min(min_corr, r);
        end
    end
end

clims = [-1,1];

imagesc(node_corr, clims);
cbar = colorbar;
colormap(bipolar);

min_corr
max_corr
