load_dir = fullfile('/Users', 'cai', 'Desktop', 'scratch', 'py_out');
save_dir = fullfile('/Users', 'cai', 'Desktop', 'scratch', 'figures_activations');

feature_models = feature_activations();
features = fieldnames(feature_models);

bn26 = load(fullfile(load_dir, 'bn26_activations.mat'));
bn26 = orderfields(bn26);

words = fieldnames(bn26);

n_features = numel(features);
[n_words, n_frames] = size(feature_models.(features{1}));
n_nodes = size(bn26.(words{1}), 2);

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

% Correlate nodes and features.
node_feature_matches = nan(n_nodes, n_features);
for feature_i = 1:n_features
    feature = features{feature_i};
    
    feature_vector = feature_models.(feature)(:);
    feature_vector = feature_vector(~isnan(feature_vector));
    
    for node_i = 1:n_nodes
        
        node_vector = node_data(:, :, node_i);
        node_vector = node_vector(:);
        node_vector = node_vector(~isnan(node_vector));
        
        node_feature_matches(node_i, feature_i) = corr(node_vector, feature_vector);%, 'type', 'Spearman');
        
    end
end

clims = [ ...
    min(node_feature_matches(:)), ...
    max(node_feature_matches(:)) ...
];

clims = centre_clims_on_zero(clims);

figure;

this_figure = gcf;
    
figure_size = [10, 10, 1400, 900];
set(this_figure, 'Position', figure_size);

imagesc(node_feature_matches, clims);
colorbar;
colormap(bipolar);

node_labels = {};
for node_i = 1:n_nodes
    node_labels = [node_labels, {['node', num2str(node_i)]}];
end

ax = gca;

set(ax, 'XTick', 1:n_features);
set(ax, 'YTick', 1:n_nodes);

ax.XTickLabel = features;
ax.YTickLabel = node_labels;
ax.XTickLabelRotation = 45;
ax.YTickLabelRotation = 45;

this_frame = getframe(this_figure);

% save the figure
file_path = fullfile(save_dir, 'node_feature_correspondence');

imwrite(this_frame.cdata, [file_path, '.png'], 'png');

close(this_figure);
