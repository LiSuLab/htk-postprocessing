function [dCM, aCM] = compare_dRDMs(correlation_type)

    if ~exist('correlation_type', 'var'), correlation_type = 'Spearman'; end

    phon_RDMs = phone_dRDM();    % 1
    feat_RDMs = feature_dRDM();  % 2
    trip_RDMs = triphone_dRDM(); % 3
    bn26_RDMs = bn26_dRDM();     % 4
    
    % should be the same for all four
    n_frames = numel(bn26_RDMs);
    data_size = numel(bn26_RDMs(1).RDM);
    n_RDMs = n_frames * 4;
    
    data_overall = nan(n_RDMs, data_size);
    
    for t = 1:n_frames
        
        % dCM
        data_this_frame = [ ...
            phon_RDMs(t).RDM; ...
            feat_RDMs(t).RDM; ...
            trip_RDMs(t).RDM; ...
            bn26_RDMs(t).RDM];
        
        data_overall(t + (0 * n_frames), :) = phon_RDMs(t).RDM;
        data_overall(t + (1 * n_frames), :) = feat_RDMs(t).RDM;
        data_overall(t + (2 * n_frames), :) = trip_RDMs(t).RDM;
        data_overall(t + (3 * n_frames), :) = bn26_RDMs(t).RDM;
        
        dCM(t).CM = corr( ...
            data_this_frame', ...
            'type', correlation_type);
        
    end
    
    aCM = corr( ...
        data_overall', ...
        'type', correlation_type);
    
end
