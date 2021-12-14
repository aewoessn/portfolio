function [stitchedImage] = imageStitch(varargin)
% [stitchedImage] = imageStitch(imageStack,coordinateContainingMetadata,kwargs,args)
%
% Description: Stitch and blend images together to some capacity, using some sort
% of image metadata with or without correlation. Note: Images spanning a
% large area may result in memory errors.
%
% Required Inputs:
%   
%   imageStack - 3D stack of images, in the order they were taken such that
%       they correctly line up with the metadata. These can be any type of
%       image variable.
%
%   coordinateContainingMetadata - Can take two forms:
%       XML file - Some XML file that contains the image positions
%           somewhere. Needs to be of type struct, which can be obtainined
%           using the 'xml2struct.m' function.
%       Matrix - Nx2 matrix, where N equals the number of images in input
%           stack. 
%
% Supported kwargs (comma-separated,incased in quotes) and values:
%
%   'alpha' - Amount of blending used during the stitching process. 1 (default) is
%       equivalent to linear blending. < || > 0 is equivalent to nonlinear
%       blending. 0 is equivalent to no blending.
%
%   'beta' - Value ranging from 0 to 1, representing max amount of single image translation (if any),
%       due to correlation allowed. Correlation is done using an NCC method with the previous image in the stack. 0 (default) represents no allowed
%       correlation. 0.5 represents correlation is allowed to move a max pixel amount of 50% of the original
%       image size. 
%
%   'betaMag' - Value ranging from 0 to 1, representing the lower bound of
%       correlation. If the max correlation is less that betaMag, then the
%       image will not move. Defualt is 0.5.
%   
%   'verbose' - Renders figure showing image stitching and blending during process.
%       Either 'on' or 'off' (default).
%
% Technical Note:
%   When an RGB image is desired, just run this function three times and
%   assign the output to a slice of an RGB stack.
%
% Created by (please report bugs to): Alan Woessner (aewoessn@gmail.com)
%                                     University of Arkansas 
%                                     Fayetteville, AR 72701
%
% Release notes:
%   2/13/2020: Initial release
%

% --- Argument Parser ---
% Error checking
if size(varargin,2)<2
    fprintf('Error: Incorrect amount of minimum inputs. \n')
    return;
end

% Collect image stack
imageStack = varargin{1};

% Collect image coordinates
coordData = varargin{2};

% Check to see if input is a stucture, if it is, then try to pull out the
% coordinates
if isstruct(coordData)
    for i = 1:size(coordData.PVScan.Sequence,2)
        for j = 1:size(coordData.PVScan.Sequence{1, i}.PVStateShard.PVStateValue,2)
            if strcmp(coordData.PVScan.Sequence{1, i}.PVStateShard.PVStateValue{1,j}.Attributes.key,'positionCurrent')
                xCoords(i) = str2double(coordData.PVScan.Sequence{1, i}.PVStateShard.PVStateValue{1, j}.SubindexedValues{1, 1}.SubindexedValue.Attributes.value);
                yCoords(i) = str2double(coordData.PVScan.Sequence{1, i}.PVStateShard.PVStateValue{1, j}.SubindexedValues{1, 2}.SubindexedValue.Attributes.value);
            end
        end
    end

    for i = 1:size(coordData.PVScan.PVStateShard.PVStateValue,2)
        if strcmp(coordData.PVScan.PVStateShard.PVStateValue{1,i}.Attributes.key,'micronsPerPixel')            
            xCoords = round(xCoords./str2double(coordData.PVScan.PVStateShard.PVStateValue{1,i}.IndexedValue{1,1}.Attributes.value));          
            yCoords = round(yCoords./str2double(coordData.PVScan.PVStateShard.PVStateValue{1,i}.IndexedValue{1,2}.Attributes.value)); 
        end
    end
else
    xCoords = coordData(:,1);
    yCoords = coordData(:,2);
end

% Check optional inputs
alpha = 1;
beta = 0;
betaMag = [];
verb = 0;
for diri = 3:2:size(varargin,2)
    if strcmpi(varargin{diri},'alpha')
        alpha = varargin{diri+1};
    elseif strcmpi(varargin{diri},'beta')
        beta = varargin{diri+1};
    elseif strcmpi(varargin{diri},'betamag')
        betaMag = varargin{diri+1};
    elseif strcmpi(varargin{diri},'verbose')
        verb = varargin{diri+1};
    end
