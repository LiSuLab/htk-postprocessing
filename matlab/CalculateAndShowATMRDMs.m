clear;
close all;

%% Paths

% Change these values
input_dir = fullfile('C:', 'Users', 'cai', 'analyses', 'Lexpro', 'Phonetic_models', 'Active_triphone_models');
output_dir = fullfile('C:', 'Users', 'cai', 'analyses', 'Lexpro', 'Phonetic_models', 'Active_triphone_models');

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
   
   %% load this phone's data
   phones.(this_phone_name) = load(this_file_name);
end

