% =========================================================================
% 3D Targeted Illumination Microscopy (TIM) Pipeline
%
% Workflow per Z-layer:
% 1. Move Z-stage & apply depth-dependent threshold decay.
% 2. Acquire Widefield (WF) -> Generate Mask 1.
% 3. Project Mask 1 -> Acquire Intermediate TIM 2 -> Generate Mask 2.
% 4. Project Mask 2 -> Acquire Final TIM Image.
% =========================================================================

clc; close all; clearvars;

%% 1. Experimental Parameters
SampleName = 'BOS152';
SampleNum  = '1c';  
CameraExposureTime = 0.1; % Seconds

ZBottom = 1932; % Start depth (um)
ZTop    = 1934; % End depth (um)
ZStep   = 0.5;  % Step size (um)

ObjectiveMag    = 60; 
LEDIntensityWF  = 2;
LEDIntensityTIM = LEDIntensityWF * 2; 
Density         = 2; % Target fiber density (%)

% Processing Parameters
KeepMetaData       = 1; 
IniDarkThreshold   = 400; 
IniBrightThreshold = 60000;
ThresholdDecrease  = 0.01; % Percentage decrease per um in depth
se = strel('square', 5);
Darkcount = 1; % Hamamatsu specific

%% 2. Paths, Hardware Init, and File Naming
addpath('C:\Program Files\Nikon\Ti2-SDK\bin'); 
addpath('E:\Yao\Nikon\ScanningPattern');

load('HamamatsuROI.mat', 'ROI');
DateStr = string(datetime('now','Format','yMMd'));
BaseName = sprintf('%s-3DTIM-%s-%s-Density%0.1f', DateStr, SampleName, num2str(SampleNum), Density);

ImageWidth = ROI(3);
ImageHeight = ROI(4);
ImageAspectRatio = ImageWidth / ImageHeight;
NominalImageHeight = 1868;
RatioH = ImageHeight / NominalImageHeight;

%% 3. Pre-allocate 3D Data Matrices
% Use round() to prevent floating point dimension mismatch
ZLayerNum = round((ZTop - ZBottom) / ZStep) + 1;

WideFieldImage1 = zeros(ImageHeight, ImageWidth, ZLayerNum, 'uint16'); 
TIMImage2       = zeros(ImageHeight, ImageWidth, ZLayerNum, 'uint16'); 
TIMImageFinal   = zeros(ImageHeight, ImageWidth, ZLayerNum, 'uint16'); 
Mask1           = zeros(ImageHeight, ImageWidth, ZLayerNum, 'uint8'); 
Mask2           = zeros(ImageHeight, ImageWidth, ZLayerNum, 'uint8'); 

%% 4. DMD Setup
DMDHeight = 1600; 
DMDWidth  = 2560;
IniBackgrImage  = repmat(uint8(255), DMDHeight, DMDWidth);
DarkBackgrImage = zeros(DMDHeight, DMDWidth, 'uint8');

FigureForShow = figure('Name','Pattern','NumberTitle','off','color','w'); % if DMD is inversed, use color w, if not, use color k
hAxes = subplot(1,1,1);
set(gcf,'unit','pixel');
set(gcf,'menubar','none');
set(gcf,'colormap',gray);
BackgroundShow = imshow(DarkBackgrImage,'Parent',hAxes,'border','loose');
[a, b]= size(DarkBackgrImage);
truesize([a b]);
pos = get(gcf, 'Position');
[Monitor2PosX, Monitor2PosY, Monitor2width, Monitor2Height] = secondMonitorInfo;

x=Monitor2PosX-371; % set the location of the outline picture showing, from the very left of first monitor to the very left of the Fig window left edge
y=Monitor2PosY-181; % set the location of the outline picture showing, from the very bottom of first monitor to the very bottom of the Fig window bottom edge

%x = 3470;  % if we need to set the figure to a new location from workstation
%y = -177;  % if we need to set the figure to a new location from workstation
WidthOfFig = pos(3);
HeightOfFig = pos(4);
set(FigureForShow,'position',[x,y,WidthOfFig,HeightOfFig]); % to maintain the figure size while move it to a new location


%% 5. Camera & UI Setup
disp('Initializing Hamamatsu Camera...');
vid = videoinput('hamamatsu', 1, 'MONO16_2304x2304_FastMode');
src = getselectedsource(vid);
vid.ROIPosition = ROI;
src.ExposureTime = CameraExposureTime;
triggerconfig(vid, 'immediate');
start(vid);

FigureForCheck = figure('Name', 'Live Preview', 'Position', [500, 200, 1600, 800]);
subplot(1, 2, 1); hWF  = imshow(zeros(ImageHeight, ImageWidth, 'uint16'), [50 25000]); title('Widefield');
subplot(1, 2, 2); hTIM = imshow(zeros(ImageHeight, ImageWidth, 'uint16'), [50 5000]);  title('TIM Result');

%% 6. Nikon Ti2 Setup
!regsvr32 /s NkTi2Ax.dll;
ti2 = actxserver('Nikon.Ti2.AutoConnectMicroscope');
ti2.iLIGHTPATH = 2; 

% Objective mapping
objMap = [2, 6; 10, 2; 20, 3; 40, 1; 60, 5];
ti2.iNOSEPIECE = objMap(find(objMap(:,1) == ObjectiveMag), 2);

ZBottomInUnit = ZBottom * 100; 
ZTopInUnit    = ZTop * 100;
ZStepInUnit   = ZStep * 100;

ti2.ZPosition.Value = ZBottomInUnit;
pause(0.2);

