% Expects phonetic_model_RDMs to be in the workspace.
% Run CalculateAndShowPhoneRDMs.m first.

[M, PHONES, FEATURES] = phonetic_feature_matrix();

[n_features, n_phones] = size(M);

[n_timepoints, n_models] = size(phonetic_model_RDMs);

% vectorise RDMs ahead of time
for t = 1:n_timepoints
    for m = 1:n_models
        phonetic_model_RDMs(t, m).RDM = squareform(phonetic_model_RDMs(t, m).RDM)';
    end
end

etasquared_s = nan(n_timepoints, 1);

for t = 1:n_timepoints
    
    rsa.util.prints('Timepoint %d of %d...', t, n_timepoints);

    for feature_i = 1:n_features
    
        rsa.util.prints('\tFeature %d of %d...', feature_i, n_features);
        
        % For each feature we'll consider the between-feat/nonfeat distances
        % and the within feat/nonfeat distances.

        feature_profile = squeeze(M(feature_i, :));
        nonfeature_profile = 1 - feature_profile;

        within_distances = [];
        between_distances = [];
        
        models_with_feature = find(feature_profile);
        models_without_feature = find(1-feature_profile);

        % within feat
        for model_i_i = 1 : numel(models_with_feature) - 1
            model_i = models_with_feature(model_i_i);
           for  model_j_i = model_i_i + 1 : numel(models_with_feature)
               model_j = models_with_feature(model_j_i);
               % distance between model i and model j
               d_ij = 1 - corr( ...
                   phonetic_model_RDMs(t, model_i).RDM, ...
                   phonetic_model_RDMs(t, model_j).RDM, ...
                   'type', 'Spearman');
               within_distances = [within_distances; d_ij];
           end
        end
        
        % within nonfeat
        for model_i_i = 1 : numel(models_without_feature) - 1
            model_i = models_without_feature(model_i_i);
           for  model_j_i = model_i_i + 1 : numel(models_without_feature)
               model_j = models_without_feature(model_j_i);
               % distance between model i and model j
               d_ij = 1 - corr( ...
                   phonetic_model_RDMs(t, model_i).RDM, ...
                   phonetic_model_RDMs(t, model_j).RDM, ...
                   'type', 'Spearman');
               within_distances = [within_distances; d_ij];
           end
        end
        
        % between feat/nonfeat
        for model_i_i = 1 : numel(models_with_feature)
            model_i = models_with_feature(model_i_i);
           for  model_j_i = 1 : numel(models_without_feature)
               model_j = models_without_feature(model_j_i);
               % distance between model i and model j
               d_ij = 1 - corr( ...
                   phonetic_model_RDMs(t, model_i).RDM, ...
                   phonetic_model_RDMs(t, model_j).RDM, ...
                   'type', 'Spearman');
               between_distances = [between_distances; d_ij];
           end
        end
        
        ss_within = sum(within_distances .^2);
        ss_between = sum(between_distances .^2);
        ss_total = ss_within + ss_between;
        
        if ss_total ~= 0
            etasquared_s(t) = ss_between/ss_total;
        end

    end

end
