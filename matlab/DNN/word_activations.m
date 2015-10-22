% Produces node-by-frame activation plots for each word
%
% Adds phone boundary markers.

load_dir = fullfile('/Users', 'cai', 'Desktop', 'scratch', 'py_out');
save_dir = fullfile('/Users', 'cai', 'Desktop', 'scratch', 'figures_activations', 'words');

bn26 = load(fullfile(load_dir, 'bn26_activations.mat'));
bn26 = orderfields(bn26);

segmentations = load(fullfile(load_dir, 'triphone_boundaries.mat'));
segmentations = orderfields(segmentations);

words = fieldnames(bn26);
n_words = numel(words);
[n_frames, n_nodes] = size(bn26.(words{1}));

% Get some info
clims = [-1, 1];
for word_i = 1:n_words
   word = words{word_i};
   clims(1) = min(clims(1), min(bn26.(word)(:)));
   clims(2) = max(clims(2), max(bn26.(word)(:)));
end

clims = centre_clims_on_zero(clims);

for word_i = 1:n_words
    word = words{word_i};
    
    %% Create the activation map
    
    figure;
    this_figure = gcf;
    this_axis = gca;

    figure_size = [10, 10, 1400, 900];
    set(this_figure, 'Position', figure_size);
    
    imagesc(bn26.(word)', clims);

    colorbar;
    colormap(bipolar);

    title(word, 'FontSize', 40);
    
    %% Phone boundary markers
    
    % We want to add the boundary markers at the frame index whose sliding
    % window is centred over the boundary.
    %
    % Recall that the frame indices mark the *start* of the sliding window,
    % so that frame 1 covers the period [0, 25]ms.
    %
    % Were the 25ms frames moving continuously, the frame centred on a
    % boundary would begin 12.5ms before the boundary, so we move all
    % boundaries to the left by 12.5ms (1.25 of a 10ms timestep).
	%
	% We also need to convert from ms (0-indexed) to frames (1-indexed)
    
    segmentation = segmentations.(word);
    for seg_i = 1:numel(segmentation)
        % Get segmentation data                           to ms    offset  to framestep (timestep)
        %                                                /        /       /     ,1-index correction
        onset  = (((double(segmentation(seg_i).onset)  / 10000) - 12.5) / 10) + 1;
        offset = (((double(segmentation(seg_i).offset) / 10000) - 12.5) / 10) + 1;
        phone  = segmentation(seg_i).label;
        
        middle = (onset + offset) / 2;
        
        % onset line
        line([onset  onset],  [0 26.5], 'LineWidth', 3, 'Color', [1, 1, 1], 'LineStyle','--');
        % offset line
        %line([offset offset], [0 26.5], 'LineWidth', 3, 'Color', [0, 0, 0], 'LineStyle','--');
        % text label
        t = text(middle, 13, phone, 'Color', 'white', 'FontSize', 20);
        set(t, 'HorizontalAlignment', 'Center');
        set(t, 'VerticalAlignment', 'middle');
    end%for

    %% save the figure
    
    this_frame = getframe(this_figure);
    file_path = fullfile(save_dir, sprintf('word_%s', word));
    imwrite(this_frame.cdata, [file_path, '.png'], 'png');

    close(this_figure);
   
end
