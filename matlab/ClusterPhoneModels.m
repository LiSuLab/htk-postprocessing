% Clusters phone models.
%
% CW 2015-05
function ClusterPhoneModels()

    %% Constants
    
    MAX_ITER = 20;

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
    
    for m = 1:n_models
        for t = 1:n_timepoints
            rdms(t, m).RDM = rsa.rdm.vectorizeRDM(rdms(t, m).RDM);
        end
    end
    
    all_model_data = nan( ...
        n_models, ...
        n_timepoints * numel(rdms(1,1).RDM));
    for m = 1:n_models
        all_model_data(m, :) = [ rdms(:, m).RDM ];
    end
    
    
    %% Perform clustering
    
    rsa.util.prints('Clustering dynamic RDM models...');
    
    clustering_method = 'single';
    clustering_metric = 'correlation';
    Z = linkage(all_model_data, clustering_method, clustering_metric);
    
    
    %% Display results
    
    dendrogram(Z);
    
end%function
