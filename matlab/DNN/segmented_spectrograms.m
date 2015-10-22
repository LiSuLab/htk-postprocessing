% Plots phone-segmented spectrograms for all words

load_dir  = fullfile('/Users', 'cai', 'Desktop', 'scratch', 'py_out');
words_dir = fullfile('/Users', 'cai', 'Desktop', 'scratch', 'the_400_used_stimuli');
save_dir  = fullfile('/Users', 'cai', 'Desktop', 'scratch', 'figures_activations', 'words');

segmentations = load(fullfile(load_dir, 'triphone_boundaries.mat'));
segmentations = orderfields(segmentations);

words = fieldnames(segmentations);
n_words = numel(words);

for word_i = 1:n_words
    word = words{word_i};
    file_name = [word, '.wav'];
    file_path = fullfile(words_dir, file_name);
    plot_spectrogram(word, file_path, segmentations.(word), save_dir);
end
