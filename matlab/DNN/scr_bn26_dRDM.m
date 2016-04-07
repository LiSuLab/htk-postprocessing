load_dir = fullfile('/Users', 'cai', 'Desktop', 'scratch', 'py_out');
save_dir = fullfile('/Users', 'cai', 'Desktop', 'scratch', 'RDMs');
figs_dir = fullfile('/Users', 'cai', 'Desktop', 'scratch', 'figures_RDMs');

bn26 = load(fullfile(load_dir, 'bn26_activations.mat'));
bn26 = orderfields(bn26);

words = fieldnames(bn26);
n_words = numel(words);
[n_frames, n_nodes] = size(bn26.(words{1}));

%% Get node data into matrix

node_data = nan(n_words, n_nodes, n_frames);
for node_i = 1:n_nodes
    for word_i = 1:n_words
        word = words{word_i};
        word_length = size(bn26.(word), 1);
        % Add to matrix, leaving nans where the word is too short.
        node_data(word_i, node_i, 1:word_length) = bn26.(word)(:, node_i)';
    end
end

%% Create a word-by-word RDM for each frame

rsa.util.prints('Loading bn26 data...');

square_RDM_stack = nan(n_words, n_words, n_frames);
output_RDMs = repmat(struct('RDM', nan), n_frames, 1);

for frame_i = 1:n_frames
    
    rsa.util.prints('Creating RDM for frame %02d...', frame_i);
    
    output_RDMs(frame_i) = struct('RDM', pdist(node_data(:, :, frame_i)));
    square_RDM_stack(:, :, frame_i) = squareform(output_RDMs(frame_i).RDM);
    
end

%% Save the RDM stack

save(fullfile(save_dir, 'bn26_models'), 'output_RDMs');


%% Display the RDMs

my_fave_colormap = hot;
figure_size = [10, 10, 1400, 900];

for frame_i = 1:n_frames
    
    rsa.util.prints('Visualising RDM for frame %02d...', frame_i);
    
    % Really gotta do something about this nonsense
    RDM_name = ['frame ', num2str(frame_i)];
    rsa.fig.showRDMs(struct('RDM', square_RDM_stack(:, :, frame_i), 'name', RDM_name), 1, 1, [], 1, [], {}, my_fave_colormap);
    
    this_figure = gcf;
    
    set(this_figure, 'Position', figure_size);
    
    this_frame = getframe(this_figure);
    
    % save this figure
    figure_name = sprintf('RDM_frame_%02d', frame_i);
    figure_path = fullfile(figs_dir, figure_name);
    
    imwrite(this_frame.cdata, [figure_path, '.png'], 'png');

    close(this_figure);
    
    % Add this figure's image data to the stack
    if frame_i == 1
        [image_stack, im_map256] = rgb2ind(this_frame.cdata, 256, 'nodither');
        image_stack(1, 1, 1, n_frames) = 0;
    else
        image_stack(:, :, 1, frame_i) = rgb2ind(this_frame.cdata, im_map256, 'nodither');
    end
    
end

% Save out animated gif

imwrite(image_stack, im_map256, fullfile(figs_dir, 'bn26_RDMs_all.gif'), 'DelayTime', 0.2, 'LoopCount', inf);

