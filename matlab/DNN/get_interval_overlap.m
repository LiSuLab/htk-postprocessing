% Imagine an interval in the foreground moving over a stationary background
% interval. This function calculates the degree to which the foreground
% interval overlaps the background window, as a fraction of the width of
% the foreground window.
%
function fraction = get_interval_overlap(background, foreground)

    % Input validations
    assert(is_interval(foreground));
    assert(is_interval(background));

    overlap = NaN;

    % Find out which case we're in.
    if foreground(1) <= background(1)
        % `foreground` starts to the left of `background`
        if foreground(2) <= background(2)
            % `foreground` does not intersect with `background` by more
            % than a point.
            overlap = 0;
        else
            % There is some overlap. `foreground peaks over the left side
            % of background.
            if foreground(2) < background(2)
                % `foreground` hasn't covered all of `background`
                overlap = foreground(2) - background(1);
            else
                % `foreground` has covered all of `background`
                overlap = background(2) - background(1);
            end
        end
    else
        % `foreground` starts to the right of the left-edge of `background`
        if foreground(2) <= background(2)
            % `foreground` is entirely inside `background`
            overlap = foreground(2) - foreground(1);
        else
            % `foreground` ends to the right of `background`
            if foreground(1) >= background(2)
                % `foreground does not intersect with `background` by more
                % than a point.
                overlap = 0;
            else
                % There is some overlap. `foreground` peaks over the right
                % side of `background`.
                overlap = background(2) - foreground(1);
            end
        end
    end
    
    % Avoid dividing by zero
    width = foreground(2) - foreground(1);
    if width == 0
        fraction = 0;
    else
        fraction = overlap / width;
    end

end

%% Subfunctions

function result = is_interval(X)
    result = (numel(X) == 2 && issorted(X));
end
