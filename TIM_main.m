% Image 1 : Original widefield image
% Mask 1 :Neuf based fiber segmentation combine with intensity inverse mask;
% Image 2 : Intermediate improved image;
% Mask 2: euf based fiber segmentation combine with binary inverse intensity mask;
% Image3: Final TIM Image.

% Performs 3D TIM with a global density threshold
% With the threshold, the code will first generate a mask1 that combine the 
% mask based on the WF Image1 intensity inverse and fiber segmentation on 
% original widefield image.
% Then, it will project the mask1 to SLM/DMD, with set to be the second 
% monitor of the computer. With mask1, we get Image2 and we call it 
% TIMImage2, or intermedate image
% Apply fiber segmentation on Image2, we get a mask2 which can futher 
% improve image quality.
% After proejct Mask 2 on SLM, we get our final TIMImage.
 
% This code uses a Nikon Ti2 inverted microscope, a Hamamatsu BT fusion 
% sCMOS camera, and a commercial projector extracted DMD (digital micromirror device) 
% for performing TIM.se the Hamamatsu Fusion BT camera for acquiring, 
% the resolution of the CMOS camera is 2304*2304.But only part of its FOV
% is used because of the DMD cannot cover the full FOV.


% Author: Yao Wang & Jia Fan
% Email: wang.yao2@northeastern.edu

clc
close all
clear all

%% set camera parameters
SampleName = 'Fish1'; % Give your sample a name
SampleNum = '1';  % give current image an order

ZBottom = 1350; % change the number here, unit is um
ZTop = 1360; % change the number here, unit is um

ZStep = 0.5; % unit is um

Density = 2; % use 2 by default. 2 or 4 work for most neurite imaging

CameraExposureTime=0.05;

LEDIntensityWF = 30; % We use a Lumencor Sola illuminator
LEDIntensityTIM = LEDIntensityWF*2; % 0-100 linear intensity representation of Sola intensity

ObjectiveMag = 60; % choose objective

IniDarkThreshold = 400; % higher than dark floor
IniBrightThreshold = 60000; % lower than camera saturation
ThresholdDecrease = 0.01; % this is the precentage of decreasing per um in depth, as light decreases in deeper tissue

KeepMetaData = 1; % if you want to keep all TIM process data, use 1, if no keep, use 0;

se = strel('square',5); % creates a square structuring element whose width is 5 pixels, to dilate fibers in image

ImageLowLimitForWFShow = 50;
ImageUpLimitForWFShow = 25000;
ImageLowLimitForTIMShow = 50;
ImageUpLimitForTIMShow = 5000;
 
Date = datetime('now','TimeZone','local','Format','yMMd');
DateChar = string(Date);

SampleNumStr = num2str(SampleNum);
SparsityStr = num2str(Density);
ImageNameSec1 = strcat(DateChar,'-3DTIM',SampleName,'-',SampleNumStr,'-Sparse',SparsityStr);

load('HamamatsuROI.mat', 'ROI'); % this ROI of camera is measured before experiment
AOILeft = ROI(1,1);
AOITop = ROI(1,2);
ImageWidth = ROI(1,3);
ImageHeight = ROI(1,4);

CameraDMDRatio = 1.666; % this is a fixed parameter if using the same DMD
Darkcount = 83; % 83 for the CMOS camera

%% show initial white background to SLM
DMDHeight = 800; % this 800*1280 is the DMD resolution we use
DMDWidth = 1280;
IniBackgrImage = uint8(255 * ones(DMDHeight,DMDWidth)); % 
DarkBackgrImage = uint8(zeros(DMDHeight,DMDWidth));
Im=IniBackgrImage;
% BackgroundShow = imshow(Im) %this Im2 is to see how the final image like from camera
FigureForShow = figure('Name','Pattern','NumberTitle','off','color','k');
hAxes = subplot(1,1,1);
set(gcf,'unit','pixel');
set(gcf,'menubar','none');
set(gcf,'colormap',gray);
BackgroundShow = imshow(Im,'Parent',hAxes,'border','loose');
[a, b]= size(Im);
truesize([a b]);
pos = get(gcf, 'Position');
x = 3655;  % if we need to set the figure to a new location from workstation
y = -88;  % if we need to set the figure to a new location from workstation
WidthOfFig = pos(3);
HeightOfFig = pos(4);
set(FigureForShow,'position',[x,y,WidthOfFig,HeightOfFig]); % to maintain the figure size while move it to a new location

%% initialize camera
disp('setting Hamamatsu Camera...')
imaqhwinfo('hamamatsu');