end

% Correlate
if beta > 0
    
    % Go through every image except the first one)
    for i = 2:size(imageStack,3)
        % Check to see how far the current image is supposed to be from the
        % previous image
        currDist = sqrt(((xCoords(i)-xCoords(i-1)).^2) + ((yCoords(i)-yCoords(i-1)).^2));
        
        % If the distance is larger that the image, then find a new place
        % to correlate from
        if currDist > size(imageStack,1)
            for j = i-1:-1:1
                newDist(j) = sqrt(((xCoords(i)-xCoords(j)).^2) + ((yCoords(i)-yCoords(j)).^2));
            end
            
            ind = find(newDist==min(newDist));
        else
            ind = i-1;
        end
        
        % Translate the current image, and correlate
        tmpImg = imageStack(:,:,i);
        tmpImg = imtranslate(tmpImg,[xCoords(i)-xCoords(ind),yCoords(i)-yCoords(ind)]);
        
        C = normxcorr2(imageStack(:,:,ind),tmpImg);
        
        % Do other things here
    end
end
% Blend
weightMap = single(zeros(size(imageStack,1),size(imageStack,2)));
weightMap(floor(median(1:size(imageStack,1))):ceil(median(1:size(imageStack,1))),floor(median(1:size(imageStack,2))):ceil(median(1:size(imageStack,2)))) = 1;
weightMap = bwdist(weightMap,'chessboard').^alpha;
weightMap = 1-(weightMap./max(max(weightMap)));

minR = min(yCoords);
minC = min(xCoords);
maxR = max(yCoords);
maxC = max(xCoords);

avgCanvas = zeros(maxR-minR+size(imageStack,1),maxC-minC+size(imageStack,2),'single');

for i = 1:length(xCoords)
    avgCanvas(yCoords(i)-minR+1:yCoords(i)-minR+size(imageStack,1),xCoords(i)-minC+1:xCoords(i)-minC+size(imageStack,2)) = avgCanvas(yCoords(i)-minR+1:yCoords(i)-minR+size(imageStack,1),xCoords(i)-minC+1:xCoords(i)-minC+size(imageStack,2)) + 1;
end

blendCanvas = zeros(maxR-minR+size(imageStack,1),maxC-minC+size(imageStack,2),'single');
canvas = zeros(maxR-minR+size(imageStack,1),maxC-minC+size(imageStack,2),'single');

for i = 1:length(xCoords)
    blender = (weightMap./single(avgCanvas(yCoords(i)-minR+1:yCoords(i)-minR+size(imageStack,1),xCoords(i)-minC+1:xCoords(i)-minC+size(imageStack,2))));
    blender(avgCanvas(yCoords(i)-minR+1:yCoords(i)-minR+size(imageStack,1),xCoords(i)-minC+1:xCoords(i)-minC+size(imageStack,2))==1) = 1;
    blendCanvas(yCoords(i)-minR+1:yCoords(i)-minR+size(imageStack,1),xCoords(i)-minC+1:xCoords(i)-minC+size(imageStack,2)) = blendCanvas(yCoords(i)-minR+1:yCoords(i)-minR+size(imageStack,1),xCoords(i)-minC+1:xCoords(i)-minC+size(imageStack,2)) + blender;    
    
    tmpImg = single(imageStack(:,:,i)).*blender;
    canvas(yCoords(i)-minR+1:yCoords(i)-minR+size(imageStack,1),xCoords(i)-minC+1:xCoords(i)-minC+size(imageStack,2)) = canvas(yCoords(i)-minR+1:yCoords(i)-minR+size(imageStack,1),xCoords(i)-minC+1:xCoords(i)-minC+size(imageStack,2)) + tmpImg;
end

blendCanvas(blendCanvas==0) = 1;
blendCanvas = 1./blendCanvas;
stitchedImage = single(canvas).*blendCanvas;
clear blendCanvas avgCanvas
end