function clims = centre_clims_on_zero(clims)
    top = clims(2);
    bottom = clims(1);
    
    hugest = max(top, -1*bottom);
    
    clims(1) = -1*hugest;
    clims(2) = hugest;
end