vid = videoinput('hamamatsu', 1, 'MONO16_2304x2304_FastMode');
src = getselectedsource(vid);

vid.ROIPosition = ROI; % set AOI

src.ExposureTime = CameraExposureTime;
vid.FramesPerTrigger = 1;

triggerconfig(vid, 'manual'); % you can also use 'immediate' to replace 'manual'

src.HotPixelCorrectionLevel = 'standard';

vid.LoggingMode = 'memory';
src.TriggerPolarity = 'positive';

disp('Starting acquisition...');
start(vid)

%% Creat data set to facilate later imaging
ZLayerNum = (ZTop - ZBottom)/ZStep + 1;

WideFieldImage1 = uint16(zeros(ImageHeight,ImageWidth,ZLayerNum)); % for speed up later acquisition
TIMImage2 = uint16(zeros(ImageHeight,ImageWidth,ZLayerNum)); % for speed up later acquisition
TIMImageFinal = uint16(zeros(ImageHeight,ImageWidth,ZLayerNum)); % for speed up later acquisition
Mask1 = uint8(zeros(ImageHeight,ImageWidth,ZLayerNum)); % for speed up later acquisition
Mask2 = uint8(zeros(ImageHeight,ImageWidth,ZLayerNum)); % for speed up later acquisition

DMDpattern = zeros(DMDHeight,DMDWidth); 

%% create image visulizing windows for future use
ImageBuf = uint16(zeros(ImageHeight, ImageWidth)); 
FigureForCheck = figure('Name','Live','NumberTitle','off','color','r');

CheckhAxesWF = subplot(1,2,1);
CheckImageWF = imshow(ImageBuf,[ImageLowLimitForWFShow ImageUpLimitForWFShow],'Parent',CheckhAxesWF,'border','tight');
title('Wide Field image')

CheckhAxesTIM = subplot(1,2,2);
CheckImageTIM = imshow(ImageBuf,[ImageLowLimitForTIMShow ImageUpLimitForTIMShow],'Parent',CheckhAxesTIM,'border','tight');
title('TIM image')
impixelinfo

set(FigureForCheck,'position',[500,200,3200,2000]); % to maintain the figure size while move it to a new location

%% Setup Nikon microscope
addpath('C:\Program Files\Nikon\Ti2-SDK\bin'); 
addpath('E:\Yao\Nikon\ScanningPattern');
addpath('E:\Yao\Nikon\AndorSDK3');
!regsvr32 /s NkTi2Ax.dll;
% global ti2;
ti2 = actxserver('Nikon.Ti2.AutoConnectMicroscope');
        
xposition=get(ti2,'iXPOSITION');
yposition=get(ti2,'iYPOSITION');

ti2.iXPOSITIONSpeed=3;
ti2.iYPOSITIONSpeed=3;
ti2.iZPOSITIONSpeed=3;

ti2.iLIGHTPATH=2; % 2 for light to the right camera, 4 for light to left camera
 
ti2.iTURRET2SHUTTER=0;
ti2.iTURRET2POS=1;
ti2.iDIA_LAMP_Switch=0;
ti2.iDIA_LAMP_Pos=0;
ti2.iTURRET1SHUTTER=1;
ti2.iTURRET2POS=1;

switch ObjectiveMag
    case 2
        ti2. iNOSEPIECE=6;
    case 10
        ti2. iNOSEPIECE=2;
    case 20
        ti2. iNOSEPIECE=3;
    case 40
        ti2. iNOSEPIECE=1;
    case 60
        ti2. iNOSEPIECE=5;
end

%% setup the bottom and top layer z coordinates
ZBottomInUnit = ZBottom*100;
ZTopInUnit = ZTop*100;
ZStepInUnit = ZStep*100;

ti2.ZPosition.Value=ZBottomInUnit;
pause(0.2)
ti2.ZPosition.Value=ZBottomInUnit; % to make sure the movement is good

ZOrderNum = 1;

%% Setup LED illumination
disp('Setting up the LEDD1B illumination...')
LEDIntensityTIMForDAQ = (LEDIntensityTIM/100) * 5; %this is a linear representation of intensity, 100 means max, 1 means min
LEDIntensityWFForDAQ = (LEDIntensityWF/100) * 5;
d = daqlist("ni");
dq = daq("ni");
dq.Rate = 24000;
addoutput(dq, "Dev1", "ao0", "Voltage");
write(dq,0);


