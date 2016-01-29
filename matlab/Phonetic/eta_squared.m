% Expects RDMs to be in the workspace.
% Run CalculateAndShowPhoneRDMs.m first.
function etasquareds = eta_squared

    FEATURES = phonetic_feature_matrix_GMM();

    feature_names = fields(FEATURES);

    n_features = numel(feature_names);

    RDMs = phonetic_model_RDMs;
    [n_timepoints, n_models] = size(RDMs);

    skip_frames = 4;

    % vectorise RDMs ahead of time
    for t = 1:n_timepoints
        for m = 1:n_models
            phonetic_model_RDMs(t, m).RDM = squareform(RDMs(t, m).RDM)';
        end
    end

    n_timepoints = n_timepoints - skip_frames;

    etasquareds = nan(n_features, n_timepoints);

    parfor t = 1:n_timepoints

        rsa.util.prints('Timepoint %d of %d...', t, n_timepoints);

        for feature_i = 1:n_features

            feature_name = feature_names{feature_i};

            rsa.util.prints('\tFeature %d of %d...', feature_i, n_features);

            % For each feature we'll consider the between-feat/nonfeat distances
            % and the within feat/nonfeat distances.

            feature_profile = FEATURES.(feature_name);

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
                       phonetic_model_RDMs(t+skip_frames, model_i).RDM, ...
                       phonetic_model_RDMs(t+skip_frames, model_j).RDM, ...
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
                       phonetic_model_RDMs(t+skip_frames, model_i).RDM, ...
                       phonetic_model_RDMs(t+skip_frames, model_j).RDM, ...
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
                       phonetic_model_RDMs(t+skip_frames, model_i).RDM, ...
                       phonetic_model_RDMs(t+skip_frames, model_j).RDM, ...
                       'type', 'Spearman');
                   between_distances = [between_distances; d_ij];
               end
            end

            ss_within = sum(within_distances .^2);
            ss_between = sum(between_distances .^2);
            ss_total = ss_within + ss_between;

            if ss_total ~= 0
                etasquareds(feature_i, t) = ss_between/ss_total;
            end

        end%for:feature_i

    end%for:t

    rsa.util.prints('Done!');

end

