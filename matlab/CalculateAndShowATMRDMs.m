clear;
close all;

%% Paths

% Change these values
input_dir = fullfile('C:', 'Users', 'cai', 'analyses', 'Lexpro', 'output', 'python');
output_dir = fullfile('C:', 'Users', 'cai', 'analyses', 'Lexpro', 'output', 'matlab');

chdir(output_dir)
mkdir('Figures');
figures_dir = fullfile(output_dir, 'Figures');


%% UserOptions
userOptions = struct();
userOptions.saveFiguresJpg = true;
userOptions.displayFigures = false;
userOptions.analysisName = 'active-triphone';
userOptions.rootPath = '';


%% Get the list of phones and load in each one

% All files
chdir(input_dir);
file_list = dir('*.mat');

% Preallocate
phone_list = cell(length(file_list));
phones = struct();

for file_i = 1:length(file_list)
   this_file_name = file_list(file_i).name;
   
   % get the phone name
   filename_parts = strsplit(this_file_name, '.');
   filename = filename_parts{1};
   filename_parts = strsplit(filename, '-');
   this_phone_name = filename_parts{2};
   phone_list{file_i} = this_phone_name;
   
   % load this phone's data
   phones.(this_phone_name) = load(this_file_name);
end

%% Get some lists and limits
phones_list = fieldnames(phones);
phones_list = sort(phones_list);
word_list = fieldnames(phones.(phones_list{1}));
word_list = sort(word_list);
n_frames = size(phones.(phones_list{1}).(word_list{1}), 1);

%% Build RDMs
% We have one RDM for each frame and each phone
for frame = 1 : n_frames
    for phone_i = 1 : length(phones_list)
        this_phone = phones_list{phone_i};
        
        this_RDM_name = sprintf('%s frame%d', this_phone, frame);
        
        data_for_this_RDM = NaN;
        
        % The RDMs are word-by-word
        for word_i = 1 : length(word_list)
            this_word = word_list{word_i};
            data_for_this_condition = phones.(this_phone).(this_word)(frame, :);
            if isnan(data_for_this_RDM)
            	data_for_this_RDM = data_for_this_condition;
            else
                data_for_this_RDM = cat(1, data_for_this_RDM, data_for_this_condition);
            end%if
        end%for:words
        
        this_RDM = squareform(pdist(data_for_this_RDM, 'hamming'));
        
        RDMs(phone_i, frame).name = this_RDM_name;
        RDMs(phone_i, frame).RDM = this_RDM;
    end%for:phones
end%for:frames