%% image acquisition
for Zposition = ZBottomInUnit:ZStepInUnit:ZTopInUnit
    tic
    write(dq,LEDIntensityWFForDAQ); % light on
    set(BackgroundShow,'CData',IniBackgrImage); % show initial wide field illumination to SLM
    drawnow
    ti2.ZPosition.Value=ZBottomInUnit+(ZOrderNum-1)*ZStepInUnit;

    DarkThreshold = IniDarkThreshold  * (1-((Zposition-ZBottomInUnit)/100)*ThresholdDecrease); % image intensity is decreasing in deeper depth, thus we change the intensity threshold
    BrightThreshold = IniBrightThreshold  * (1-((Zposition-ZBottomInUnit)/100)*ThresholdDecrease); % image intensity is decreasing in deeper depth, thus we change the intensity threshold

    ti2.ZPosition.Value=ZBottomInUnit+(ZOrderNum-1)*ZStepInUnit; % to make sure the movement is good
    pause(CameraExposureTime+0.1) % wait because of DMD response time
    
    %% get the Image1 and generate intensity inverse combined fiber detector mask1 
    WideFieldImage1(:,:,ZOrderNum) = getsnapshot(vid);% a fake acquire to clean possible wrong camera buff
    WideFieldImage1(:,:,ZOrderNum) = getsnapshot(vid); % acquire the widefield image

%     write(dq,0); % light off
    
    InitialImage = double(WideFieldImage1(:,:,ZOrderNum));
    
    [FibersInImage,EnhancedImage,ImageAngle,ImageRatio,ImageOutNoLocal,ImageOutWithLocal] = NeufRatioLocalSparsityA3(InitialImage, Darkcount, Density); % returns all edges that are stronger than threshold.
    FibersInImageDilated = double(imdilate(FibersInImage,se));
    
    InitialImageThre = InitialImage;
    InitialImageThre(InitialImage<DarkThreshold) = BrightThreshold;
    InitialImageThre(InitialImage>BrightThreshold) = BrightThreshold;
    
    InitialImageUint8 = (InitialImageThre./BrightThreshold)*255;
    
    InitialImageUint8(InitialImageUint8<1) = 1;
    
    InitialImageUint8Inv = floor(255-InitialImageUint8);
    InitialImageUint8Inv = InitialImageUint8Inv+1;
    
    
    Mask1(:,:,ZOrderNum)  = InitialImageUint8Inv .* FibersInImageDilated; % combine the edge detected mask with previous intensity inverse mask
    
    FiberMaskUint8Resize = imresize(Mask1(:,:,ZOrderNum),[DMDHeight DMDWidth],'bilinear');
%     FiberMaskUint8Resize(DMDHeightCrop, DMDWidthCrop);
    FiberMaskUint8ResizeMax = max(FiberMaskUint8Resize(:));
    FiberMask1Uint8Pattern = uint8(floor((FiberMaskUint8Resize/FiberMaskUint8ResizeMax)*255));
    
    set(BackgroundShow,'CData',FiberMask1Uint8Pattern);
    drawnow
    write(dq,LEDIntensityTIMForDAQ); % light for TIM on
%     write(dq,LEDIntensityForDAQ); % light on
    pause(CameraExposureTime+0.1)
    
    %% get an improved intermediate TIM Image2
    TIMImage2(:,:,ZOrderNum) = getsnapshot(vid); % a fake acquire to clean possible wrong camera buff
    TIMImage2(:,:,ZOrderNum) = getsnapshot(vid); % acquire image from the Hamamatsu camera
    
%     write(dq,0); % light off
    
    %% generate a Neuf fiber and intensity inverse combined mask2
    [FibersInImage,EnhancedImage,ImageAngle,ImageRatio,ImageOutNoLocal,ImageOutWithLocal]  = NeufRatioLocalSparsityA3(TIMImage2(:,:,ZOrderNum), Darkcount, Density/2);
    FibersInImageDilated = double(imdilate(FibersInImage,se));
     
    Mask2Buff1  = InitialImageUint8Inv .* FibersInImageDilated; % combine the edge detected mask with previous intensity inverse mask
    Mask2Buff2 = Mask2Buff1;
    Mask2Buff2(Mask2Buff2>2) = 255; % for all those illuminating location, make them bright all the way
    
    Mask2(:,:,ZOrderNum) = Mask2Buff2;
    
    FiberMaskUint8Resize = imresize(Mask2Buff1,[DMDHeight DMDWidth],'bilinear');
