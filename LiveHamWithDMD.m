% =========================================================================
% Microscope Control & Live Imaging Script
% 
% Purposes:
% 1. Live imaging of samples (with option to save the image)
% 2. Align Spatial Light Modulator (SLM) / DMD for proper positioning/rotation
% 3. Generate a laser spot mark on screen for easy laser shooting targeting
%
% Author: Yao Wang
% Email: wang.yao2@northeastern.edu
%
% Hardware:
% - Camera: Hamamatsu Fusion BT (2304x2304)
% - Illumination: Lumencor Sola or Thorlabs LED
% - Microscope: Nikon Ti2
% =========================================================================

clc;
close all;
clearvars; % 'clearvars' is safer and more efficient than 'clear all'

%% 1. Workspace & Path Setup
workDir = 'E:\Yao\Nikon';
cd(workDir);
addpath(workDir);
addpath('C:\Program Files\Nikon\Ti2-SDK\bin'); % Nikon microscope SDK
addpath('E:\Yao\Nikon\ScanningPattern');       % Scanning pattern location


%% 2. General Parameters
CameraExposureTime = 0.1; % Exposure time in seconds
ImageLowLimitForShow = 100; % Lower limit for contrast
ImageName = '20241111-WF-BOS121-Sola20-2a.tif'; 

AlignMode = 1; % 1: DMD alignment mode, 0: Real imaging (saves image)
IlluminationSource = 1; % 1: Lumencor Sola, 2: Thorlabs LED
LEDOn = 1; % 1: LED on, 0: LED off

LaserMode = 0; % 1: Laser overlay on, 0: Off
LaserPosX = 988; % Laser X coordinate (used if LaserMode == 1)
LaserPosY = 1098; % Laser Y coordinate (used if LaserMode == 1)
LaserShootMarkSize = 13; % Crosshair size for laser spot

NeedImageEnhancement = 1; % 1: Use neuron fiber enhancement filter, 0: Original widefield
FiberThickness = 5; % Parameter for image enhancement filter
DMDOpticalInvert = 1; % 0: DMD normal, 1: DMD inverted

%% 3. Mode-Specific Configurations
if AlignMode == 1
    ImageUpLimitForShow = 25000; 
    CaptureIt = 1; 
    LEDIntensity = 2; % 0-100 linear representation
    ObjectiveMag = 60; % Options: 2, 10, 20, 40, 60 (60x is oil immersion)
    CrossAlignNeed = 0; 
else % AlignMode == 0
    ImageUpLimitForShow = 7000; 
    CaptureIt = 1; 
    LEDIntensity = 1; 
    ObjectiveMag = 60; 
    CrossAlignNeed = 0; % Assumed 0 for normal imaging, adjust if needed
end

%% --- CRITICAL HARDWARE SETTINGS (Do Not Change Below) ---
UseAOI = 1;
% ImageWidth = 500; % smaller FOV for activity tracking
% ImageHeight = 500; % smaller FOV for activity tracking
ImageWidth = 2304; % camera pixel numbers to match our DMD
ImageHeight = 1868; % camera pixel numbers to match our DMD
ImageOffsetX = (2304 - ImageWidth) / 2;
ImageOffsetY = (2304 - ImageHeight) / 2;

% ROI configuration for DLi9000 DMD [Left, Top, Width, Height]
ROI = [ImageOffsetX, ImageOffsetY, ImageWidth, ImageHeight];   
save('HamamatsuROI.mat', 'ROI');

% DMD display initializations
ShowOutlineToDLiDMD; % Figure for DMD alignment
if DMDOpticalInvert == 0
    ShowWhiteToDLiDMD; % Used for laser shooting and wide field image
else
    ShowDarkToDLiDMD;
end

%% 4. Initialize Camera
disp('Setting up Hamamatsu Camera...');
imaqhwinfo('hamamatsu');
imageFormat = 'MONO16_2304x2304_FastMode';
vid = videoinput('hamamatsu', 1, imageFormat);
src = getselectedsource(vid);

% Apply Camera Settings
vid.ROIPosition = ROI; 
src.ExposureTime = CameraExposureTime;
vid.FramesPerTrigger = 1;
triggerconfig(vid, 'manual'); 
src.HotPixelCorrectionLevel = 'standard';
vid.LoggingMode = 'memory';
src.TriggerPolarity = 'positive';

