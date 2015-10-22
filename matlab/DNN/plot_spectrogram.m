function plot_spectrogram(word, filepath, segmentation, save_dir)

    % Load in the data
    [wav, sample_freq] = audioread(filepath);
    
    % spectrogram parameters
    spect_window_size = 400;
    spect_window_overlap = 300;
    spect_freq_range = []; %default
    
    % figure parameters
    figure_size = [10, 10, 1400, 900];
    
    %% Create spectrogram
    figure;
    this_figure = gcf;
    this_axis = gca;
    
    set(this_figure, 'Position', figure_size);
    
    spectrogram(wav, spect_window_size, spect_window_overlap, spect_freq_range, sample_freq, 'yaxis');
    colormap(hot);
    
    title(word, 'FontSize', 40);
    
    %% Phone boundary markers
    for seg_i = 1:numel(segmentation)
        % Get segmentation data                        ,to ms
        onset  = (double(segmentation(seg_i).onset)  / 10000);
        offset = (double(segmentation(seg_i).offset) / 10000);
        phone  = segmentation(seg_i).label;
        
        middle = (onset + offset) / 2;
        
        % onset line
        %line([onset  onset],  [0 11], 'LineWidth', 3, 'Color', [1, 1, 1], 'LineStyle','--');
        % offset line
        line([offset offset], [0 11], 'LineWidth', 3, 'Color', [0, 0, 1], 'LineStyle','--');
        % text label
        t = text(middle, 5, phone, 'Color', [0, 0, 1], 'FontSize', 20);
        set(t, 'HorizontalAlignment', 'Center');
        set(t, 'VerticalAlignment', 'middle');
    end%for

    %% save the figure
    
    this_frame = getframe(this_figure);
    file_path = fullfile(save_dir, sprintf('word_%s_spectrogram', word));
    imwrite(this_frame.cdata, [file_path, '.png'], 'png');

    close(this_figure);

end