% This function disconnects the Lumencor Sola illuminator 

function SolaOff
    global Sola
    fprintf(Sola,'%s',char([hex2dec('4F') hex2dec('7F') hex2dec('50')])); %turn light output OFF
    fclose(Sola) % disconnect COM4
    clear Sola
end