function naive_reconstruction()

    load_dir = fullfile('/Users', 'cai', 'Desktop', 'scratch', 'py_out');
    stimuli_dir = fullfile('/Users', 'cai', 'Desktop', 'scratch', 'the_400_used_stimuli');
    save_dir = fullfile('/Users', 'cai', 'Desktop', 'scratch', 'Reconstruction');

    bn26 = load(fullfile(load_dir, 'bn26_activations.mat'));
    bn26 = orderfields(bn26);

    words = fieldnames(bn26);
    n_words = numel(words);

    %% Get largest number of frames
    n_frames = 0;
    for word_i = 1:n_words
        word = words{word_i};
        word_data_size = size(bn26.(word));
        n_frames = max(n_frames, word_data_size(1));
        n_bn_nodes = word_data_size(2); % this should always be 26
    end
    
    %% Finding longest audio length
%     audio_length_max = 0;
%     for word_i = 1:n_words
%        word = words{word_i};
%        stimulus_path = fullfile(stimuli_dir, [word, '.wav']);
%        % Load in the data
%        [wav, sample_freq] = audioread(stimulus_path);
%        audio_length_max = max(audio_length_max, numel(wav));
%     end
    audio_length_max = 19430;
    
    %% Load in audio data
    audio_data = nan(n_words, audio_length_max);
    for word_i = 1:n_words
       word = words{word_i};
       stimulus_path = fullfile(stimuli_dir, [word, '.wav']);
       % Load in the data
       [wav, sample_freq] = audioread(stimulus_path);
       audio_data(word_i, 1:numel(wav)) = wav;
    end

    %% Load in bottleneck cube
    % Fill the data cube with nans to begin with.
    big_data_cube = nan(n_words, n_bn_nodes, n_frames);
    for word_i = 1:n_words
        word = words{word_i};
        this_word_data = bn26.(word);
        big_data_cube(word_i, :, 1:size(this_word_data, 1)) = this_word_data';
    end
    
    %% Big loop
    % For each word...
    for recon_word_i = 1:n_words
        recon_word = words{recon_word_i};
        
        recon_word_bn_data = bn26.(recon_word);
        n_recon_frames = size(recon_word_bn_data, 1);
        
        disp(['Reconstructing ', recon_word, ' (', num2str(recon_word_i), ')...']);
        
        % ...and each frame of that word
        for frame_i = 1:n_recon_frames
            
            disp(['    Frame ', num2str(frame_i), ':', num2str(n_recon_frames)]);
            
            % we take the bn-pattern for this frame
            recon_bn_pattern = recon_word_bn_data(frame_i, :)';
            
            % and correlate it with each frame pattern of each other word.
            best_corr = -inf;
            best_corr_word_i = nan;
            best_corr_frame_i = nan;
            for other_word_i = exrange(1, n_words, recon_word_i)
                other_word = words{other_word_i};
                other_word_bn_data = bn26.(other_word);
                
                corrs = corr(other_word_bn_data', recon_bn_pattern);
                [max_corr, max_corr_i] = max(corrs);
                if max_corr > best_corr
                   best_corr = max_corr;
                   best_corr_word_i = other_word_i;
                   best_corr_frame_i = max_corr_i;
                end
            end
            
            % We now have the location of the best bn-layer response match.
            % We use this to extract the segment of audio corresponding to
            % this frame.
            time_window = frame2time(best_corr_frame_i);
        end
    end
        

end%function

%% SUB FUNCTIONS

% Returns the range start:finish, but without the value omit.  Useful for
% leave-one-out loops.
function l = exrange(start, finish, omit)

    assert(start <= finish);
    assert(start <= omit);
    assert(omit <= finish);

    first_chunk = start:omit-1;
    second_chunk = omit+1:finish;
    l = [first_chunk, second_chunk];

end%function

% Returns the start and end time code from a frame number
function time_window = frame2time(frame_i)
    
end%function
