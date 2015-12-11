function [coeff, score, latent, tsquared, explained, mu, data_matrix, Zica, A, T, muica] = pca_on_nodes

    load_dir = fullfile('/Users', 'cai', 'Desktop', 'scratch', 'py_out');
    save_dir = fullfile('/Users', 'cai', 'Desktop', 'scratch', 'figures_activations');

    bn26 = load(fullfile(load_dir, 'bn26_activations.mat'));
    bn26 = orderfields(bn26);

    words = fieldnames(bn26);
    n_words = numel(words);
    

    %% Data matrix

    % We want a matrix of all observations of the BN variabls that we have.
    % This includes all words and all timepoints.  So it will be a 26 x LONG
    % data matrix.
    
    data_matrix = [];

    for word_i = 1:n_words
        word = words{word_i};
        node_responses_this_word = bn26.(word);

        data_matrix = [data_matrix; node_responses_this_word];
    end
    
    [coeff, score, latent, tsquared, explained, mu] = pca(data_matrix);
    [Zica, A, T, muica] = myICA(data_matrix', 5);
    
    %orig
    node_1=4;node_2=16;figure;s=scatter(data_matrix(:, node_1), data_matrix(:, node_2)); s.Marker = '.';lsline;title(sprintf('%d-%d', node_1, node_2));
    %pca
    node_1=4;node_2=16;figure;s=scatter(coeff(:, node_1), coeff(:, node_2)); s.Marker = '.';lsline;title(sprintf('%d-%d', node_1, node_2));
    %ica
    node_1=1;node_2=2;figure;s=scatter(Zica(node_1,:)', Zica(node_2,:)'); s.Marker = '.';lsline;title(sprintf('%d-%d', node_1, node_2));

end
