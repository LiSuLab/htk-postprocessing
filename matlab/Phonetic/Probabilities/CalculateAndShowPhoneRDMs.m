clear;
close all;

%% Paths

% Change these values
input_dir = fullfile('/Users', 'cai', 'Desktop', 'cwd_likelihood', 'phones_data');
output_dir = fullfile('/Users', 'cai', 'Desktop', 'cwd_likelihood', 'models');
toolbox_path = '/Volumes/Cai''s MBP HDD/Documents/Code/Neurolex/rsatoolbox-rsagroup';

chdir(output_dir)

addpath(genpath(toolbox_path));


%% Options

% Whether or not to go through with displaying the RDMs.
do_display = false;

% Width of the sliding window in frames.
sliding_window_width = 6;

% Step of the sliding window in frames.
sliding_window_step = 1;

% The frame_id of the first usable frame.
first_usable_htk_frame = 2;

% Convert an htk frame id into a time index for the start of the frame.
htk_frame_to_ms = @(htk_frame_id) (htk_frame_id*10)-10;

% Delay in seconds between successive frames.
animation_frame_delay = 0.5;

% The position of the figures if they're displayed.
figure_size = [10, 10, 800, 600];


%% Get the list of phones and load in each one

rsa.util.prints('Loading phones data...');

% All files
chdir(input_dir);
file_list = dir('*.mat');

% Wow this is an ugly hack.
% -1 is a SUPER FRAGILE hack to remove the last thing in list, which isn't
% actually a frame data file.
last_frame_id = str2num(file_list(end-1).name(1:2));

for file_i = 1:length(file_list)
   this_file_name = file_list(file_i).name;
   
   % get the phone name
   filename_parts = strsplit(this_file_name, '.');
   filename = filename_parts{1};
   this_htk_frame = str2num(filename);
   
   % To ignore `used_triphones.mat`
   if length(filename) > 3
       continue;
   end
   
   % We're going to skip these frames
   if this_htk_frame < first_usable_htk_frame
       continue;
   end
   
   % If we're using this frame, we give it a name
   frame_id = sprintf('frame_%2.2d', this_htk_frame);
   
   frame_data = load(this_file_name);
   
   % load this phone's data
   phones_data.(frame_id) = frame_data;
end

phone_list = fields(phones_data.(sprintf('frame_%2.2d', first_usable_htk_frame)));
phone_list = sort(phone_list);

n_words = size(phones_data.(sprintf('frame_%2.2d', first_usable_htk_frame)).(phone_list{1}), 1);

%% Sliding window setup

% The sliding window position refer to htk frames.
sliding_window_positions = [];
window_starting_points = first_usable_htk_frame:sliding_window_step:last_frame_id;
for first_frame_in_window = window_starting_points
    this_window = (first_frame_in_window:first_frame_in_window+sliding_window_width-1)';
    if max(this_window) <= last_frame_id
        sliding_window_positions = [sliding_window_positions, this_window];
    else
        break;
    end
end

%% Build RDMs

% Start on the first frame of real RDMs
animation_frame_i = 1;

% We have one RDM for each frame and each phone
for window_frames = sliding_window_positions
    for phone_i = 1 : length(phone_list)
        this_phone = phone_list{phone_i};
        
        data_for_this_RDM = [];
        for window_frame = window_frames'
            window_frame_id = sprintf('frame_%2.2d', window_frame);
            data_this_frame = phones_data.(window_frame_id).(this_phone);
            data_for_this_RDM = [ ...
                data_for_this_RDM, ...
                data_this_frame];
        end
        
        % check if pdist can possibly wory
        no_data = all(all(isnan(data_for_this_RDM)));
        data_overlap = sum(data_for_this_RDM, 1);
        no_overlapping_data = all(isnan(data_overlap));
        
        if no_data || no_overlapping_data
            this_RDM = 1 - eye(n_words, n_words);
        else
            % remove nans
            data_for_this_RDM = data_for_this_RDM(:, ~isnan(data_overlap));
            
            % Compute the distances, and scale it by the length of the vector.
            this_RDM = squareform( ...
                pdist( ...
                    data_for_this_RDM, ...
                    'Correlation'));
        end
        
        this_rank_transformed_RDM = squareform( ...
            rsa.util.scale01(tiedrank(squareform(this_RDM))));
        
        this_RDM_name = sprintf( ...
            '%s window [%dms-%dms]', ...
            this_phone, ...
            htk_frame_to_ms(window_frames(1)), ...
            ...%+1 because we want to list the time index of the end of the window.
            htk_frame_to_ms(window_frames(end)+1));
        
        RDMs(animation_frame_i, phone_i).name = this_RDM_name;
        RDMs(animation_frame_i, phone_i).RDM = this_RDM;
        RDMs(animation_frame_i, phone_i).phone = this_phone;
        
        RDMs_for_display(animation_frame_i, phone_i).name = this_RDM_name;
        RDMs_for_display(animation_frame_i, phone_i).RDM = this_rank_transformed_RDM;
    end%for:phones
    
    rsa.util.prints('Frame %02d done.', animation_frame_i);
    
    animation_frame_i = animation_frame_i + 1;
end%for:frames

%% Save this for now

chdir(output_dir);
save('triphone-likelihood-RDMs', 'RDMs', '-v7.3');
phonetic_model_RDMs = RDMs;
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

        rsa.util.prints('Figures for frame %d stored in memory.', frame);
    end%for:frames

    % Save animated gifs
    chdir(figures_dir);
    imwrite(all_models_image_stack, map, 'all_models_likelihood.gif', 'DelayTime', animation_frame_delay, 'LoopCount', inf);
    for phone_i = 1 : length(phone_list)
        imwrite(each_model_image_stack.(phone_list{phone_i}), maps.(phone_list{phone_i}), [phone_list{phone_i}, '_likelihood.gif'], 'DelayTime', animation_frame_delay, 'LoopCount', inf);
    end%for

end

