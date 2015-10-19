load_dir = fullfile('/Users', 'cai', 'Desktop', 'scratch', 'py_out');
save_dir = fullfile('/Users', 'cai', 'Desktop', 'scratch', 'figures_activations');

bn26 = load(fullfile(load_dir, 'bn26_activations.mat'));
bn26 = orderfields(bn26);

words = fieldnames(bn26);
n_words = numel(words);

% The number of nodes is constant for each word
[n_frames_ignore, n_nodes] = size(bn26.(words{1}));

% Get some info
clims = [-1, 1];
max_word_length = 1;
for word_i = 1:n_words
   word = words{word_i};
   
   clims(1) = min(clims(1), min(bn26.(word)(:)));
   clims(2) = max(clims(2), max(bn26.(word)(:)));
   
   max_word_length = max(max_word_length, size(bn26.(word), 1));
end

clims = centre_clims_on_zero(clims);

for node_i = 1:n_nodes
   
    % Extract data for this frame
    activation_data = nan(n_words, max_word_length);
    for word_i = 1:n_words
        word = words{word_i};
        this_word_length = size(bn26.(word), 1);
        % Add to matrix, leaving nans where the word is too short.
        activation_data(word_i, 1:this_word_length) = bn26.(word)(:, node_i)';
    end
    
    figure;
    this_figure = gcf;
    this_axis = gca;
    
    figure_size = [10, 10, 1400, 900];
    set(this_figure, 'Position', figure_size);

    pic = sanePColor(activation_data);
    set(pic, 'EdgeColor', 'none');
    set(this_axis, 'color', 'none');
    set(this_axis, 'box', 'off');
    caxis(clims);
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
