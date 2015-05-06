% Clusters phone models.
%
% CW 2015-05
function ClusterPhoneModels(cluster_distance_threshold, aggregation, correlation_type)

    %% Constants
    
    MAX_ITER = 20;

    %% Paths

    % Change these values
    input_dir  = fullfile('/', 'Users', 'cai', 'Desktop', '42-phone-models');
    output_dir = fullfile('/', 'Users', 'cai', 'Desktop', 'clustered-phone-models');

    rsa.util.gotoDir(output_dir);


    %% Load RDMs
    
    rsa.util.prints('Loading RDMs...');

    rdms = rsa.util.directLoad(fullfile(input_dir, 'RDMs.mat'));
    
    phone_list = { rdms(1, :).phone };
    
    [n_timepoints, n_models] = size(rdms);
    
    % Put RDMs in ltcv form.
    parfor m = 1:n_models
        for t = 1:n_timepoints
            rdms(t, m).RDM = rsa.rdm.vectorizeRDM(rdms(t, m).RDM)';
        end
    end
    
    
    %% Prepare list of clusters
    
    rsa.util.prints('Preparing initial cluster list...');
    
    parfor model_i = 1:n_models
        % The list of models in this cluster
        clusters(model_i).contents = [ model_i ];
        % Whether this cluster is still alive
        clusters(model_i).alive = true;
    end%for
    
    % There is now a singleton cluster for each model
    
    
    %% %% Iteration loop
    
    rsa.util.prints('Performing hierarchical agglomerative clustering on dynamic model RDMs...');
    
    % Metrics
    min_cluster_dist = inf;
    iteration_count = 0;
    
    while true
        
        iteration_count = iteration_count + 1;
    
        %% Find closest pair of clusters
        cluster_pair = [nan, nan];
        for cluster_1 = 1:numel(clusters)-1
            for cluster_2 = cluster_1+1:numel(clusters)
                
                cluster_1_rdms = cluster_centroid(rdms(:, clusters(cluster_1).contents));
                cluster_2_rdms = cluster_centroid(rdms(:, clusters(cluster_2).contents));
                
                dist_1_2 = 1 - correlate_dynamic_rdms( ...
                    cluster_1_rdms, ...
                    cluster_2_rdms);%, ...
                    %'aggregate', aggregation, ...
                    %'correlationtype', correlation_type);
                
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
    rsa.util.prints('Minimum distance between clusters is %f', min_cluster_dist);
    
    rsa.util.prints();
    
    % Name and display clusters
    cluster_names = cell(numel(clusters), 1);
    for cluster_i = 1:numel(clusters)
        cluster = clusters(cluster_i).contents;
        phones = phone_list(cluster);
        cluster_names{cluster_i} = array2string(phones);
        rsa.util.prints('Cluster %d: %s', cluster_i, cluster_names{cluster_i});
    end
    
    
    %% Combine clusters into representative models
    
    % Preallocate
    cluster_centroid_rdms(1:n_timepoints, 1:numel(clusters)) = struct('RDM', nan, 'name', nan);
    
    for cluster_i = 1:numel(clusters)
        cluster_centroid_rdms(:, cluster_i).RDM = cluster_centroid(rdms(:, clusters(cluster_i).contents));
        cluster_centroid_rdms(:, cluster_i).name = cluster_names{cluster_i};
    end%for

    
    %% Save results
    
    rsa.util.prints('Saving results...');
    
    % TODO
    chdir(output_dir);
    save('cluster_centroid_rdms', 'cluster_centroid_rdms', '-v7.3');
    
end%function


% Returns the cluster centroid for a cluster of dymanic RDMs (ltv, column).
%
% CW 2015-05
function centroid_rdms = cluster_centroid(rdms)
    [n_timepoints, n_items] = size(rdms);
    parfor t = 1:n_timepoints
        centroid_rdms(t, 1).RDM = mean([rdms(t, :).RDM], 2);
    end
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
    defaultCorrelationType = 'Pearson';%'Spearman';

    ip = inputParser;
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
        rsa.util.errors('Dynamic RDM ranges must be of the same length.');
    end
    
    list_of_values = nan(dynamic_length, 1);
    
    parfor rdm_i = 1:dynamic_length
        rdm_a = rsa.rdm.vectorizeRDM(rdms_a(rdm_i).RDM)';
        rdm_b = rsa.rdm.vectorizeRDM(rdms_b(rdm_i).RDM)';
        
        % hack
        if all(rdm_a == 0) && all(rdm_b == 0)
            list_of_values(rdm_i) = 0;
        elseif strcmpi(correlation_type, 'Kendalltaua')
            list_of_values(rdm_i) = rsa.stat.rankCorr_Kendall_taua(rdm_a, rdm_b);
        else
            list_of_values(rdm_i) = corr(rdm_a', rdm_b', 'type', correlation_type);
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
           s = [s, sprintf('%d',a)]; 
       else
           s = [s, sprintf('%d',a), ', '];
       end
    end
    s = [s, ']'];
end%function
