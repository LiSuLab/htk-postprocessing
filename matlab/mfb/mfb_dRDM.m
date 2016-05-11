function dRDM = mfb_dRDM(distance_type)

    input_dir  = fullfile('/Users', 'cai', 'Desktop', 'ece_scratch', 'py_out', 'ece_mfb');
    
    TSTEP_ms = 10;
    WWIDTH_ms = 25;

    n_frames = 30;
    fname_template = fullfile(input_dir, 'fbanks_frame%02d.mat');
    temp_fbk = load(sprintf(fname_template, 0));
    temp_fbk = orderfields(temp_fbk);
    
    words = fieldnames(temp_fbk);
    n_words = numel(words);
    
    dRDM = struct();
    
    for f = 1:n_frames
        
        fbk_this_frame = load(sprintf(fname_template, f-1));
        fbk_this_frame = orderfields(fbk_this_frame);
        
        fbank_dim = numel(fbk_this_frame.(words{1}));
        
        data_this_frame = nan(n_words, fbank_dim);
        
        for word_i = 1:n_words
            word = words{word_i};
            data_this_frame(word_i, :) = fbk_this_frame.(word);
        end
        
        rdm_this_frame = pdist(data_this_frame, distance_type);
        
        window_start = (f-1) * TSTEP_ms;
        window_end = window_start + WWIDTH_ms;
        
        dRDM(f).RDM = rdm_this_frame;
        dRDM(f).Name = sprintf('Ece mel filterbank frame%02d [%03d, %03d]ms.', f-1, window_start, window_end);
        
    end
    
end
