function branching = generate_optimal_hierarchy()

    import rsa.*
    import rsa.rdm.*
    import rsa.util.*

    %% Phone-feature matrix
    M = [ ...
        ...%  AA AE AH AO AW AY B  CH D  EA EH ER EY F  G  HH IA IH IY JH K  L  M  N  NG OH OW OY P  R  S  SH T  TH UH UW V  W  Y  Z  
        ...% DORSAL
            [ 0  0  0  0  0  0  0  0  0  0  0  0  0  0  1  0  0  0  0  0  1  0  0  0  1  0  0  0  0  0  0  1  0  0  0  0  0  0  0  0 ]; ...
        ...% CORONAL
            [ 0  0  0  0  0  0  0  0  1  0  0  0  0  0  0  0  0  0  0  0  0  0  0  1  0  0  0  0  0  0  1  0  1  0  0  0  0  0  0  1 ]; ...
        ...% LABIAL
            [ 0  0  0  0  0  0  1  0  0  0  0  0  0  1  0  0  0  0  0  0  0  0  1  0  0  0  0  0  1  0  0  0  0  0  0  0  1  0  0  0 ]; ...
        ...% HIGH
            [ 0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  1  1  1  0  0  0  0  0  0  0  0  1  0  0  0  0  0  0  0  1  0  0  0  0 ]; ...
        ...% FRONT
            [ 0  1  0  0  0  0  0  0  0  1  1  0  0  0  0  0  1  1  1  0  0  0  0  0  0  0  0  1  0  0  0  0  0  0  0  0  0  0  0  0 ]; ...
        ...% LOW
            [ 1  1  1  1  0  0  0  0  0  1  1  0  0  0  0  0  0  0  0  0  0  0  0  0  0  1  0  1  0  0  0  0  0  0  0  0  0  0  0  0 ]; ...
        ...% BACK
            [ 1  0  1  1  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  1  0  1  0  0  0  0  0  0  0  1  0  0  0  0 ]; ...
        ...% PLOSIVE
            [ 0  0  0  0  0  0  1  0  1  0  0  0  0  0  1  0  0  0  0  0  1  0  0  0  0  0  0  0  1  0  0  0  1  0  0  0  0  0  0  0 ]; ...
        ...% FRICATIVE
            [ 0  0  0  0  0  0  0  1  0  0  0  0  0  1  0  1  0  0  0  0  0  0  0  0  0  0  0  0  0  0  1  1  0  1  0  0  1  0  0  1 ]; ...
        ...% NASAL
            [ 0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  1  1  1  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0 ]; ...
        ...% VOICED
            [ 1  1  1  1  1  1  1  0  1  1  1  1  1  0  1  0  1  1  1  1  0  1  1  1  1  1  1  1  0  1  0  0  0  0  1  1  1  1  1  1 ]; ...
        ...% OBSTRUENT
            [ 0  0  0  0  0  0  1  1  1  0  0  0  0  1  1  1  0  0  0  1  1  1  1  1  1  0  0  0  1  1  1  1  1  1  0  0  1  1  0  1 ]; ...
        ...% SONORANT
            [ 1  1  1  1  1  1  0  0  0  1  1  1  1  0  0  0  1  1  1  0  0  1  0  0  0  1  1  1  0  1  0  0  0  0  1  1  0  0  1  0 ]];
    
    PHONES{1}  = 'AA';
    PHONES{2}  = 'AE';
    PHONES{3}  = 'AH';
    PHONES{4}  = 'AO';
    PHONES{5}  = 'AW';
    PHONES{6}  = 'AY';
    PHONES{7}  = 'B';
    PHONES{8}  = 'CH';
    PHONES{9}  = 'D';
    PHONES{10} = 'EA';
    PHONES{11} = 'EH';
    PHONES{12} = 'ER';
    PHONES{13} = 'EY';
    PHONES{14} = 'F';
    PHONES{15} = 'G';
    PHONES{16} = 'HH';
    PHONES{17} = 'IA';
    PHONES{18} = 'IH';
    PHONES{19} = 'IY';
    PHONES{20} = 'JH';
    PHONES{21} = 'K';
    PHONES{22} = 'L';
    PHONES{23} = 'M';
    PHONES{24} = 'N';
    PHONES{25} = 'NG';
    PHONES{26} = 'OH';
    PHONES{27} = 'OW';
    PHONES{28} = 'OY';
    PHONES{29} = 'P';
    PHONES{30} = 'R';
    PHONES{31} = 'S';
    PHONES{32} = 'SH';
    PHONES{33} = 'T';
    PHONES{34} = 'TH';
    PHONES{35} = 'UH';
    PHONES{36} = 'UW';
    PHONES{37} = 'V';
    PHONES{38} = 'W';
    PHONES{39} = 'Y';
    PHONES{40} = 'Z';

    FEATURES{1}  = 'DORSAL';
    FEATURES{2}  = 'CORONAL';
    FEATURES{3}  = 'LABIAL';
    FEATURES{4}  = 'HIGH';
    FEATURES{5}  = 'FRONT';
    FEATURES{6}  = 'LOW';
    FEATURES{7}  = 'BACK';
    FEATURES{8}  = 'PLOSIVE';
    FEATURES{9}  = 'FRICATIVE';
    FEATURES{10} = 'NASAL';
    FEATURES{11} = 'VOICED';
    FEATURES{12} = 'OBSTRUENT';
    FEATURES{13} = 'SONORANT';
    
    
    %% Paths

    input_dir  = '/imaging/cw04/analyses/Lexpro/Phonotopic_mapping/Phonetic_models/pruning-100';
    output_dir = '/home/cw04/Desktop/hierarchical-models/';
    
    
    %% Load models
    
    rsa.util.prints('Loading RDMs...');
    all_rdms = rsa.util.directLoad(fullfile(input_dir, 'RDMs.mat'));
    
    n_timepoints = size(all_rdms, 1);
    
    n_entries = numel(rsa.rdm.vectorizeRDM(all_rdms(1, 1).RDM));
    
    n_phones  = numel(PHONES);
    n_features = numel(FEATURES);
    
    % Remove the outliers
    rdms(1:n_timepoints, n_phones) = struct('name', nan, 'RDM', nan, 'phone', nan);
    for phone_i = 1:n_phones
       % find the all_rdms-index for this phone
       this_phone = PHONES{phone_i};
       rdm_i = find(ismember({ all_rdms(1, :).phone }, lower(this_phone)));
       rdms(:, phone_i) = all_rdms(:, rdm_i);
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
        chdir(output_dir);
        save('hierarchy_D', D, '-v7.3');
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



% Given a binary vector representing the presence of absence of a
% particular feature for each condition, this function returns a model RDM
% based on that condition.
%
% CW 2015-05
function rdm = binary_categorical_rdm(v)

    n_conditions = numel(v);
    
    rdm = zeros(n_conditions, n_conditions);
    for condition_1 = 1:n_conditions-1
        for condition_2 = condition_1+2:n_conditions
            rdm(condition_2, condition_1) = (v(condition_1) ~= v(condition_2));
        end
    end
    
    rdm = squareform(rdm);

end%function


