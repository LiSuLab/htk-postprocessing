bn26 = load('bn26_activations.mat');
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

% Animate
for frame_i = 1:n_frames
   
    % Extract data for this frame
    activation_data = nan(n_words, n_nodes);
    for word_i = 1:n_words
        word = words{word_i};
        activation_data(word_i, :) = bn26.(word)(frame_i, :);
    end
    
    figure;
    this_figure = gcf;
    
    imagesc(activation_data, clims);
    colorbar;
    colormap(bipolar);
    
    f = getframe(this_figure);
    
    if frame_i == 1
        [image_stack, map] = rgb2ind(f.cdata, 256, 'nodither');
        image_stack(1, 1, 1, n_frames) = 0;
    else
        image_stack(:, :, 1, frame_i) = rgb2ind(f.cdata, map, 'nodither');
    end
    
    close(this_figure);
    
end

imwrite(image_stack, map, 'time.gif', 'DelayTime', 0.2, 'LoopCount', inf);

