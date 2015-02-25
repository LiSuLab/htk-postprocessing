clear;
close all;

%% Paths

% Change these values
input_dir = fullfile('/Users', 'cai', 'Desktop', 'mat-files', '100');
output_dir = fullfile('/Users', 'cai', 'Desktop', 'matlab-out', '100');
toolbox_path = fullfile('/Volumes/Cai''s MBP HDD/Documents/Code/Neurolex/RSA-MEG');

chdir(output_dir)
mkdir('Figures');
figures_dir = fullfile(output_dir, 'Figures');

addpath(genpath(toolbox_path));


%% UserOptions
userOptions = struct();
userOptions.saveFiguresJpg = true;
userOptions.displayFigures = false;
userOptions.analysisName = 'active-triphone';
userOptions.rootPath = '';


%% Other options
animation_frame_delay = 0.15; % Delay in seconds between successive frames
figure_size = [0, 0, 1200, 800];


%% Get the list of phones and load in each one

% All files
chdir(input_dir);
file_list = dir('*.mat');

% Preallocate
phone_list = cell(length(file_list), 1);
phones_data = struct();

for file_i = 1:length(file_list)
   this_file_name = file_list(file_i).name;
   
   % get the phone name
   filename_parts = strsplit(this_file_name, '.');
   filename = filename_parts{1};
   filename_parts = strsplit(filename, '-');
   this_phone_name = filename_parts{2};
   phone_list{file_i} = this_phone_name;
   
   % load this phone's data
   phones_data.(this_phone_name) = load(this_file_name);
end

%% Get some lists and limits
phone_list = sort(phone_list);
word_list = fieldnames(phones_data.(phone_list{1}));
word_list = sort(word_list);
n_frames = size(phones_data.(phone_list{1}).(word_list{1}), 1);

%% Clear some things out
clear this_phone_name;
clear this_file_name;
clear file_i;
clear file_list;
clear filename;
clear filename_parts;

%% Build RDMs
% We have one RDM for each frame and each phone
for frame = 1 : n_frames
    for phone_i = 1 : length(phone_list)
        this_phone = phone_list{phone_i};
        
        this_RDM_name = sprintf('%s frame%d', this_phone, frame);
        
        data_for_this_RDM = NaN;
        
        % The RDMs are word-by-word
        for word_i = 1 : length(word_list)
            this_word = word_list{word_i};
            data_for_this_condition = phones_data.(this_phone).(this_word)(frame, :);
            if isnan(data_for_this_RDM)
            	data_for_this_RDM = data_for_this_condition;
            else
                data_for_this_RDM = cat(1, data_for_this_RDM, data_for_this_condition);
            end%if
        end%for:words
        
        this_RDM = pdist(data_for_this_RDM, 'hamming');
        if all(this_RDM == this_RDM(1))
            this_rank_transformed_RDM = squareform(zeros(size(this_RDM)));
        else
            this_rank_transformed_RDM = squareform(scale01(tiedrank(this_RDM)));
        end%if
        this_RDM = squareform(this_RDM);
        
        RDMs(frame, phone_i).name = this_RDM_name;
        RDMs(frame, phone_i).RDM = this_RDM;
        RDMs(frame, phone_i).phone = this_phone;
        
        rank_transformed_RDMs(frame, phone_i).name = this_RDM_name;
        rank_transformed_RDMs(frame, phone_i).RDM = this_rank_transformed_RDM;
    end%for:phones
    
    disp(frame);
end%for:frames

%% Save this for now

chdir(output_dir);
save('RDMs', 'RDMs');
clear RDMs;

%% Show RDMs

for frame = 1 : n_frames
    RDMs_this_frame = rank_transformed_RDMs(frame,:);
    showRDMs(RDMs_this_frame, frame, false, [0,1], true, 1, [], 'Jet');
    
    this_figure = gcf;
        
    % Resize the current figure
    set(this_figure, 'Position', figure_size);
    
    f = getframe(this_figure);
    
    % All models
    if frame == 1
        [all_models_image_stack, map] = rgb2ind(f.cdata, 256, 'nodither');
        all_models_image_stack(1,1,1,n_frames) = 0;
    else
        all_models_image_stack(:,:,1,frame) = rgb2ind(f.cdata, map, 'nodither');
    end%if
    
    close;
    
    % Individual modles
    for phone_i = 1 : size(RDMs_this_frame, 2);
        RDM_this_model = rank_transformed_RDMs(frame, phone_i);
        showRDMs(RDM_this_model, 1, false, [0,1], true, 1, [], 'Jet');
        
        this_figure = gcf;
        
        % Resize the current figure
        set(this_figure, 'Position', figure_size);
        
        % Get the pixel values of the current figure
        f = getframe(this_figure);
        
        % Add the data of the current figure to the stack for animating
        if frame == 1
            [each_model_image_stack.(phone_list{phone_i}), maps.(phone_list{phone_i})] = rgb2ind(f.cdata, 256, 'nodither');
            each_model_image_stack.(phone_list{phone_i})(1,1,1,n_frames) = 0;
        else
            each_model_image_stack.(phone_list{phone_i})(:,:,1,frame) = rgb2ind(f.cdata, maps.(phone_list{phone_i}), 'nodither');
        end%if
        
        % We don't need these piling up, as the image data is saved in the
        % animation stack.
        close;
        
    end%for
        
    disp(frame);
end%for:frames

% Save animated gifs
chdir(figures_dir);
imwrite(all_models_image_stack, map, 'all_models.gif', 'DelayTime', animation_frame_delay, 'LoopCount', inf);
for phone_i = 1 : length(phone_list)
    imwrite(each_model_image_stack.(phone_list{phone_i}), maps.(phone_list{phone_i}), [phone_list{phone_i}, '.gif'], 'DelayTime', animation_frame_delay, 'LoopCount', inf);
end%for

