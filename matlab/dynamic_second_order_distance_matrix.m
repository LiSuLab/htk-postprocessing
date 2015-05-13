% CW 2015-05
function D = dynamic_second_order_distance_matrix(all_model_data, aggregate, disttype)

    [n_models, n_timepoints, n_rdm_entries] = size(all_model_data);

    D = zeros(n_models, n_models);
    
    for model_1 = 1:n_models-1
        rsa.util.prints('Distances from model %d...', model_1);
        D_slice = zeros(n_models, 1);
        for model_2 = model_1+1:n_models
            d = dist_dynamic_rdms( ...
                squeeze(all_model_data(model_1, :, :)), ...
                squeeze(all_model_data(model_2, :, :)), ...
                'aggregate', aggregate, ...
                'disttype', disttype);
            D_slice(model_2) = d;
        end
        D(:, model_1) = D_slice(:);
    end
    
    D = squareform(D);

end%function