%% 7. 3D Z-Stack Acquisition Loop
disp('Setting up Sola illumination...');
SolaOn;
ZOrderNum = 1;

for Zposition = ZBottomInUnit:ZStepInUnit:ZTopInUnit
    tic;  
    
    % Step A: Move Z and Setup Widefield
    Sola(LEDIntensityWF); 
    set(BackgroundShow, 'CData', 255 - IniBackgrImage); 
    drawnow;
    
    ti2.ZPosition.Value = Zposition;
    
    % Depth-dependent threshold calculation
    depthOffset = (Zposition - ZBottomInUnit) / 100;
    DarkThreshold   = IniDarkThreshold   * (1 - depthOffset * ThresholdDecrease); 
    BrightThreshold = IniBrightThreshold * (1 - depthOffset * ThresholdDecrease); 
    
    pause(CameraExposureTime + 0.05); 
    
    % Step B: Acquire WF & Generate Mask 1
    flushdata(vid);
    WideFieldImage1(:,:,ZOrderNum) = getsnapshot(vid);
    InitialImage = double(WideFieldImage1(:,:,ZOrderNum));
    
    Sola(LEDIntensityTIM); 

    Fibers = NeufRatioLocalDensity(InitialImage, Darkcount, Density); 
    FibersDilated = imdilate(Fibers, se);
    
    ImgThres = InitialImage;
    ImgThres(ImgThres < DarkThreshold)   = BrightThreshold;
    ImgThres(ImgThres > BrightThreshold) = BrightThreshold;
    ImgInv = floor(255 - ((ImgThres ./ BrightThreshold) * 255)) + 1;
    
    Mask1(:,:,ZOrderNum) = ImgInv .* double(FibersDilated); 
    
    P1 = prepareDMDMask(Mask1(:,:,ZOrderNum), DMDHeight, DMDWidth, RatioH, ImageAspectRatio, DarkBackgrImage);
    set(BackgroundShow, 'CData', P1);
    drawnow;

    pause(CameraExposureTime + 0.1);
    
    % Step C: Acquire TIM 2 & Generate Mask 2
    flushdata(vid);

    TIMImage2(:,:,ZOrderNum) = getsnapshot(vid);
    
    Fibers2 = NeufRatioLocalDensity(double(TIMImage2(:,:,ZOrderNum)), Darkcount, Density/2);
    Mask2Buff1 = ImgInv .* double(imdilate(Fibers2, se)); 
    
    Mask2Display = Mask2Buff1;
    Mask2Display(Mask2Display > 2) = 255; 
    Mask2(:,:,ZOrderNum) = Mask2Display;
    
    P2 = prepareDMDMask(Mask2Buff1, DMDHeight, DMDWidth, RatioH, ImageAspectRatio, DarkBackgrImage);
    set(BackgroundShow, 'CData', P2);
    drawnow;
    pause(CameraExposureTime + 0.1);
   
    % Step D: Acquire Final TIM Image
    flushdata(vid);
    TIMImageFinal(:,:,ZOrderNum) = getsnapshot(vid);
    
    % Update UI
    set(hWF, 'CData', WideFieldImage1(:,:,ZOrderNum)); 
    set(hTIM, 'CData', TIMImageFinal(:,:,ZOrderNum)); 
    drawnow; 
    
    % Timing and Progress
    OneSlicePeriod = toc;
    SlidesLeft = (ZTopInUnit - ti2.ZPosition.Value) / ZStepInUnit;
    fprintf('Layer %d Complete. Estimated time remaining: %.1f seconds\n', ZOrderNum, SlidesLeft * OneSlicePeriod);
    
    ZOrderNum = ZOrderNum + 1;
end

%% 8. Hardware Shutdown
SolaOff; stop(vid); delete(vid);
ti2.release; 
close all;
disp('Acquisition complete. Hardware released safely.');

%% 9. Save Data
saveDesc = sprintf('ExpTime:%.2fs; ZStep:%.2fum; Sola:', CameraExposureTime, ZStep);

fprintf('Saving Widefield Z-stack...\n');
SaveZstackImage(WideFieldImage1, [BaseName, '-WF.tif'], 16, [saveDesc, num2str(LEDIntensityWF)]);

fprintf('Saving Final TIM Z-stack...\n');
SaveZstackImage(TIMImageFinal, [BaseName, '-TIM.tif'], 16, [saveDesc, num2str(LEDIntensityTIM)]);

fprintf('Saving Final Mask Z-stack...\n');
SaveZstackImage(Mask2, [BaseName, '-FinalMask.tif'], 8, sprintf('ZStep:%.2fum', ZStep));

if KeepMetaData
    fprintf('Saving Metadata...\n');
    SaveZstackImage(TIMImage2, [BaseName, '-MetaTIMImage2.tif'], 16, [saveDesc, num2str(LEDIntensityTIM)]);
    SaveZstackImage(Mask1, [BaseName, '-Mask1.tif'], 8, sprintf('ZStep:%.2fum', ZStep));
end

disp('All Done! Z-Stacks saved successfully.');

%% --- Helper Functions ---

function pattern = prepareDMDMask(mask, dmdH, dmdW, ratioH, aspect, bgImage)
    % Resizes, centers, and flips the mask for the DMD hardware
    resized = imresize(mask, [dmdH * ratioH, dmdH * aspect * ratioH], 'bilinear');
    scaled = uint8(floor((resized / max(resized(:) + eps)) * 255));
    pattern = flip(255 - centerSmallMatrix(scaled, bgImage), 1);
end