disp('Starting acquisition...');
start(vid);

%% 5. Setup Live Viewing UI
CenterLinesLeft = ImageWidth/2 - 1;
CenterLinesRight = ImageWidth/2 + 2;
CenterLinesUp = ImageHeight/2 - 1;
CenterLinesDown = ImageHeight/2 + 2;

ImageBuf = uint16(zeros(ImageHeight, ImageWidth)); 
FigureForCheck = figure('Name', 'Live', 'NumberTitle', 'off', 'Color', 'r'); 

if NeedImageEnhancement == 0
    % Standard UI Setup
    set(FigureForCheck, 'Position', [600, 200, ImageWidth*1.2, ImageHeight*1.2]);
    h = imshow(ImageBuf, [ImageLowLimitForShow, ImageUpLimitForShow]);
    impixelinfo;
    hold on;
    
    % Draw SLM Alignment Crosshairs (Drawn ONCE to save memory)
    line([CenterLinesLeft-1000 CenterLinesLeft-600],[CenterLinesUp CenterLinesUp], 'Color', 'b'); 
    line([CenterLinesLeft-500 CenterLinesLeft-400],[CenterLinesUp CenterLinesUp], 'Color', 'b');
    line([CenterLinesLeft-300 CenterLinesLeft-200],[CenterLinesUp CenterLinesUp], 'Color', 'b');
    line([CenterLinesLeft-100 CenterLinesRight+100],[CenterLinesUp CenterLinesUp], 'Color', 'b'); 
    line([CenterLinesRight+200 CenterLinesRight+300],[CenterLinesUp CenterLinesUp], 'Color', 'b'); 
    line([CenterLinesRight+400 CenterLinesRight+500],[CenterLinesUp CenterLinesUp], 'Color', 'b'); 
    line([CenterLinesRight+600 CenterLinesRight+1000],[CenterLinesUp CenterLinesUp], 'Color', 'b'); 
    line([CenterLinesLeft-1000 CenterLinesLeft-600],[CenterLinesDown CenterLinesDown], 'Color', 'b'); 
    line([CenterLinesLeft-500 CenterLinesLeft-400],[CenterLinesDown CenterLinesDown], 'Color', 'b');
    line([CenterLinesLeft-300 CenterLinesLeft-200],[CenterLinesDown CenterLinesDown], 'Color', 'b');
    line([CenterLinesLeft-100 CenterLinesRight+100],[CenterLinesDown CenterLinesDown], 'Color', 'b'); 
    line([CenterLinesRight+200 CenterLinesRight+300],[CenterLinesDown CenterLinesDown], 'Color', 'b'); 
    line([CenterLinesRight+400 CenterLinesRight+500],[CenterLinesDown CenterLinesDown], 'Color', 'b'); 
    line([CenterLinesRight+600 CenterLinesRight+1000],[CenterLinesDown CenterLinesDown], 'Color', 'b'); 
    line([CenterLinesLeft CenterLinesLeft],[CenterLinesUp-1000 CenterLinesUp-600], 'Color', 'b');
    line([CenterLinesLeft CenterLinesLeft],[CenterLinesUp-500 CenterLinesUp-400], 'Color', 'b');
    line([CenterLinesLeft CenterLinesLeft],[CenterLinesUp-300 CenterLinesUp-200], 'Color', 'b');
    line([CenterLinesLeft CenterLinesLeft],[CenterLinesUp-100 CenterLinesDown+100], 'Color', 'b');
    line([CenterLinesLeft CenterLinesLeft],[CenterLinesDown+200 CenterLinesDown+300], 'Color', 'b');
    line([CenterLinesLeft CenterLinesLeft],[CenterLinesDown+400 CenterLinesDown+500], 'Color', 'b');
    line([CenterLinesLeft CenterLinesLeft],[CenterLinesDown+600 CenterLinesDown+1000], 'Color', 'b');
    line([CenterLinesRight CenterLinesRight],[CenterLinesUp-1000 CenterLinesUp-600], 'Color', 'b');
    line([CenterLinesRight CenterLinesRight],[CenterLinesUp-500 CenterLinesUp-400], 'Color', 'b');
    line([CenterLinesRight CenterLinesRight],[CenterLinesUp-300 CenterLinesUp-200], 'Color', 'b');
    line([CenterLinesRight CenterLinesRight],[CenterLinesUp-100 CenterLinesDown+100], 'Color', 'b');
    line([CenterLinesRight CenterLinesRight],[CenterLinesDown+200 CenterLinesDown+300], 'Color', 'b');
    line([CenterLinesRight CenterLinesRight],[CenterLinesDown+400 CenterLinesDown+500], 'Color', 'b');
    line([CenterLinesRight CenterLinesRight],[CenterLinesDown+600 CenterLinesDown+1000], 'Color', 'b');

    if LaserMode == 1
        % Draw Laser Crosshairs
        line([LaserPosX-LaserShootMarkSize LaserPosX+LaserShootMarkSize],[LaserPosY LaserPosY], 'Color', 'r'); 
        line([LaserPosX LaserPosX],[LaserPosY-LaserShootMarkSize LaserPosY+LaserShootMarkSize], 'Color', 'r'); 
    end
    hold off;
