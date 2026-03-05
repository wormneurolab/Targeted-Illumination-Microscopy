% This function controls the Sola illumination power, 
% the IlluminationIntensity is a linear representation of intensity, 
% 100 means max, 1 means min

function Sola(IlluminationIntensity)
     %this is a linear representation of intensity, 100 means max, 1 means min
    global Sola
    IntensityinDec = IlluminationIntensity;
    DepthOfIntensity = 256;
    Intensityin256 = floor((IntensityinDec/100)*DepthOfIntensity);
    Intensityin256Inv = 256 - Intensityin256;
    Intensityin256InvHEX = dec2hex(Intensityin256Inv);
    IntensityFirstDigit = sscanf(Intensityin256InvHEX(1), '%s');
    IntensitySecondDigit = sscanf(Intensityin256InvHEX(2), '%s');
    IntensityFirstHex = strcat('F',IntensityFirstDigit);
    IntensitySecondHex = strcat(IntensitySecondDigit,'0');

    fprintf(Sola,'%s',char([hex2dec('53') hex2dec('18') hex2dec('03') hex2dec('04') hex2dec(IntensityFirstHex) hex2dec(IntensitySecondHex) hex2dec('50')])); % Set the intensity acccording to “DAC Intensity Control Command Strings”
end
