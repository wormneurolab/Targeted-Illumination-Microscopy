% =========================================================================
% ShowOutlineToDLiDMD.m (Inverted Mode)
% 
% Purpose: Generates a calibration pattern with an inverted (white background)
% display, featuring dual-line crosshairs and reference markers for 
% precision SLM/DMD alignment.
% =========================================================================

%% 1. Define DMD Dimensions
Width  = 2560; 
Height = 1600;
Image  = zeros(Height, Width, 'uint8');

%% 2. Matrix Geometry for Outline
centerY = Height/2 + 1; % "C" reference
centerX = Width/2 + 1;  % "D" reference

% Define specific column margins
StartCol = 288;
EndCol   = Width - StartCol + 1;

%% 3. Generate Pattern Features (Black on White logic)
% --- Boundary Box ---
Image(1, StartCol:EndCol)      = 255;
Image(Height, StartCol:EndCol) = 255;
Image(:, StartCol)             = 255;
Image(:, Width - StartCol)     = 255;

% --- Dual-Line Horizontal Crosshair ---
Image(round(centerY - 3), StartCol:EndCol) = 255;
Image(round(centerY + 2), StartCol:EndCol) = 255;

% --- Dual-Line Vertical Crosshair ---
Image(:, round(centerX - 3)) = 255;
Image(:, round(centerX + 3)) = 255;

% --- Reference Markers ---
Image(150:200, 300:350) = 255; % Orientation Block
Image(400:420, 700:720) = 255; % Rotation Reference Dot

%% 4. Invert and Display
% Inverting to create black lines on a white background
Im = 255 - Image;

FigureForShow = figure('Name', 'OutlinePattern', 'Color', 'w', ...
                       'Units', 'pixels', 'MenuBar', 'none', ...
                       'NumberTitle', 'off', 'Colormap', gray);

hAxes = subplot(1, 1, 1);
imshow(Im, 'Parent', hAxes, 'Border', 'loose');

% Enforce 1:1 pixel mapping
[imgHeight, imgWidth] = size(Image);
truesize(FigureForShow, [imgHeight, imgWidth]);

%% 5. Coordinate Mapping (Second Monitor)
% Retrieve current figure size
pos = get(FigureForShow, 'Position');
WidthOfFig  = pos(3);
HeightOfFig = pos(4);

% Get monitor info and apply lab-specific offsets
[Monitor2PosX, Monitor2PosY, ~, ~] = secondMonitorInfo;
targetX = Monitor2PosX - 371; 
targetY = Monitor2PosY - 181; 

% Shift window to the DMD display
set(FigureForShow, 'Position', [targetX, targetY, WidthOfFig, HeightOfFig]);

%% 6. Workspace Cleanup
clear centerX centerY StartCol EndCol Width Height WidthOfFig HeightOfFig pos targetX targetY imgHeight imgWidth hAxes;