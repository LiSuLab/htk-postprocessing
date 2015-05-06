function CluserPhoneModels()

    %% Paths

    % Change these values
    input_dir = fullfile('/Users', 'cai', 'Desktop', 'matlab-out', '100');
    output_dir = fullfile('/Users', 'cai', 'Desktop', 'clustered-phone-models', '100');

    toolbox_path = fullfile('/Volumes/Cai''s MBP HDD/Documents/Code/Neurolex/rsagroup-rsatoolbox');

    addpath(genpath(toolbox_path));

    rsa.util.gotoDir(output_dir);


    %% Load RDMs

    rdms = rsa.util.directLoad(fullfile(input_dir, 'rdms.mat'));

    phone_list = { rdms(1, :).phone };
    
    
    %% %% Iteration loop
    
    %% Find closest pair of clusters
    
    %% If closest pair are far enough away then stop
    
    %% Average together pair of clusters
    
    %% Concatenate list of phones in cluster list
    
    %% Renumber clusters
    
    %% Print current state


end%function





% Returns the average correlation of two dynamic RDMs
%
% CW 2015-05
function c = correlate_dynamic_rdms(rdms_a, rdms_b, varargin)
    
    %% Parse inputs
    
    nameAggregate    = 'aggregate';
    validAggregate   = {'mean', 'median', 'max', 'min'};
    checkAggregate   = @(x) (any(validatestring(x, validAggregate)));
    defaultAggregate = 'mean';
    
    nameCorrelationType    = 'correlationtype';
    validCorrelationType   = {'Pearson', 'Spearman', 'Kendalltaua'};
    checkCorrelationType   = @(x) (any(validatestring(x, validCorrelationType)));
    defaultCorrelationType = 'Spearman';

    ip = InputParser;
    ip.CaseSensitive = false;
    ip.StructExpand  = false;
    
    addParameter(ip, nameAggregate,       defaultAggregate,       checkAggregate);
    addParameter(ip, nameCorrelationType, defaultCorrelationType, checkCorrelationType);
    
    parse(ip, varargin{:});
    
    aggregation      = ip.Results.(nameAggregate);
    correlation_type = ip.Results.(nameCorrelationType);
    
    %% Constants
    dynamic_length = numel(rdms_a);
    
    %% Validate input
    if numel(rdms_b) ~= dynamic_length
        rsa.util.errors('Dynamic rdm ranges must be of the same length.');
    end
    
    list_of_values = nan(dynamic_length, 1);
    
    for rdm_i = 1:dynamic_length
        rdm_a = rsa.rdm.vectorizerdm(rdms_a(rdm_i).rdm);
        rdm_b = rsa.rdm.vectorizerdm(rdms_b(rdm_i).rdm);
        
        if strcmpi(correlation_type, 'Kendalltaua')
            list_of_values(rdm_i) = rsa.stat.rankCorr_Kendall_taua(rdm_a, rdm_b);
        else
            list_of_values(rdm_i) = corr(rdm_a, rdm_b, 'type', correlation_type);
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
