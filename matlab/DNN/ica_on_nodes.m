function [Z_ica] = ica_on_nodes(n_ica_components)

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
    
    
    %% ICA
    
    % (d x n): n samples of d-dim state
    Z = data_matrix';
    
    % Do the ica
    [ ...
        ...% Z_ica is (r x n) is n samples of r ica components
        Z_ica, ...
        A_ica, T_ica, ...
        ...% mu_ica is sample mean of data
        mu_ica] = myICA(Z, n_ica_components);
    %r-dim approx of data: Zr = T \ pinv(A) * Zi + repmat(mu, 1, n)

end
