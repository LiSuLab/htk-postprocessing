clear;
close all;

%% Paths

% Change these values
input_dir = fullfile('/Users', 'cai', 'Desktop', 'matlab-out');
output_dir = fullfile('/Users', 'cai', 'Desktop', 'matlab-out-again');
toolbox_path = fullfile('/Volumes/Cai''s MBP HDD/Documents/Code/Neurolex/RSA-MEG');

chdir(output_dir)
mkdir('Figures');
figures_dir = fullfile(output_dir, 'Figures');

addpath(genpath(toolbox_path));


%% UserOptions
userOptions = struct();
userOptions.saveFiguresJpg = false;
userOptions.displayFigures = close;
userOptions.analysisName = 'active-triphone';
userOptions.rootPath = output_dir;


%% Other options
animation_frame_delay = 0.15; % Delay in seconds between successive frames
figure_size = [0, 0, 1200, 800];


%% Phone labelling

phone_label.aa = 1; % vowel	
phone_label.ae = 1; % vowel	
phone_label.ah = 1; % vowel	
phone_label.ao = 1; % vowel	
phone_label.aw = 1; % vowel	
phone_label.ax = 1; % vowel	
phone_label.ay = 1; % vowel	
phone_label.ea = 1; % vowel	
phone_label.eh = 1; % vowel	
phone_label.er = 1; % vowel	
phone_label.ey = 1; % vowel	
phone_label.ia = 1; % vowel	
phone_label.ih = 1; % vowel	
phone_label.iy = 1; % vowel	
phone_label.oh = 1; % vowel	
phone_label.ow = 1; % vowel	
phone_label.oy = 1; % vowel	
phone_label.ua = 1; % vowel	
phone_label.uh = 1; % vowel	
phone_label.uw = 1; % vowel	
phone_label.b  = 2; % consonant	bilabial	stop	voiced
phone_label.p  = 2; % consonant	bilabial	stop	unvoiced
phone_label.m  = 2; % consonant	bilabial	nasal
phone_label.y  = 2; % consonant	paletal	approximant
phone_label.jh = 2; % consonant	palato-alveolar	affricate	voiced
phone_label.ch = 2; % consonant	palato-alveolar	affricate	unvoiced
phone_label.zh = 2; % consonant	palato-alveolar sibilant fricative	voiced
phone_label.sh = 2; % consonant	palato-alveolar	sibilant fricative	unvoiced
phone_label.d  = 2; % consonant	alveolar	stop	voiced
phone_label.t  = 2; % consonant	alveolar	stop	unvoiced
phone_label.l  = 2; % consonant	alveolar	lateral approximant
phone_label.n  = 2; % consonant	alveolar	nasal
phone_label.r  = 2; % consonant	alveolar	trill
phone_label.z  = 2; % consonant	alveolar	sibilant fricative	voiced
phone_label.s  = 2; % consonant	alveolar	sibilant fricative	unvoiced
phone_label.dh = 2; % consonant	interdental	fricative	voiced
phone_label.th = 2; % consonant	interdental	fricative	unvoiced
phone_label.v  = 2; % consonant	labiodental	fricative	voiced
phone_label.f  = 2; % consonant	labiodental	fricative	unvoiced
phone_label.g  = 2; % consonant	velar	stop	voiced
phone_label.k  = 2; % consonant	velar	stop	unvoiced
phone_label.ng = 2; % consonant	velar	nasal
phone_label.hh = 2; % consonant	glottal	fricative
phone_label.w  = 2; % consonant	labio-velar	approximant

category_colour_mapping(1) = {[1, 0, 0]};
category_colour_mapping(2) = {[0, 1, 0]};


%% Load RDMs

chdir(input_dir);
RDMs = load('RDMs.mat');
RDMs = RDMs.RDMs;

phone_free_RDMs = rmfield(RDMs, 'phone');


%% Start iterating on each frame
pats_mds_2D = NaN;

n_frames = size(RDMs, 1);
n_phones = size(RDMs, 2);
for frame = 1:n_frames
    
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
    RDM_d_matrix_this_frame = RDMCorrMat(RDMs(frame, :), 1, 'Spearman');
    
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
    if isnan(pats_mds_2D)
        % Start at random positions
        MDS_options_extra.initialPositions = 'random';
    else
        % Continue with previous positions
        MDS_options_extra.initialPositions = pats_mds_2D;
    end
    pats_mds_2D = MDSRDMs({phone_free_RDMs(frame, :)}, MDS_options, MDS_options_extra);
    
    %% Adjust figure
    
    this_figure = gcf;
        
    % Resize the current figure
    set(this_figure, 'Position', figure_size);
    
    f = getframe(this_figure);
    
    % Store figure in stack
    if frame == 1
        [all_models_image_stack, map] = rgb2ind(f.cdata, 256, 'nodither');
        all_models_image_stack(1,1,1,n_frames) = 0;
    else
        all_models_image_stack(:,:,1,frame) = rgb2ind(f.cdata, map, 'nodither');
    end%if
    
    close;
    
    %% Clean up
    
    disp(frame);
    
end%for:frame

% Save animated gifs
chdir(figures_dir);
imwrite(all_models_image_stack, map, 'all_models_mds.gif', 'DelayTime', animation_frame_delay, 'LoopCount', inf);

