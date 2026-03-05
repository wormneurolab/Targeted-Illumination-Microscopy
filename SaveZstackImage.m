function SaveZstackImage(Image, ImageName, BitDepth, ImageDescription)
% SAVEZSTACKIMAGE Saves a 3D matrix (Z-stack) to a multi-page TIFF file.
%
% Usage:
%   SaveZstackImage(myStack, 'sample_01.tif', 16, '60x Oil Immersion, 0.5um step')
%
% Inputs:
%   Image            - 3D matrix (Height x Width x Z-slices)
%   ImageName        - File name/path (must end in .tif or .tiff)
%   BitDepth         - Data depth: 8 or 16
%   ImageDescription - (Optional) Metadata string for the TIFF header

    %% 1. Input Validation & Casting
    if nargin < 4
        ImageDescription = 'MATLAB Acquired Z-stack image';
    end

    % Cast image to the requested bit depth
    if BitDepth == 8
        Image = uint8(Image);
    elseif BitDepth == 16
        Image = uint16(Image);
    else
        error('BitDepth must be either 8 or 16. Other values are not supported.');
    end

    %% 2. Initialize TIFF Object
    % Create Tiff object in write mode
    t = Tiff(ImageName, 'w');
    
    % Define TIFF Tag Structure
    tagstruct.ImageLength     = size(Image, 1);
    tagstruct.ImageWidth      = size(Image, 2);
    tagstruct.Photometric     = Tiff.Photometric.MinIsBlack;
    tagstruct.BitsPerSample   = BitDepth;
    tagstruct.SamplesPerPixel = 1;
    tagstruct.Compression     = Tiff.Compression.None;
    tagstruct.PlanarConfiguration = Tiff.PlanarConfiguration.Chunky;
    tagstruct.Software        = 'MATLAB Microscopy Pipeline'; 
    tagstruct.ImageDescription = ImageDescription;
    
    % Set SampleFormat (1 = Unsigned Integer)
    tagstruct.SampleFormat = Tiff.SampleFormat.UInt;

    %% 3. Write Z-Slices to Directory
    numSlices = size(Image, 3);
    
    for ii = 1:numSlices
        % Apply tags to the current directory (frame)
        setTag(t, tagstruct);
        
        % Write the specific Z-slice
        write(t, Image(:, :, ii));
        
        % If there are more slices, prepare the next directory
        if ii < numSlices
            writeDirectory(t);
        end
    end

    %% 4. Cleanup
    close(t);
    fprintf('Successfully saved %d slices to: %s\n', numSlices, ImageName);
end