%     FiberMaskUint8Resize(DMDHeightCrop, DMDWidthCrop);
    FiberMaskUint8ResizeMax = max(FiberMaskUint8Resize(:));
    FiberMask2Uint8Pattern = uint8(floor((FiberMaskUint8Resize/FiberMaskUint8ResizeMax)*255));
    FiberMask2Uint8Pattern(FiberMask2Uint8Pattern>2) = 255;
    set(BackgroundShow,'CData',FiberMask2Uint8Pattern);
    drawnow
%     write(dq,LEDIntensityForDAQ); % light on
    pause(CameraExposureTime+0.1)
   
    %% get the final TIM Image3
    TIMImageFinal(:,:,ZOrderNum) = getsnapshot(vid); % a fake acquire to clean possible wrong camera buff
    TIMImageFinal(:,:,ZOrderNum) = getsnapshot(vid);
    
    set(CheckImageWF,'CData',WideFieldImage1(:,:,ZOrderNum)); % refresh the WF image to a new one
    set(CheckImageTIM,'CData',TIMImageFinal(:,:,ZOrderNum)); % refresh the TIM image to a new one
    drawnow
%     impixelinfo
    
    ZOrderNum = ZOrderNum+1;
    
    OneSlicePeriod = toc
    SlidesLeft = (ZTopInUnit-ti2.ZPosition.Value)/(ZStepInUnit);
    TimeLeft = num2str(SlidesLeft*OneSlicePeriod+5);
    TimeLeft=strcat('About'," ", TimeLeft,' seconds left until finish');
    disp(TimeLeft)
end

%% post acquisition cleaning
% close the illumination
write(dq,0);
daqreset
disp('DAQ disconnected')

disp('Acquisition complete');
stop(vid);
delete(vid);
disp('Camera shutdown');

pause(1)
close all
 
%% save all images
WFLEDIntensityChar = num2str(LEDIntensityWF);
TIMLEDIntensityChar = num2str(LEDIntensityTIM);
ImageNameSec2WF = strcat('-LED',WFLEDIntensityChar);
ImageNameSec2TIM = strcat('-LED',TIMLEDIntensityChar);
ImageNameSec3 = '.tif';

WF3DImageName = strcat(ImageNameSec1,ImageNameSec2WF,'-Original',ImageNameSec3);
TIMImageName = strcat(ImageNameSec1,ImageNameSec2TIM,'-TIM',ImageNameSec3);
TIMFinalMaskName = strcat(ImageNameSec1,ImageNameSec2TIM,'-FinalMask',ImageNameSec3);
TIMBackgroundZerosName = strcat(ImageNameSec1,ImageNameSec2TIM,'-BackgroundZeros',ImageNameSec3);
ProcessedTIMZStackImageName = strcat(ImageNameSec1,ImageNameSec2TIM,'-ProcessedTIM',ImageNameSec3);
ProcessedTIMZStackImageLogScaleName = strcat(ImageNameSec1,ImageNameSec2TIM,'-ProcessedTIMLogScale',ImageNameSec3);

disp('Saving Original Wide field Z-stack image...');
WideFieldImage1 = uint16(WideFieldImage1);
t = Tiff(WF3DImageName,'w');
tagstruct.ImageLength = size(WideFieldImage1,1);
tagstruct.ImageWidth = size(WideFieldImage1,2);
% tagstruct.SampleFormat = 1; % uint
tagstruct.Photometric = Tiff.Photometric.MinIsBlack;
tagstruct.BitsPerSample = 16;
tagstruct.SamplesPerPixel = 1;
tagstruct.Compression = Tiff.Compression.None;
tagstruct.PlanarConfiguration = Tiff.PlanarConfiguration.Chunky;
tagstruct.Software = 'MATLAB'; 
ImageDescription = strcat('ExposureTime:',num2str(CameraExposureTime),'s;','ZStep:',num2str(abs(ZStep)),'um;','LED:',WFLEDIntensityChar);
tagstruct.ImageDescription = ImageDescription;

for ii=1:size(WideFieldImage1,3)
   setTag(t,tagstruct);
   write(t,WideFieldImage1(:,:,ii));
   writeDirectory(t);
end
close(t)

