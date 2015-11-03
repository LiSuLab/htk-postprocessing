% Produces sliding-window-matched plots for the instances of each phone for
% each word.
%
% phones: A cell array of phones.
function [] = phone_activations(segmentations)

    % sliding window specification
    WINDOW_WIDTH = 25; % ms
    WINDOW_STEP  = 10; % ms
    
    phones = get_used_phones(segmentations);
    words = fieldnames(segmentations);
    
    n_phones = numel(phones);
    n_words = numel(words);
    
    % These phone plots will model the node plots, so we will produce
    % word-by-time plots for each phone.
    
    max_word_length = 1;
    for word_i = 1:n_words
       word = words{word_i};
       max_word_length = max(max_word_length, size(bn26.(word), 1));
    end
    
    phone_models = struct();
    
    for phone_i = 1:n_phones
        phone = phones{phone_i};
        
        % Initialise empty matrix
        phone_models.(phone) = nan(n_words, max_word_length);
        
        for word_i = 1:n_words
            word = words{word_i};
            
            % move a virtual sliding window throughout the segmentatino of
            % the word to get a model activation map for this phone.
            
            % Most words don't have most phones, so we can quickly check
            % that and just insert all zeros where necessary.
            
            this_word_phones = unique({ segmentations.(word)(:).label });
            
            if any(strcmpi(this_word_phones, phone))
                % The phone is in the word
                % TODO
                
            else
                % The phone is not in the word, so we can just add zeros in
                % place of the convolution.
                
            end
            
            sliding_window_intervals
        end
    end

end
