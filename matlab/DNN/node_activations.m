load_dir = fullfile('/Users', 'cai', 'Desktop', 'scratch', 'py_out');
save_dir = fullfile('/Users', 'cai', 'Desktop', 'scratch', 'figures_activations');

bn26 = load(fullfile(load_dir, 'bn26_activations.mat'));
bn26 = orderfields(bn26);

words = fieldnames(bn26);
n_words = numel(words);
[n_frames, n_nodes] = size(bn26.(words{1}));

% Get clims
clims = [-1, 1];
for word_i = 1:n_words
   word = words{word_i};
   clims(1) = min(clims(1), min(bn26.(word)(:)));
   clims(2) = max(clims(2), max(bn26.(word)(:)));
end

clims = centre_clims_on_zero(clims);

for node_i = 1:n_nodes
   
    % Extract data for this frame
    activation_data = nan(n_words, n_frames);
    for word_i = 1:n_words
        word = words{word_i};
        activation_data(word_i, :) = bn26.(word)(:, node_i)';
    end
    
    figure;
    this_figure = gcf;
    this_axis = gca;
    
    figure_size = [10, 10, 1400, 900];
    set(this_figure, 'Position', figure_size);

    imagesc(activation_data, clims);
    colorbar;
    colormap(bipolar);
    
    node_name = sprintf('node%02d', node_i);
    title(node_name);
    
    this_frame = getframe(this_figure);

    % save the figure
    file_path = fullfile(save_dir, node_name);
    
    imwrite(this_frame.cdata, [file_path, '.png'], 'png');

    close(this_figure);
    
end
