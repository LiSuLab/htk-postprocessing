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

%% All nodes and features in same data matrix
n_entries = n_nodes + n_features;

entry_data = nan(n_words, n_frames, n_entries);


entry_labels = {};
% Nodes first
for node_i = 1:n_nodes
    entry_labels = [entry_labels, {['node', num2str(node_i)]}];
    for word_i = 1:n_words
        word = words{word_i};
        word_length = size(bn26.(word), 1);
        % Add to matrix, leaving nans where the word is too short.
        entry_data(word_i, 1:word_length, node_i) = bn26.(word)(:, node_i)';
    end
end
% Features second
for feature_i = 1:n_features
    feature = features{feature_i};
    entry_labels = [entry_labels, {feature}];
    entry_i = n_nodes + feature_i;
    entry_data(:, :, entry_i) = feature_models.(feature)(:, :);
end

% Reshape away the word dimension
entry_data_reshaped = nan(n_entries, n_words * n_frames);
for entry_i = 1:n_entries
    data_this_entry = entry_data(:, :, entry_i);
    entry_data_reshaped(entry_i, :) = data_this_entry(:);
end


%% Correlate nodes and features.

similarity_matrix = nan(n_entries, n_entries);
for entry_i = 1:n_entries
    rsa.util.prints('Entry %d of %d...', entry_i, n_entries);
    
    data_vector_i = entry_data_reshaped(entry_i, :);
    
    for entry_j = entry_i + 1: n_entries
        data_vector_j = entry_data_reshaped(entry_j, :);
        
        similarity_matrix(entry_i, entry_j) = corr(data_vector_i', data_vector_j', 'rows', 'complete', 'type', 'Spearman');
        %symmetric
        similarity_matrix(entry_j, entry_i) = similarity_matrix(entry_i, entry_j);
        
    end
end

% force diagonal to be 1
similarity_matrix(find(eye(n_entries))) = 1;

distance_matrix = 1 - similarity_matrix;


%% Similarity matrix figure

clims = [ ...
    min(similarity_matrix(:)), ...
    max(similarity_matrix(:)) ...
];

%clims = centre_clims_on_zero(clims);
clims = [-1, 1];

figure;

this_figure = gcf;
    
figure_size = [10, 10, 1200, 900];
set(this_figure, 'Position', figure_size);

imagesc(similarity_matrix, clims);
colorbar;
colormap(hot);

ax = gca;

set(ax, 'XTick', 1:n_entries);
set(ax, 'YTick', 1:n_entries);

ax.XTickLabel = entry_labels;
ax.YTickLabel = entry_labels;
ax.XTickLabelRotation = 45;
ax.YTickLabelRotation = 45;

this_frame = getframe(this_figure);

% save the figure
file_path = fullfile(save_dir, 'node_feature_correspondence');

imwrite(this_frame.cdata, [file_path, '.png'], 'png');

close(this_figure);


%% MDS figure

figure;

this_figure = gcf;
    
figure_size = [10, 10, 900, 900];
set(this_figure, 'Position', figure_size);

D = squareform(distance_matrix);
[points_2d, stress, disparities] = mdscale(D, 2, ...
    'criterion', 'strain', ...
    'start', 'random', ...
    'options', struct( ...
        'MaxIter', 1000), ...
    'replicates', 5);
mdso = struct();
mdso.textLabels = entry_labels;
mdso.dotSize = 8;
mdso.fontSize = 10;
mdso.dotColours = [ ...
    ...nodes
    repmat([1 0 0], [26, 1]); ...
    ...%categories
    repmat([0.7 0.7 0], [4 , 1]); ...
    ...%place
    repmat([0 1 0], [3 , 1]); ...
    ...%manner
    repmat([0 0.5 1], [4 , 1]); ...
    ...%frontness
    repmat([0 0 1], [3 , 1]); ...
    ...%closeness
    repmat([0 0.5 0.5], [4 , 1]); ...
    ...%rounded
    repmat([.7 0 .7], [1 , 1]); ...
    ];
rsa.fig.plotDotsWithTextLabels(points_2d, mdso);

this_frame = getframe(this_figure);

% save the figure
file_path = fullfile(save_dir, 'node_feature_correspondence_mds');

imwrite(this_frame.cdata, [file_path, '.png'], 'png');

close(this_figure);

