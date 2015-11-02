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
    audio_length_max = 0;
    for word_i = 1:n_words
       word = words{word_i};
       stimulus_path = fullfile(stimuli_dir, [word, '.wav']);
       [wav, sample_freq] = audioread(stimulus_path);
       audio_length_max = max(audio_length_max, numel(wav));
    end
    
    %% Load in audio data
    audio_data = nan(n_words, audio_length_max);
    audio_lengths = nan(n_words, 1);
    for word_i = 1:n_words
       word = words{word_i};
       stimulus_path = fullfile(stimuli_dir, [word, '.wav']);
       % Load in the data
       [wav, sample_freq] = audioread(stimulus_path);
       audio_lengths(word_i) = numel(wav);
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
        
        disp(['Reconstructing ', recon_word, ' (', num2str(recon_word_i), ')...']);
        
        % BN activations for each frame of the word to be reconstructed
        recon_word_bn_data = bn26.(recon_word);
        n_recon_frames = size(recon_word_bn_data, 1);
        
        % collect the data from the audio reconstruction
        recon_audio = nan(audio_lengths(word_i), 1);
        
        % ...and each frame of that word:
        for recon_frame_i = 1:n_recon_frames
            disp(['    Frame ', num2str(recon_frame_i), ':', num2str(n_recon_frames)]);
            
            % Take the BN activation pattern for this frame
            recon_bn_pattern = recon_word_bn_data(recon_frame_i, :)';
            
            % and correlate it with the pattern for each frame of each
            % other word.
            
            % best correlation to this frame so far
            best_corr = -inf;
            % word_i for best correlation so far
            best_corr_word_i = nan;
            % frame_i for best correlation so far
            best_corr_frame_i = nan;
            
            % For each other word
            for other_word_i = exrange(1, n_words, recon_word_i)
                other_word = words{other_word_i};
                
                % Get its data
                other_word_bn_data = bn26.(other_word);
                
                % Correlation every frame with the recon's current frame
                corrs = corr(other_word_bn_data', recon_bn_pattern);
                
                % find the best frame by correlation
                [max_corr, max_corr_i] = max(corrs);
                
                % If it's the best one so far, remember it.
                if max_corr > best_corr
                   best_corr = max_corr;
                   best_corr_word_i = other_word_i;
                   best_corr_frame_i = max_corr_i;
                end
            end
            
            % We now have the location of the best bn-layer response match.
            % We use this to extract the segment of audio corresponding to
            % this frame.
            
            % time window to exactract from
            extract_time_window = frame2time(best_corr_frame_i, sample_freq);
            
            % time window to insert into
            recon_time_window = frame2time(recon_frame_i, sample_freq);
            
            % extract the audio
            extracted_audio_fragment = audio_data(best_corr_word_i, win2range(extract_time_window));
            
            % insert the audio
            recon_audio(win2range(recon_time_window)) = extracted_audio_fragment(:);
            
            % continue with the next frame to reconstruct
        end
        
        % Save the audio
        audiowrite(fullfile(save_dir, [recon_word, '.wav']), recon_audio, sample_freq);
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
function time_window = frame2time(frame_i, sample_freq)
    FRAME_WIDTH_MS = 25;
    FRAME_STEP_MS = 10;
    
    start_time = FRAME_STEP_MS * (frame_i - 1);
    end_time = start_time + FRAME_WIDTH_MS;
    
    time_window = [ ...
        floor((sample_freq/1000) * start_time) + 1, ...
        floor((sample_freq/1000) * end_time), ...
    ];
    
end%function

function r = win2range(w)
    r = w(1):w(2);
end
