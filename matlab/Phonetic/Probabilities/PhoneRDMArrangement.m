clear;
close all;

%% Paths

% Change these values
input_dir = '/Users/cai/Desktop/cwd_likelihood/models';
output_dir = '/Users/cai/Desktop/cwd_likelihood/models';

chdir(output_dir)
mkdir('Figures');
figures_dir = fullfile(output_dir, 'Figures');


%% UserOptions
userOptions = struct();
userOptions.saveFiguresJpg = false;
userOptions.displayFigures = false;
userOptions.analysisName = 'triphone-likelihood';
userOptions.rootPath = output_dir;
userOptions.RDMCorrelationType = 'Spearman';


%% Other options
animation_frame_delay = 0.15; % Delay in seconds between successive frames
figure_size = [0, 0, 1200, 800];


%% Phone labelling

% sonorant
phone_label.aa = 1;
phone_label.ae = 1;
phone_label.ah = 1;
phone_label.ao = 1;
phone_label.aw = 1;
phone_label.ax = 1;
phone_label.ay = 1;
phone_label.b  = 2;
phone_label.ch = 2;
phone_label.d  = 2;
phone_label.dh = 2;
phone_label.ea = 1;
phone_label.eh = 1;
phone_label.er = 1;
phone_label.ey = 1;
phone_label.f  = 2;
phone_label.g  = 2;
phone_label.hh = 2;
phone_label.ia = 1;
phone_label.ih = 1;
phone_label.iy = 1;
phone_label.jh = 2;
phone_label.k  = 2;
phone_label.l  = 1;
phone_label.m  = 2;
phone_label.n  = 2;
phone_label.ng = 2;
phone_label.oh = 1;
phone_label.ow = 1;
phone_label.oy = 1;
phone_label.p  = 2;
phone_label.r  = 1;
phone_label.s  = 2;
phone_label.sh = 2;
phone_label.t  = 2;
phone_label.th = 2;
phone_label.ua = 1;
phone_label.uh = 1;
phone_label.uw = 1;
phone_label.v  = 2;
phone_label.w  = 1;
phone_label.y  = 1;
phone_label.z  = 2;
phone_label.zh = 2;

category_colour_mapping(1) = {[1, 0, 0]};
category_colour_mapping(2) = {[0, 1, 0]};


%% Load RDMs

chdir(input_dir);
RDMs = rsa.util.directLoad('triphone-likelihood-RDMs.mat');

phone_free_RDMs = rmfield(RDMs, 'phone');


%% Start iterating on each frame
pats_mds_2D = NaN;

n_frames = size(RDMs, 1);
n_phones = size(RDMs, 2);

skip_frames = 4;
animation_frame = 1;

for frame = skip_frames+1:n_frames
    
    %% Second-order similarity matrix
    
    % Apply colour to RDMs for this frame
    for phone_i = 1:n_phones
        
        % Get phone info
        this_phone = RDMs(frame, phone_i).phone;
        this_phone_label = phone_label.(this_phone);
        this_phone_colour = category_colour_mapping{this_phone_label};
        
        % Apply colour to RDM
        RDMs(frame, phone_i).color = this_phone_colour;
        phone_free_RDMs(frame, phone_i).color = this_phone_colour;
        RDMs(frame, phone_i).name = this_phone;
        phone_free_RDMs(frame, phone_i).name = this_phone;
        
    end%for:phone_i
        
    % Calculate and show a second order matrix
    % TODO: Don't use Spearman here, use a signed-rank test
    RDM_d_matrix_this_frame = rsa.stat.RDMCorrMat(RDMs(frame, :), 1, 'Spearman');
    colormap(jet);
    
    %% MDS RDMs
    
    % Set up options
    MDS_options = userOptions;
    MDS_options.criterion = 'metricsstress';
    MDS_options.rubberbands = false;
    MDS_options.displayFigures = true;
    MDS_options_extra.titleString = sprintf('Frame %d', frame);
    MDS_options_extra.rubberbandGraphPlot = false;
    MDS_options_extra.figureNumber = 1;
    MDS_options_extra.dMatrix = RDM_d_matrix_this_frame;
    
    % Do the MDS
    rsa.MDSRDMs({phone_free_RDMs(frame, :)}, MDS_options, MDS_options_extra);
    
    %% Adjust figure
    
    this_figure = gcf;
        
    % Resize the current figure
    set(this_figure, 'Position', figure_size);
    
    f = getframe(this_figure);
    
    % Store figure in stack
    if animation_frame == 1
        [all_models_image_stack, map] = rgb2ind(f.cdata, 256, 'nodither');
        all_models_image_stack(1,1,1,n_frames-skip_frames) = 0;
    else
        all_models_image_stack(:,:,1,animation_frame) = rgb2ind(f.cdata, map, 'nodither');
    end%if
    
    animation_frame = animation_frame + 1;
    
    close;
    
    %% Clean up
    
    disp(frame);
    
end%for:frame

% Save animated gifs
chdir(figures_dir);
imwrite(all_models_image_stack, map, 'all_models_likelihood_mds.gif', 'DelayTime', animation_frame_delay, 'LoopCount', inf);

