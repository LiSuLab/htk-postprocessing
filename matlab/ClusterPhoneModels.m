function CluserPhoneModels()

    %% Paths

    % Change these values
    input_dir = fullfile('/Users', 'cai', 'Desktop', 'matlab-out', '100');
    output_dir = fullfile('/Users', 'cai', 'Desktop', 'clustered-phone-models', '100');

    toolbox_path = fullfile('/Volumes/Cai''s MBP HDD/Documents/Code/Neurolex/rsagroup-rsatoolbox');

    addpath(genpath(toolbox_path));

    rsa.util.gotoDir(output_dir);


    %% Load RDMs

    RDMs = rsa.util.directLoad(fullfile(input_dir, 'RDMs.mat'));

    phone_list = { RDMs(1, :).phone };
    
    
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
function correlate_dynamic_RDMs(RDMs_a, RDMs_b, varargin)
    
end%function
