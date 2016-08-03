function [] = scr_convert_fbk_to_hl_format()

    segmentation_load_dir  = fullfile('/Users', 'cai', 'Desktop', 'scratch', 'py_out');
    phone_segmentations = load(fullfile(segmentation_load_dir, 'triphone_boundaries.mat'));
    phone_segmentations = orderfields(phone_segmentations);
    words = fieldnames(phone_segmentations);
    n_words = numel(words);

    all_data = struct();

    for frame = 0:37
        
       frame_data_file = sprintf('~/Desktop/scratch/py_out/filterbank/fbanks_frame%02d.mat', frame);
       frame_data = load(frame_data_file);
       
       for word_i = 1:n_words
           word = words{word_i};
           
           if frame == 0
               % First time
               all_data.(word) = frame_data.(word);
           else
               all_data.(word) = [ all_data.(word); frame_data.(word) ];
           end
       end
    end
    
    % Wow, so this is going into 'py_out', even though this isn't python.
    % In retrospect, this is a poor way to organise files.
    output_path = '~/Desktop/scratch/py_out/hidden_layer_FBK_activations.mat';
    save(output_path, '-struct', 'all_data', '-v7.3');

end
