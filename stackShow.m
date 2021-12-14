function im = stackShow(varargin)
% [im] = stackShow(stack,kwargs,args)
% Generates a 3D render of an image stack (may take little bit of time to
% populate figure)
%
% Required Inputs:
%    stack - Volume stack (any image data type is supported)
%   Important note: For R/G/B input stacks, the channel should be the 4th
%   dim.
%
% Optional Inputs:
%   'cmap' - Desired colormap for images (all matlab colormaps are supported)
%   Important note: For R/G/B input stacks, please specify 'rgb' as colormap
%
%   'clim' - Limits of colormap, important to keep stack data value range in mind
%
%   'alpha' - Deisred alpha map, must be same size as the input image stack
%
%   'alim' - Limits of alpha map, important to keep stack data value range in mind
%
%   'zRes' - Resolution (in microns) of z-steps
%
%   'ref' - X/Y/Z lines are included (1) or not (default)
%
%   Note: If optional inputs are not used, this function will use
%   pre-determined default parameters
%
% Technical Note:
%   When inputting an RGB stack, you get best results when normalizing the
%   stack prior to inputting into this function
%
% Created by (please report bugs to): Alan Woessner (aewoessn@gmail.com)
%                                     University of Arkansas 
%                                     Fayetteville, AR 72701
%
% Release notes
%   1/10/2020: Initial release
%       -Key Features
%           -R/G/B stack compatibility
%           -Improved performance over 'surface' method
%

% --- Argument parser ---
stack = varargin{1};

cmap = 'default';
clim = [0 1];
alim = [0 1];
alphaMap = stack./2;
zRes = 1;
ref = 0;

for i = 2:2:size(varargin,2)
    if strcmpi(varargin{i},'cmap')
        cmap = varargin{i+1};
    elseif strcmpi(varargin{i},'clim')
        clim = varargin{i+1};
    elseif strcmpi(varargin{i},'alim')
        alim = varargin{i+1};
    elseif strcmpi(varargin{i},'alpha')
        alphaMap = varargin{i+1};
    elseif strcmpi(varargin{i},'zres')
        zRes = 1/varargin{i+1};
    elseif strcmpi(varargin{i},'ref')
        ref = varargin{i+1};
    end
end

% Get the size of the stack
[r,c,s,ch] = size(stack);

if ch>1 && ~strcmp(cmap,'rgb')
    disp('Critical Error: Input is 4D, but incorrect colormap')
    return
end

% Draw initial figure
ax = gca;
set(ax,'XLim',[1 c]);
set(ax,'YLim',[1 r]);
set(ax,'ZLim',[1 s]);
set(ax,'YDir','reverse');
set(ax,'ZDir','reverse');
set(ax,'Color',[0 0 0]);
set(ax,'XTick',[]);
set(ax,'YTick',[]);
set(ax,'ZTick',[]);
set(ax,'View',[45,45]);
set(ax,'DataAspectRatio',[1.14415550203554,1.14415550203554,zRes]) % This value is set by our microscope
hold on;

% Draw bounding box
boundBoxCoords = [1,1,1;c,1,1;c,r,1;1,r,1;1,1,s;c,1,s;c,r,s;1,r,s];
boundBoxInd = [1,2;1,4;1,5;2,6;3,2;3,4;3,7;4,8;...
               5,6;5,8;6,7;7,8];
           
for i = 1:size(boundBoxInd,1)
    line(boundBoxCoords(boundBoxInd(i,:),1),boundBoxCoords(boundBoxInd(i,:),2),boundBoxCoords(boundBoxInd(i,:),3),'Color',[0.25 0.25 0.25]);
end

if ref == 1
    axInd = cat(3,[c,r,1;c*0.9,r,1],[c,r,1;c,r*0.9,1],[c,r,1;c,r,s*0.5]);

    color = [1,0,0;0,1,0;0,0,1];
    for i = 1:size(axInd,3)
        line(axInd(:,1,i),axInd(:,2,i),axInd(:,3,i),'Color',color(i,:),'Linewidth',2);
    end
end

if ~strcmp(cmap,'rgb')
    %{
    stack = (stack-clim(1))./(clim(2)-clim(1));
    stack(stack>1) = 1;
    stack(stack<0) = 0;
    %}
    
    alphaMap = (alphaMap-alim(1))./(alim(2)-alim(1));
    alphaMap(alphaMap>1) = 1;
    alphaMap(alphaMap<0) = 0;
    
    % Draw images
    for i = 1:s
        im = imagesc('CData',stack(:,:,i),'AlphaData',alphaMap(:,:,i));
        colormap(ax,cmap);
        caxis(ax,clim);
        t = hgtransform('Parent',ax);
        set(im,'Parent',t);
        set(t,'Matrix',makehgtform('translate',[0 0 i]));
    end
    
    
else
    %redImg = cat(3,ones(512,512,'like',stack),zeros(512,512,'like',stack),zeros(512,512,'like',stack));
    %grnImg = circshift(redImg,1,3);
    %bluImg = circshift(grnImg,1,3);
    %stack = (stack-clim(1))./(clim(2)-clim(1));
    %stack(stack>1) = 1;
    %stack(stack<0) = 0;
    
    %alphaMap = (alphaMap-alim(1))./(alim(2)-alim(1));
    %alphaMap(alphaMap>1) = 1;
    %alphaMap(alphaMap<0) = 0;
    alphaMap = mean(stack,4);
    alphaMap = (alphaMap-min(min(min(alphaMap))))./(max(max(max(alphaMap)))-min(min(min(alphaMap))));
    
    for i = 1:s
        %{
        for j = 1:3
            if j == 1
                im(i,j) = imagesc('CData',redImg.*stack(:,:,i,j),'AlphaData',alphaMap(:,:,i,j));
            elseif j == 2
                im(i,j) = imagesc('CData',grnImg.*stack(:,:,i,j),'AlphaData',alphaMap(:,:,i,j));
            elseif j == 3
                im(i,j) = imagesc('CData',bluImg.*stack(:,:,i,j),'AlphaData',alphaMap(:,:,i,j));
            end
            t = hgtransform('Parent',ax);
            set(im(i,j),'Parent',t);
            set(t,'Matrix',makehgtform('translate',[0 0 i]));
        end
        %}
        im(i) = imagesc('CData',squeeze(stack(:,:,i,:)),'AlphaData',alphaMap(:,:,i));
        t = hgtransform('Parent',ax);
        set(im(i),'Parent',t);
        set(t,'Matrix',makehgtform('translate',[0 0 i]));        
    end
end
hold off;

end