else
    % Image Enhancement UI Setup (Side-by-side view)
    set(FigureForCheck, 'Position', [300, 60, 1600, 800]); 
    
    ax1 = subplot(1, 2, 1);
    h(1) = imshow(ImageBuf, [ImageLowLimitForShow ImageUpLimitForShow], 'Parent', ax1, 'Border', 'tight');
    title('Original Widefield Image');
    hold on;
    if LaserMode == 1
        line([LaserPosX-LaserShootMarkSize LaserPosX+LaserShootMarkSize],[LaserPosY LaserPosY], 'Color', 'r'); 
        line([LaserPosX LaserPosX],[LaserPosY-LaserShootMarkSize LaserPosY+LaserShootMarkSize], 'Color', 'r'); 
    end
    hold off;
    
    ax2 = subplot(1, 2, 2);
    h(2) = imshow(ImageBuf, [0 ImageUpLimitForShow*8], 'Parent', ax2, 'Border', 'tight');
    title('Enhanced Widefield Image');
    hold on;
    if LaserMode == 1
        line([LaserPosX-LaserShootMarkSize LaserPosX+LaserShootMarkSize],[LaserPosY LaserPosY], 'Color', 'r'); 
        line([LaserPosX LaserPosX],[LaserPosY-LaserShootMarkSize LaserPosY+LaserShootMarkSize], 'Color', 'r'); 
    end
    hold off;

    impixelinfo;
    linkaxes([ax1 ax2], 'xy');
end

%% 6. Setup Nikon Ti2 Microscope
disp('Connecting to Nikon Ti2...');
!regsvr32 /s NkTi2Ax.dll;
ti2 = actxserver('Nikon.Ti2.AutoConnectMicroscope');
        
ti2.iXPOSITIONSpeed = 3;
ti2.iYPOSITIONSpeed = 3;
ti2.iZPOSITIONSpeed = 3;
ti2.iLIGHTPATH = 2; % 2: right camera, 4: left camera
ti2.iTURRET2SHUTTER = 0;
ti2.iTURRET2POS = 1;
ti2.iDIA_LAMP_Switch = 0;
ti2.iDIA_LAMP_Pos = 0;
ti2.iTURRET1SHUTTER = 1;
ti2.iTURRET1POS = 1;

switch ObjectiveMag
    case 2,  ti2.iNOSEPIECE = 6;
    case 10, ti2.iNOSEPIECE = 2;
    case 20, ti2.iNOSEPIECE = 3;
    case 40, ti2.iNOSEPIECE = 1;
    case 60, ti2.iNOSEPIECE = 5;
end

%% 7. Setup LED Illumination
if LEDOn == 1
    if IlluminationSource == 1
        disp('Setting up Sola illumination...');
        SolaOn;
        Sola(LEDIntensity);
    elseif IlluminationSource == 2
        disp('Setting up DAQ LEDD1B illumination...');
        LEDIntensityForDAQ = (LEDIntensity / 100) * 5; % Linear conversion to voltage (max 5V)
        dq = daq("ni");
        dq.Rate = 24000;
        addoutput(dq, "Dev1", "ao0", "Voltage");
        write(dq, LEDIntensityForDAQ);
    end