disp('Saving TIM Z-stack image...');
TIMImageFinal = uint16(TIMImageFinal);
t = Tiff(TIMImageName,'w');
tagstruct.ImageLength = size(TIMImageFinal,1);
tagstruct.ImageWidth = size(TIMImageFinal,2);
% tagstruct.SampleFormat = 1; % uint
tagstruct.Photometric = Tiff.Photometric.MinIsBlack;
tagstruct.BitsPerSample = 16;
tagstruct.SamplesPerPixel = 1;
tagstruct.Compression = Tiff.Compression.None;
tagstruct.PlanarConfiguration = Tiff.PlanarConfiguration.Chunky;
tagstruct.Software = 'MATLAB'; 
ImageDescription = strcat('ExposureTime:',num2str(CameraExposureTime),'s;','ZStep:',num2str(abs(ZStep)),'um;','LED:',TIMLEDIntensityChar);
tagstruct.ImageDescription = ImageDescription;

for ii=1:size(TIMImageFinal,3)
   setTag(t,tagstruct);
   write(t,TIMImageFinal(:,:,ii));
   writeDirectory(t);
end
close(t)

disp('Saving TIM-FinalMask Z-stack image...');
Mask2 = uint8(Mask2);
t = Tiff(TIMFinalMaskName,'w');
tagstruct.ImageLength = size(Mask2,1);
tagstruct.ImageWidth = size(Mask2,2);
% tagstruct.SampleFormat = 1; % uint
tagstruct.Photometric = Tiff.Photometric.MinIsBlack;
tagstruct.BitsPerSample = 8;
tagstruct.SamplesPerPixel = 1;
tagstruct.Compression = Tiff.Compression.None;
tagstruct.PlanarConfiguration = Tiff.PlanarConfiguration.Chunky;
tagstruct.Software = 'MATLAB'; 
ImageDescription = strcat('ZStep:',num2str(abs(ZStep)),'um');
tagstruct.ImageDescription = ImageDescription;

for ii=1:size(Mask2,3)
   setTag(t,tagstruct);
   write(t,Mask2(:,:,ii));
   writeDirectory(t);
end
close(t)

if KeepMetaData == 1
    TIMImage2Name = strcat(ImageNameSec1,ImageNameSec2WF,'-MetaTIMImage2',ImageNameSec3);
    %TIMImage3Name = strcat(ImageNameSec1,ImageNameSec2,'-MetaTIMImage3',ImageNameSec3);
    Mask1Name = strcat(ImageNameSec1,ImageNameSec2WF,'-Mask1',ImageNameSec3);
    %Mask2Name = strcat(ImageNameSec1,ImageNameSec2,'-Mask2',ImageNameSec3);
    
    disp('Saving Meta TIM-Image2 Z-stack...');
%     TIMImage2  = rot90(TIMImage2,-1);
    t = Tiff(TIMImage2Name,'w');
    tagstruct.ImageLength = size(TIMImage2,1);
    tagstruct.ImageWidth = size(TIMImage2,2);
    % tagstruct.SampleFormat = 1; % uint
    tagstruct.Photometric = Tiff.Photometric.MinIsBlack;
    tagstruct.BitsPerSample = 16;
    tagstruct.SamplesPerPixel = 1;
    tagstruct.Compression = Tiff.Compression.None;
    tagstruct.PlanarConfiguration = Tiff.PlanarConfiguration.Chunky;
    tagstruct.Software = 'MATLAB';  
    ImageDescription = strcat('ExposureTime:',num2str(CameraExposureTime),'s;','ZStep:',num2str(abs(ZStep)),'um;','LED:',TIMLEDIntensityChar);
    tagstruct.ImageDescription = ImageDescription;

    for ii=1:size(TIMImage2,3)
       setTag(t,tagstruct);
       write(t,TIMImage2(:,:,ii));
       writeDirectory(t);
    end
    close(t)
    
    
    disp('Saving TIM Mask1 Z-stack image...');
    Mask1 = uint8(Mask1);
    t = Tiff(Mask1Name,'w');
    tagstruct.ImageLength = size(Mask1,1);
    tagstruct.ImageWidth = size(Mask1,2);
    % tagstruct.SampleFormat = 1; % uint
    tagstruct.Photometric = Tiff.Photometric.MinIsBlack;
    tagstruct.BitsPerSample = 8;
    tagstruct.SamplesPerPixel = 1;
    tagstruct.Compression = Tiff.Compression.None;
    tagstruct.PlanarConfiguration = Tiff.PlanarConfiguration.Chunky;
    tagstruct.Software = 'MATLAB'; 
    ImageDescription = strcat('ZStep:',num2str(abs(ZStep)),'um');
    tagstruct.ImageDescription = ImageDescription;

    for ii=1:size(Mask1,3)
       setTag(t,tagstruct);
       write(t,Mask1(:,:,ii));
       writeDirectory(t);
    end
    close(t)
end

disp('All Done! Enjoy TIM image!');
