% =========================================================================
% ShowDarkToDLiDMD.m
% 
% Purpose: Creates a completely dark (black) image and displays it 1:1 on 
% the second monitor, which is the DLi9000 DMD in this case.
% =========================================================================

%% 1. Define Image Dimensions
% Set to the native resolution of the DMD
Width = 2560; 
Height = 1600;

% Create a completely black 8-bit image 
% (Optimized: pre-allocate as uint8 directly)
DarkImage = zeros(Height, Width, 'uint8');

%% 2. Initialize Figure Window
% Create a figure window tailored for the DMD display without menus.
% Note: Changed background color from 'r' (red) to 'k' (black) to prevent 
% light leakage. If the red border was used for debugging alignment, 
% change 'Color', 'k' back to 'Color', 'r'.
FigureForShow = figure('Color', 'k', ... 
                       'Units', 'pixels', ...
                       'MenuBar', 'none', ...
                       'NumberTitle', 'off', ...
                       'Colormap', gray);

% Display the image with loose borders
hAxes = axes('Parent', FigureForShow);
imshow(DarkImage, 'Parent', hAxes, 'Border', 'loose');

% Enforce 1:1 pixel mapping between the image matrix and screen pixels
[imgHeight, imgWidth] = size(DarkImage);
truesize(FigureForShow, [imgHeight, imgWidth]);

%% 3. Position Window on the Second Monitor (DMD)
% Get current figure dimensions
pos = get(FigureForShow, 'Position');
WidthOfFig = pos(3);
HeightOfFig = pos(4);

% Retrieve second monitor coordinates using custom function
[Monitor2PosX, Monitor2PosY, ~, ~] = secondMonitorInfo();

% Apply empirical offsets for the DLi DMD to ensure exact placement.
% These offsets account for the OS window borders/decorations.
targetX = Monitor2PosX - 371; 
targetY = Monitor2PosY - 181; 

% Manual override coordinates (uncomment if running from specific workstation)
% targetX = 3470;  
% targetY = -177;  

% Move the figure to the DMD monitor while maintaining its exact pixel size
set(FigureForShow, 'Position', [targetX, targetY, WidthOfFig, HeightOfFig]);

%% 4. Clean Up Workspace
% Clear temporary positioning variables to keep the workspace tidy
clear targetX targetY Height Width WidthOfFig HeightOfFig pos imgHeight imgWidth hAxes Monitor2PosX Monitor2PosY;