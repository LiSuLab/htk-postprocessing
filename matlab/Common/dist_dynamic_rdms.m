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
