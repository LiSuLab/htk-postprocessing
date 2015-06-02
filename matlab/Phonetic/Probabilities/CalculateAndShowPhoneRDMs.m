clear;
close all;

%% Paths

% Change these values
input_dir = fullfile('/Users', 'cai', 'Desktop', 'cwd', 'phones_data');
output_dir = fullfile('/Users', 'cai', 'Desktop', 'cwd', 'models');
toolbox_path = '/Volumes/Cai''s MBP HDD/Documents/Code/Neurolex/rsatoolbox-rsagroup';

chdir(output_dir)

addpath(genpath(toolbox_path));


%% UserOptions
userOptions = struct();
userOptions.saveFiguresJpg = true;
userOptions.displayFigures = false;
userOptions.analysisName = 'triphone-likelihood';
userOptions.rootPath = '';


%% Model options

% Width of the sliding window in frames.
sliding_window_width = 3;

% Step of the sliding window in frames.
sliding_window_step = 1;

% The first frame of the models isn't 0ms, it's 10ms, so we record that
% here so we can pad the beginning with zeros.
model_offset_in_timesteps = 1;


%% Display options

do_display = true;

animation_frame_delay = 0.5; % Delay in seconds between successive frames
figure_size = [0, 0, 1200, 800];


%% Get the list of phones and load in each one

rsa.util.prints('Loading phones data...');

% All files
chdir(input_dir);
file_list = dir('*.mat');

n_frames = length(file_list);

for file_i = 1:length(file_list)
   this_file_name = file_list(file_i).name;
   
   % get the phone name
   filename_parts = strsplit(this_file_name, '.');
   filename = filename_parts{1};
   this_frame = str2num(filename);
   
   frame_data = load(this_file_name);
   
   % load this phone's data
   phones_data(this_frame) = frame_data;
end

phone_list = fields(phones_data(2));
phone_list = sort(phone_list);

n_words = size(phones_data(2).(phone_list{1}), 1);

% Fake the missing data on the first frame. We know it's all zeros anyway.
for phone_i = 1:numel(phone_list)
    phone = phone_list{phone_i};
    phones_data(1).(phone) = nan(n_words,1);
end

%% Sliding window setup

sliding_window_positions = [];
for first_frame_in_window = 1:sliding_window_step:n_frames
    this_window = (first_frame_in_window:first_frame_in_window+sliding_window_width-1)';
    if max(this_window) <= n_frames
        sliding_window_positions = [sliding_window_positions, this_window];
    else
        break;
    end
end

%% Build RDMs

% Start on the first frame of real RDMs
animation_frame_i = model_offset_in_timesteps;

% We have one RDM for each frame and each phone
for window_frames = sliding_window_positions
    for phone_i = 1 : length(phone_list)
        this_phone = phone_list{phone_i};
        
        this_RDM_name = sprintf('%s frame%d', this_phone, animation_frame_i);
        
        data_for_this_RDM = [];
        for window_frame = window_frames'
            data_this_frame = phones_data(window_frame).(this_phone);
            if ~all(isnan(data_this_frame))
                data_for_this_RDM = [ ...
                    data_for_this_RDM, ...
                    ];
            end
        end
        
        % Sometimes all the data is nan, because there is no data whatsoever.
        % In this case we constrain the RDMs to be all-zeros.
        if isempty(data_for_this_RDM)
            this_RDM = zeros(n_words, n_words);
        else
            % Compute the distances, and scale it by the length of the vector.
            this_RDM = squareform( ...
                pdist( ...
                    data_for_this_RDM, ...
                    'Correlation'));
        end
        
        this_rank_transformed_RDM = squareform( ...
            rsa.util.scale01(tiedrank(squareform(this_RDM))));
        
        RDMs(animation_frame_i, phone_i).name = this_RDM_name;
        RDMs(animation_frame_i, phone_i).RDM = this_RDM;
        RDMs(animation_frame_i, phone_i).phone = this_phone;
        
        RDMs_for_display(animation_frame_i, phone_i).name = this_RDM_name;
        RDMs_for_display(animation_frame_i, phone_i).RDM = this_rank_transformed_RDM;
    end%for:phones
    
    rsa.util.prints('Frame %02d done.', animation_frame_i);
    
    animation_frame_i = animation_frame_i + 1;
end%for:frames

% Finally we start the animation with the appropriate number of padding
% frames.
for animation_frame_i = 1:model_offset_in_timesteps
    for phone_i = 1:length(phone_list)
        this_phone = phone_list{phone_i};
        this_RDM_name = sprintf('%s frame%d (padding)', this_phone, animation_frame_i);
        RDMs(animation_frame_i, phone_i).name  = this_RDM_name;
        RDMs(animation_frame_i, phone_i).phone = this_phone;
        % Wow, this is fragile and uses Matlab's horrible scope breaking!
        RDMs(animation_frame_i, phone_i).RDM   = zeros(size(this_RDM));
        
        RDMs_for_display(animation_frame_i, phone_i).name = this_RDM_name;
        % Wow, this is fragile and uses Matlab's horrible scope breaking!
        RDMs_for_display(animation_frame_i, phone_i).RDM  = zeros(size(this_RDM));
    end
end

%% Save this for now

chdir(output_dir);
save('triphone-likelihood-RDMs', 'RDMs', '-v7.3');
clear RDMs;

%% Show RDMs

if do_display
    
    mkdir('Figures');
    figures_dir = fullfile(output_dir, 'Figures');

    n_animation_frames = size(RDMs_for_display, 1);

    for frame = 1 : n_animation_frames
        RDMs_this_frame = RDMs_for_display(frame,:);
        rsa.fig.showRDMs(RDMs_this_frame, frame, false, [0,1], true, 1, [], 'Jet');
        colormap(jet);

        this_figure = gcf;

        % Resize the current figure
        set(this_figure, 'Position', figure_size);

        f = getframe(this_figure);

        % All models
        if frame == 1
            [all_models_image_stack, map] = rgb2ind(f.cdata, 256, 'nodither');
            all_models_image_stack(1,1,1,n_animation_frames) = 0;
        else
            all_models_image_stack(:,:,1,frame) = rgb2ind(f.cdata, map, 'nodither');
        end%if

        close;

        % Individual modles
        for phone_i = 1 : size(RDMs_this_frame, 2);
            RDM_this_model = RDMs_for_display(frame, phone_i);
            rsa.fig.showRDMs(RDM_this_model, 1, false, [0,1], true, 1, [], 'Jet');
            colormap(jet);

            this_figure = gcf;

            % Resize the current figure
            set(this_figure, 'Position', figure_size);

            % Get the pixel values of the current figure
            f = getframe(this_figure);

            % Add the data of the current figure to the stack for animating
            if frame == 1
                [each_model_image_stack.(phone_list{phone_i}), maps.(phone_list{phone_i})] = rgb2ind(f.cdata, 256, 'nodither');
                each_model_image_stack.(phone_list{phone_i})(1,1,1,n_animation_frames) = 0;
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
    imwrite(all_models_image_stack, map, 'all_models_likelihood.gif', 'DelayTime', animation_frame_delay, 'LoopCount', inf);
    for phone_i = 1 : length(phone_list)
        imwrite(each_model_image_stack.(phone_list{phone_i}), maps.(phone_list{phone_i}), [phone_list{phone_i}, '_likelihood.gif'], 'DelayTime', animation_frame_delay, 'LoopCount', inf);
    end%for

end

