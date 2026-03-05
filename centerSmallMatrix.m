function largeMatrixProcessed = centerSmallMatrix(smallMatrix, largeMatrix)
% CENTERSMALLMATRIX Places a smaller 2D matrix into the center of a larger one.
%
% Usage:
%   largeMatrixProcessed = centerSmallMatrix(smallMatrix, largeMatrix)
%
% Inputs:
%   smallMatrix - The smaller matrix to be embedded.
%   largeMatrix - The target matrix (background).
%
% Outputs:
%   largeMatrixProcessed - The final matrix with the small matrix centered.

    %% 1. Get Dimensions
    [numRowsLarge, numColsLarge] = size(largeMatrix); 
    [numRowsSmall, numColsSmall] = size(smallMatrix); 
    
    %% 2. Dimensional Validation
    % Check if the small matrix actually fits inside the large one
    if numRowsSmall > numRowsLarge || numColsSmall > numColsLarge
        error('Error: smallMatrix dimensions exceed largeMatrix dimensions.');
    end
    
    %% 3. Calculate Placement Coordinates
    % Find the starting row and column (top-left corner of the insertion)
    startRow = floor((numRowsLarge - numRowsSmall) / 2) + 1;
    startCol = floor((numColsLarge - numColsSmall) / 2) + 1;
    
    % Find the ending row and column
    endRow = startRow + numRowsSmall - 1;
    endCol = startCol + numColsSmall - 1;
    
    %% 4. Embed the Matrix
    % Initialize the output as a copy of the large matrix
    largeMatrixProcessed = largeMatrix;
    
    % Overwrite the center section with the small matrix
    largeMatrixProcessed(startRow:endRow, startCol:endCol) = smallMatrix;
    
end