bn26 = load('bn26_activations.mat');
bn26 = orderfields(bn26);

words = fieldnames(bn26);
n_words = numel(words);
[n_frames, n_nodes] = size(bn26.(words{1}));

% Get clims
clims = [0, 1];
for word_i = 1:n_words
   word = words{word_i};
   clims(1) = min(clims(1), min(bn26.(word)(:)));
   clims(2) = max(clims(2), max(bn26.(word)(:)));
end

for word_i = 1:n_words
   word = words{word_i};
   
   figure;
   this_figure = gcf;
   
   imagesc(bn26.(word)', clims);
   colorbar;
   colormap(hot);
   
   title(word);
   
   % save the figure
   file_name = sprintf('activations_for_%s', word);
   print(this_figure, file_name, '-dpng');
   
   close(this_figure);
   
end
