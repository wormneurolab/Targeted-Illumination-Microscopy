% =========================================================================
% ShowWhiteToDLiDMD.m
% 
% Purpose: Projects a full-screen white image to the second monitor (DMD).
% This is commonly used for widefield illumination or laser targeting.
% =========================================================================

%% 1. Define Image Dimensions
Width  = 2560; 
Height = 1600;

% Create a solid white 8-bit image
WhiteImage = repmat(uint8(255), Height, Width);

%% 2. Initialize Figure for DMD Display
% We use a red background ('Color', 'r') as a border for alignment visibility
FigureForShow = figure('Color', 'r', ...
                       'Units', 'pixels', ...
                       'MenuBar', 'none', ...
                       'NumberTitle', 'off', ...
                       'Colormap', gray);

hAxes = subplot(1, 1, 1);
imshow(WhiteImage, 'Parent', hAxes, 'Border', 'loose');

% Enforce 1:1 pixel mapping
[imgHeight, imgWidth] = size(WhiteImage);
truesize(FigureForShow, [imgHeight, imgWidth]);

%% 3. Position Window on the Second Monitor (DMD)
pos = get(FigureForShow, 'Position');
WidthOfFig  = pos(3);
HeightOfFig = pos(4);

% Retrieve second monitor coordinates from your helper function
[Monitor2PosX, Monitor2PosY, ~, ~] = secondMonitorInfo;

% Apply offsets specific to the Rockefeller lab setup
targetX = Monitor2PosX - 371; 
targetY = Monitor2PosY - 181; 

% Manual override (uncomment if using a specific fixed workstation)
% targetX = 3470;  
% targetY = -177;  

% Move the figure to the DMD monitor coordinates
set(FigureForShow, 'Position', [targetX, targetY, WidthOfFig, HeightOfFig]);

%% 4. Cleanup Workspace
% Space-separated clear command (no brackets)
clear targetX targetY Height Width WidthOfFig HeightOfFig pos imgHeight imgWidth hAxes Monitor2PosX Monitor2PosY;