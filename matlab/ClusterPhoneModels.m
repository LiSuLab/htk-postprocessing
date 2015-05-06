% Clusters phone models.
%
% CW 2015-05
function ClusterPhoneModels(cluster_distance_threshold, aggregation, correlation_type)

    %% Constants
    
    MAX_ITER = 1000;

    %% Paths

    % Change these values
    input_dir  = fullfile('/', 'Users', 'cai', 'Desktop', '42-phone-models');
    output_dir = fullfile('/', 'Users', 'cai', 'Desktop', 'clustered-phone-models');

    rsa.util.gotoDir(output_dir);


    %% Load RDMs

    rdms = rsa.util.directLoad(fullfile(input_dir, 'rdms.mat'));
    
    phone_list = { rdms(1, :).phone };
    
    [n_timepoints, n_models] = size(rdms);
    
    % Put RDMs in ltcv form.
    for m = 1:n_models
        for t = 1:n_timepoints
            rdms(t, m).RDM = rsa.rdm.vectorizeRDM(rdms(t, m).RDM)';
        end
    end
    
    
    %% Prepare list of clusters
    
    for model_i = 1:n_models
        % The list of models in this cluster
        clusters(model_i).contents = [ model_i ];
        % Whether this cluster is still alive
        clusters(model_i).alive = true;
    end%for
    
    % There is now a singleton cluster for each model
    
    
    %% %% Iteration loop
    
    % Metrics
    min_cluster_dist = inf;
    iteration_count = 0;
    
    while true
        
        iteration_count = iteration_count + 1;
    
        %% Find closest pair of clusters
        cluster_pair = [nan, nan];
        for cluster_1 = 1:numel(clusters)
            for cluster_2 = cluster_1+1:numel(clusters)
                dist_1_2 = 1 - correlate_dynamic_rdms( ...
                    cluster_centroid(rdms(clusters(cluster_1).contents)), ...
                    cluster_centroid(rdms(clusters(cluster_2).contents)), ...
                    'aggregate', aggregation, ...
                    'correlationtype', correlation_type);
                if dist_1_2 < min_cluster_dist
                    min_cluster_dist = dist_1_2;
                    cluster_pair = [cluster_1, cluster_2];
                end
            end
        end
        
        
        %% If closest pair are far enough away, or we've been going on too long then stop
        if min_cluster_dist < cluster_distance_threshold ...
                && iteration_count < MAX_ITER ...
                && numel(clusters) <= 3
            break;
        end
        

        %% Combine clusters
        
        % Add cluster 2 to cluster 1
        clusters(cluster_pair(1)).contents = [ ...
            clusters(cluster_pair(1)).contents, ...
            clusters(cluster_pair(2)).contents ];
        
        % Delete cluster 2
        clusters(cluster_pair(1)).alive = false;

        %% Renumber clusters
        clusters = renumber_clusters(clusters);

        %% Print current state
        rsa.util.prints('Iteration %d: \t %d clusters.', iteration_count, numel(clusters));
        for i = 1:numel(clusters)
            rsa.util.prints('\tCluster %d: %s', i, array2string(clusters(i).contents));
        end
        % Newline
        rsa.util.prints();
    
    end%while
    
    
    %% Display results
    
    rsa.util.prints('Completed after %d iterations.', iteration_count);
    rsa.util.prints('%d clusters remain.', numel(clusters));
    
    rsa.util.prints();
    
    % Print out clusters
    for cluster_i = 1:numel(clusters)
        cluster = clusters(cluster_i).contents;
        phones = phone_list(cluster);
        rsa.util.prints('Cluster %d: %s', cluster_i, array2string(phones));
    end
    
    
    %% Combine clusters into representative models
    for cluster_i = 1:numel(clusters)
        
    end%for

    
    %% Save results
    
    rsa.util.prints('Saving results...');
    
    % TODO
    
    

end%function


% Returns the cluster centroid for a cluster of dymanic RDMs (ltv, column).
%
% CW 2015-05
function centroid = cluster_centroid(rdms)
    centroid = mean([rdms.RDM], 2);
end%function


% Renumbers a list of clusters.
%
% CW 2015-05
function clusters_out = renumber_clusters(clusters_in)
    clusters_out = clusters_in([clusters_in.alive]);
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
        rdm_a = rsa.rdm.vectorizerdm(rdms_a(rdm_i).rdm)';
        rdm_b = rsa.rdm.vectorizerdm(rdms_b(rdm_i).rdm)';
        
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

% String representation of a 1-d array.
%
% CW 2015-05
function s = array2string(a)
    s = '[';
    for i = 1:numel(a)
       if i == 1
           s = [s, a]; 
       else
           s = [s, a, ', '];
       end
    end
    s = [s, ']'];
end%function
