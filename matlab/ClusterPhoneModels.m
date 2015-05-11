% Clusters phone models.
%
% CW 2015-05
function ClusterPhoneModels()

    %% Category colours
    CATEGORY_COLOURS = [ ...
        0 0 0; ... % 1 outlier
        1 0 0; ... % 2 nasals
        0 1 1; ... % 3 plosives
        1 0 1; ... % 4 fricatives
        0 0 1; ... % 5 resonants
        0 1 0; ... % 6 high resonants
        1 1 0; ... % 7 low resonants
        ];
    
    %% Labels
    LABELS = { ...
        'aa', 7; ...
        'ae', 7; ...
        'ah', 7; ...
        'ao', 7; ...
        'aw', 7; ...
        'ay', 5; ...
        'b',  3; ...
        'ch', 4; ...
        'd',  3; ...
        'dh', 1; ...
        'ea', 7; ...
        'eh', 7; ...
        'er', 5; ...
        'ey', 6; ...
        'f',  4; ...
        'g',  3; ...
        'hh', 4;...
        'ia', 6; ...
        'ih', 6; ...
        'iy', 6; ...
        'jh', 4; ...
        'k',  3; ...
        'l',  5;...
        'm',  2; ...
        'n',  2; ...
        'ng', 1; ...
        'oh', 7; ...
        'ow', 7; ...
        'oy', 7;...
        'p',  3; ...
        'r',  5; ...
        's',  4; ...
        'sh', 4; ...
        't',  3; ...
        'th', 4; ...
        'ua', 1; ...
        'uh', 5; ...
        'uw', 6; ...
        'v',  4; ...
        'w',  5; ...
        'y',  5; ...
        'z',  4; ...
        };

    %% Paths

    % Change these values
    input_dir  = '/imaging/cw04/analyses/Lexpro/Phonotopic_mapping/Phonetic_models/pruning-100';
    output_dir = '/home/cw04/Desktop/clustered-models';

    rsa.util.gotoDir(output_dir);

    %% Load RDMs
    
    rsa.util.prints('Loading RDMs...');

    rdms = rsa.util.directLoad(fullfile(input_dir, 'RDMs.mat'));
    
    phone_list = { rdms(1, :).phone };
    
    [n_timepoints, n_models] = size(rdms);
    
    
    %% Put in model x all-data form
    
    rsa.util.prints('Collecting all model data together...');
    
    all_model_data = nan( ...
        n_models, ...
        n_timepoints, ...
        numel( rsa.rdm.vectorizeRDM(rdms(1,1).RDM)));
    
    for m = 1:n_models
        for t = 1:n_timepoints
            all_model_data(m, t, :) = rsa.rdm.vectorizeRDM(rdms(t, m).RDM);
        end
    end
    
    
    %% Calculating distance matrix
    
    rsa.util.prints('Calculating distance matrix...');
    
    D = zeros(n_models, n_models);
    for model_1 = 1:n_models-1
        rsa.util.prints('Distances from model %d...', model_1);
        D_slice = zeros(n_models, 1);
        for model_2 = model_1+1:n_models
            d = dist_dynamic_rdms( ...
                squeeze(all_model_data(model_1, :, :)), ...
                squeeze(all_model_data(model_2, :, :)), ...
                'aggregate', 'mean', ...
                'disttype', 'Spearman');
            D_slice(model_2) = d;
        end
        D(:, model_1) = D_slice(:);
    end
    
    D = squareform(D);
    
    
    %% Perform clustering
    
    rsa.util.prints('Clustering dynamic RDM models...');
    
    clustering_method = 'average';
    Z = linkage(D, clustering_method);
    
    
    %% Display results
    
    [H, T, cond_perm] = dendrogram(Z, ...
        numel(LABELS), ...
        'Orientation', 'right', ...
        'ColorThreshold', 0.4, ...
        'labels', phone_list);
    set(H, 'LineWidth', 2);
    % don't know why this isn't working...
    %add_category_colours_to_dendrogram(cond_perm, [LABELS{:, 2}], CATEGORY_COLOURS);
    
end%function


% Returns the average correlation of two dynamic RDMs
%
% CW 2015-05
function c = dist_dynamic_rdms(rdms_a, rdms_b, varargin)
    
    %% Parse inputs
    
    nameAggregate    = 'aggregate';
    validAggregate   = {'mean', 'median', 'max', 'min'};
    checkAggregate   = @(x) (any(validatestring(x, validAggregate)));
    defaultAggregate = 'mean';
    
    nameDistType    = 'disttype';
    validDistType   = {'Pearson', 'Spearman', 'Kendalltaua', 'Euclidean'};
    checkDistType   = @(x) (any(validatestring(x, validDistType)));
    defaultDistType = 'Spearman';

    ip = inputParser;
    ip.CaseSensitive = false;
    ip.StructExpand  = false;
    
    addParameter(ip, nameAggregate,       defaultAggregate,       checkAggregate);
    addParameter(ip, nameDistType, defaultDistType, checkDistType);
    
    parse(ip, varargin{:});
    
    aggregation      = ip.Results.(nameAggregate);
    dist_type = ip.Results.(nameDistType);
    
    %% Constants
    [dynamic_length, model_size] = size(rdms_a);
    
    list_of_values = nan(dynamic_length, 1);
    
    for rdm_i = 1:dynamic_length
        rdm_a = squeeze(rdms_a(rdm_i, :))';
        rdm_b = squeeze(rdms_b(rdm_i, :))';
        
        % hack
        if all(rdm_a == 0) || all(rdm_b == 0)
            list_of_values(rdm_i) = 0;
        elseif strcmpi(dist_type, 'Euclidean')
            list_of_values(rdm_i) = sqrt(sum((rdm_a - rdm_b) .^ 2));
        elseif strcmpi(dist_type, 'Kendalltaua')
            list_of_values(rdm_i) = 1 - rsa.stat.rankCorr_Kendall_taua(rdm_a, rdm_b);
        else
            list_of_values(rdm_i) = 1 - corr(rdm_a, rdm_b, 'type', dist_type);
        end
        
    end%for
    
    if strcmpi(aggregation, 'mean')
        c = mean(list_of_values);
    elseif strcmpi(aggregation, 'median')
        c = median(list_of_values);
    elseif strcmpi(aggregation, 'min')
        c = min(list_of_values);
    elseif strcmpi(aggregation, 'max')
        c = max(list_of_values);
    end
    
end%function
