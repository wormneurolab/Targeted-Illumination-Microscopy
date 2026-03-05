% This function connects the Lumencor Sola illuminator 
% Note that you must use the SolaOff function after you finish illumination
% in your script

function SolaOn
    global Sola
    Sola = serial('COM4'); %creat the serial COM4 for communicate with light engine

    fopen(Sola); % active this COM port

    fprintf(Sola,'%s',char([hex2dec('57') hex2dec('02') hex2dec('FF') hex2dec('50')]));  % Initialization of light engine
    fprintf(Sola,'%s',char([hex2dec('57') hex2dec('03') hex2dec('FD') hex2dec('50')]));  % Initialization of light engine

    % disp('Sola connected!!!' );
    fprintf(Sola,'%s',char([hex2dec('4F') hex2dec('7D') hex2dec('50')])); %turn light output ON
end