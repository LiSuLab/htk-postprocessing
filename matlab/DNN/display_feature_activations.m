% Produces word-by-frame activations for each feature

load_dir = fullfile('/Users', 'cai', 'Desktop', 'scratch', 'py_out');
save_dir = fullfile('/Users', 'cai', 'Desktop', 'scratch', 'figures_activations', 'features');

feature_models = feature_activations();
features = fieldnames(feature_models);

n_features = numel(features);
[n_words, n_frames] = size(feature_models.(features{1}));

% Everything should be in here.
clims = [0,1];
% But we want colours to match.
clims = centre_clims_on_zero(clims);

for feature_i = 1:n_features
    feature = features{feature_i};
    
    feature_data = feature_models.(feature);
    
    figure;
    this_figure = gcf;
    this_axis = gca;
    
    figure_size = [10, 10, 1400, 900];
    set(this_figure, 'Position', figure_size);

    pic = sanePColor(feature_data);
    set(pic, 'EdgeColor', 'none');
    set(this_axis, 'color', 'none');
    set(this_axis, 'box', 'off');
    caxis(clims);
    colorbar;
    colormap(bipolar);
    
    title(feature);
    
    this_frame = getframe(this_figure);

    % save the figure
    file_path = fullfile(save_dir, feature);
    
    imwrite(this_frame.cdata, [file_path, '.png'], 'png');

    close(this_figure);
    
end

