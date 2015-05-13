% CW 2015-05
function GroupPhoneRDMsByLabel()

    % We're ignoring these ones for lack of data.
    %phones.OUTLIERS = { ...
    %    'dh', 'ua', 'ax', 'zh', };
    PHONES.FRICATIVES = { ...
        'sh', 'z',  's',  'th', 'v',  'f',  'hh', 'jh', 'ch' };
    PHONES.PLOSIVES = { ...
        'b',  'p',  'd',  't',  'g',  'k'  };
    PHONES.NASALS = { ...
        'm',  'n',  'ng' };
    PHONES.RESONANTS_CLOSED = { ...
        'uh', 'uw', 'ia', 'ih', 'iy', 'ay' };
    PHONES.RESONANTS_MID = { ...
        'y',  'l',  'r',  'w',  'ea', 'eh', 'er', 'ey',  'ah', 'ao', 'aw' };
    PHONES.RESONANSTS_OPEN = { ...
        'oh', 'ow', 'oy', 'aa', 'ae' };

    category_labels = fields(PHONES);
    

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
    n_values_in_rdm = numel(squareform(rsa.rdm.vectorizeRDM(rdms(1).RDM)));
    
    %%
    
    category_average_rdms(1:n_timepoints, 1:numel(category_labels)) = struct('RDM', nan, 'name', nan);
    
    for category_label_i = 1:numel(category_labels)
        category_label = category_labels{category_label_i};
        
        rsa.util.prints('Averaging RDMs in the "%s" category...', category_label);

        model_labels_this_category = PHONES.(category_label);

        n_models_this_category = numel(model_labels_this_category);

        rdms_this_category = nan( ...
           n_timepoints, ...
           n_values_in_rdm, ...
           n_models_this_category);

        for model_label_i = 1:numel(model_labels_this_category)
           model_label = model_labels_this_category{model_label_i};

           % Find the index of this condition in the original RDM
           % structure.
           model_i = ismember({rdms(1, :).phone}, model_label);

           for t = 1:n_timepoints
               rdms_this_category(t, :, model_label_i) = rsa.rdm.vectorizeRDM(rdms(t, model_i).RDM);
           end
        end
        
        average_rdms = squeeze(mean(rdms_this_category, 3));
        
        for t = 1:n_timepoints
            category_averaged_rdms(t, category_label_i).RDM = squeeze(average_rdms(t, :));
            category_average_rdms(t, category_label_i).name = category_label;
        end
    end
    
    rsa.util.prints('Saving results...');
    
    save(fullfile(output_dir, 'average_RDMs'), 'category_averaged_rdms', '-v7.3');
    
end%function