end

%% 8. Alignment / Image Acquisition Loop
if NeedImageEnhancement == 0
    set(FigureForCheck, 'Position', [600, 10, ImageWidth*1.1, ImageHeight*1.1]);
end

if CrossAlignNeed == 1
    % Setup Cross Profile alignment graphs
    FigureForCrossProfile = figure('Name', 'AlignmentProfile', 'NumberTitle', 'off', 'Color', 'g'); 
    set(FigureForCrossProfile, 'Position', [2000, 50, 1400, 400]);
    XForPlot = 1:20;
    
    CrossX = subplot(1, 2, 1);
    CrossPlot(1) = plot(XForPlot, zeros(1,20), 'r');
    xlim([1, 20]); ylim([0, 1.2]); xticks(1:2:20);
    title('Alignment in X direction');
    
    CrossY = subplot(1, 2, 2);
    CrossPlot(2) = plot(XForPlot, zeros(1,20), 'r');
    xlim([1, 20]); ylim([0, 1.2]); xticks(1:2:20);
    title('Alignment in Y direction');
end

% === MAIN LIVE LOOP ===
disp('Entering Live View... Close the figure window to stop.');

if NeedImageEnhancement == 0
    % Standard Display Loop
    while ishandle(h)
        ImageBuf = getsnapshot(vid);
        if ishandle(h)
            set(h,'CData',ImageBuf);
            drawnow;
        end
        if CrossAlignNeed == 1              
            CrossXdirection = double(ImageBuf(ImageHeight/2 - 50, ImageWidth/2-9:ImageWidth/2+10));
            CrossXdirectionNormal = CrossXdirection(:) / max(CrossXdirection(:));
        
            CrossYdirection = double(ImageBuf(ImageHeight/2-9:ImageHeight/2+10, ImageWidth/2-50));
            CrossYdirectionNormal = CrossYdirection(:) / max(CrossYdirection(:));
            
            CrossPlot(1).YData = CrossXdirectionNormal;
            CrossPlot(2).YData = CrossYdirectionNormal;
        end
        drawnow;
    end
else
    % Enhanced Display Loop (Filters applied live)
    FiberFilter = [-1*ones(FiberThickness) 2*ones(FiberThickness) -1*ones(FiberThickness)]; 
    
    while ishandle(h(1)) || ishandle(h(2))
        ImageBuf = getsnapshot(vid);
        if ishandle(h(1))
            set(h(1),'CData',ImageBuf);
            drawnow;
        end
        
        % Apply directional filtering
        buf2EnhancedX = double(imfilter(ImageBuf, FiberFilter, 'replicate'));
        buf2EnhancedY = double(imfilter(ImageBuf, FiberFilter', 'replicate'));
        buf2EnhancedX(buf2EnhancedX < 0) = 0;
        buf2EnhancedY(buf2EnhancedY < 0) = 0;
        buf2Enhanced = sqrt(buf2EnhancedX.^2 + buf2EnhancedY.^2);
        
        if ishandle(h(2))
            set(h(2), 'CData', buf2Enhanced);
            drawnow;
        end
    end
end

%% 9. Hardware Shutdown & Cleanup
close all;

% Turn off illumination
if LEDOn == 1 
    if IlluminationSource == 1
        SolaOff;
        disp('Sola illumination disconnected.');
    elseif IlluminationSource == 2
        write(dq, 0);
        daqreset;
        disp('DAQ LED disconnected.');
    end
end

% Save the 2D image
if CaptureIt == 1
    imwrite(ImageBuf, ImageName);
    disp(['Image saved as ', ImageName]);
end

% Disconnect Camera & Microscope
stop(vid);
delete(vid);
disp('Camera Disconnected.');

zposition = get(ti2, 'iZPOSITION');
xposition = get(ti2, 'iXPOSITION');
yposition = get(ti2, 'iYPOSITION');

% Synchronize UI positions back to scope (if applicable to your SDK wrapper)
try
    ti2.ZPosition.Value = zposition;
    ti2.XPosition.Value = xposition;
    ti2.YPosition.Value = yposition;
catch
    % Failsafe in case exact property names vary by SDK version
end

save('Position.mat', 'zposition', 'xposition', 'yposition');
disp('Acquisition complete. Positions saved.');