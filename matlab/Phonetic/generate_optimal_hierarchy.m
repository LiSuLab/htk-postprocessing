function [branching, M] = generate_optimal_hierarchy(model_rdms, output_dir)

    import rsa.*
    import rsa.rdm.*
    import rsa.util.*
    
    %% Models

    [M, PHONES, FEATURES] = phonetic_feature_matrix();
    
    n_timepoints = size(model_rdms, 1);
    
    n_entries = numel(rsa.rdm.vectorizeRDM(model_rdms(1, 1).RDM));
    
    n_phones  = numel(PHONES);
    n_features = numel(FEATURES);
    
    % Remove the outliers
    rdms(1:n_timepoints, n_phones) = struct('name', nan, 'RDM', nan, 'phone', nan);
    for phone_i = 1:n_phones
       % find the all_rdms-index for this phone
       this_phone = PHONES{phone_i};
       rdm_i = find(ismember({ model_rdms(1, :).phone }, lower(this_phone)));
       rdms(:, phone_i) = model_rdms(:, rdm_i);
    end
    
    clear all_rdms;
    
    
    %% Compte overall second-order similarity matrix for model RDMs
    
    % Get model RDMs into shape
    
    rsa.util.prints('Collecting data together...');
    
    all_model_data = nan(n_phones, n_timepoints, n_entries);
    
    for phone_i = 1:n_phones
        for t = 1:n_timepoints
            all_model_data(phone_i, t, :) = rsa.rdm.vectorizeRDM(rdms(t, phone_i).RDM);
        end
    end
    
    rsa.util.prints('Computing second-order distance matrix from dynamic RDMs...');
    
    if exist(fullfile(output_dir, 'hierarchy_D.mat'), 'file')
        D = rsa.util.directLoad(fullfile(output_dir, 'hierarchy_D'));
    else
        % Calculate dynamic distance matrix
        D = dynamic_second_order_distance_matrix(all_model_data, 'mean', 'Spearman');
        save(fullfile(output_dir, 'hierarchy_D'), 'D', '-v7.3');
    end
    
    %% Produce feature-based model-arrangement hypotheses
    
    feature_cat_rdms = nan(n_features, numel(D));
    for feature_i = 1:n_features
       feature_cat_rdms(feature_i, :) = binary_categorical_rdm(M(feature_i, :));
    end
    
    
    %% Fit hierarchy
    initial_phone_list = 1:n_phones;
    initial_feature_list = 1:n_features;

    branching = hierarchically_classify_features(initial_feature_list, initial_phone_list, feature_cat_rdms, D, M);
    

end%function

%% %%%%%%%%%%%%%%
% Sub functions %
%%%%%%%%%%%%%%%%%

function [branching] = hierarchically_classify_features(remaining_features, remaining_phones, feature_cat_rdms, D, M)

    n_remaining_features = numel(remaining_features);
    n_remaining_phones = numel(remaining_phones);

    % If somehow we only have one remaining phone, we just stop here
    if n_remaining_phones == 1
        branching = remaining_phones;
        return;
    end
    
    %% Find the feature which best separates the remaining phones at this level

    % Take the sub-matrices of D and feature_cat_rdms for the remaining features and phones
    remaining_D = squareform(D);
    % remaining_D is now phones-by-phones
    remaining_D = remaining_D(remaining_phones, remaining_phones);
    remaining_D = squareform(remaining_D);
    n_entries_remaining = numel(remaining_D);

    remaining_feature_cat_rdms = nan(n_remaining_features, n_entries_remaining);
    for feature_i = 1:n_remaining_features
        remaining_rdm = squareform(feature_cat_rdms(remaining_features(feature_i), :));
        remaining_rdm = remaining_rdm(remaining_phones, remaining_phones);
        remaining_feature_cat_rdms(feature_i, :) = squareform(remaining_rdm);
    end

    %% Fit the reduced matrices

    % For each remaining feature, we try to fit it with the actual
    % arragement of the remaining phone models.
    fit_of_features = nan(n_remaining_features, 1);
    for feature_i = 1:n_remaining_features
        feature_cat_rdm = remaining_feature_cat_rdms(feature_i, :);

        if(all(feature_cat_rdm == 0))
            % If we find that the feature doesn't at all separate the phones, 
            % we say that it doesn't fit at all.
            fit_of_features(feature_i) = -inf;
        else
            % Otherwise we match the fit using tau_a
            fit_of_features(feature_i) = rsa.stat.rankCorr_Kendall_taua( ...
                remaining_D, ...
                feature_cat_rdm);
        end
    end
    
    % When we've looked at all the features, we pick the one which is best.
    [max_fit, best_feature_i] = max(fit_of_features);

    % If the one which is best is actually no good at all, we stop branching here.
    if max_fit <= 0
        branching = remaining_phones;
        return;
    end
    
    % best_feature_i is the index of the best feature in the current list
    % best_feature   is the index of the best feature in the main list

    best_feature = remaining_features(best_feature_i);
    
    % Now we split the current list of phones by whether or not the have this feature

    all_phones_w_feature = find(M(best_feature, :));
    phones_w_feature = intersect(all_phones_w_feature, remaining_phones);


    all_phones_wo_feature = find(1-M(best_feature, :));
    phones_wo_feature = intersect(all_phones_wo_feature, remaining_phones);
    
    % The we recursively sub-cluster the remaining phones with the remaining features
    diminished_feature_list = remaining_features(remaining_features ~= best_feature);

    phones_w_feature = hierarchically_classify_features(diminished_feature_list, phones_w_feature, feature_cat_rdms, D, M);
    phones_wo_feature = hierarchically_classify_features(diminished_feature_list, phones_wo_feature, feature_cat_rdms, D, M);

    branching = {best_feature, phones_w_feature, phones_wo_feature};

end
