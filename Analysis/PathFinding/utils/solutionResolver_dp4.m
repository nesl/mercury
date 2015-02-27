function [solver] = solutionResolver_dp4(matFileName, varargin)
    % We shouldn't just run the solver and see the result and say ya and
    % then do nothing... We should store the result and for future analysis
    
    % matFileName: just the file name, not path
    % varargin: if specified, this should be a solver, and this function
    %           will be treated as a save function. And the result will be
    %           assigned as the passing solver.
    %           if not, then the function interprets you want to load the
    %           solver. It returns the solver from the output
    
    MAT_FOLDER = '../../Data/resultOfSolverDP4/';  % since we should always be called from one-level-out script, thus only two levels of ../
    
    if length(matFileName) >= 4 && strcmp(matFileName(end-3:end), '.mat') == 0  % doesn't have an extension
        matFileName = [matFileName '.mat'];
    end
    matPath = [MAT_FOLDER matFileName];
    if numel(varargin) >= 1  % save mode
        solver = varargin{1};
        save(matPath, 'solver');
    else
        load(matPath, 'solver');
    end
end

