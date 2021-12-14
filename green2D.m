function out = green2D(data,ref)
% Calculate green strain of an element by using finite element
% isoparametric mapping.
%
% Created by:
% Alan Woessner
% University of Arkansas
% Quantitative Tissue and Diagnostics Laboratory (www.quinnlab.org)
%
% Last edited on/by: AW, 2/3/21
% 
% Edit notes:
% 7/17/19
%   -Initial Release
%
% 7/7/20
%   -Changed output to structure rather than individual outputs
%
% 2/3/21
%   -Added incompressibility assumption as Ezz in green strain tensor
% -------------------------------------------------------------------------
% Inputs:
%   data
%       The (x,y) coordinates for each dot. This should take the form:
%           [x1 y1 x2 y2 ... xn yn]
%       where each row corresponds to a different point in time. Please
%       refer to the supported shapes section for more clarification on the
%       ordering of points.
%
%   ref
%       A single input, referring to which row should be considered the
%       reference point
% -------------------------------------------------------------------------
% Output:
%   out
%       Data structure containing the following:
%           frame - The time point relative to ref input
%
%           greenStrain - Green strain tensor
%
%           deformation - Deformation gradient
%
%           principleStrain - Principle green strain tensor such at first
%           column is E1 X/Y/Z magnitude, etc.
%
%           principleDirection - Vector of principle green strain such that
%           first column is E1 X/Y/Z vector, etc.
% -------------------------------------------------------------------------
% There are currently two supported shapes:
%
% 3 node triangle (position does not matter)
%      3
%     / \  
%    /   \
%   1-----2
%
%  Shape Function:
%  Node |I(L1)|J(L2)|K(L3)|
%  -----------------------|
%   1   |  1  |  0  |  0  |   N(1) = 1 - L2 - L3
%   2   |  0  |  1  |  0  |   N(2) = L2
%   3   |  0  |  0  |  1  |   N(3) = L3
% 
% x = x1 + (x2 - x1)L2 + (x3 - x1)L3
% y = y1 + (y2 - y1)L2 + (y3 - y1)L3
% 
% -------------------------------------------------------------------------
% 4 node rectangle (position does matter)
%   3------4         ^ beta
%   |      |         |  
%   |      |         |
%   2------1         -----> alpha
%
%  Shape Function:
%  Node |alpha|beta |
%  -----------------|
%   1   |  1  | -1  |  N(i) = 1/4 (1+ a*alpha)(1+ b*beta)
%   2   | -1  | -1  | 
%   3   | -1  |  1  |  
%   4   |  1  |  1  |
% -------------------------------------------------------------------------
% Green Strain is calculated by performing these steps:
%
% 1) Compute displacement of each dot
% 2) Assemble Jacobian from the partial derivatives of each catesian
% coordinate with respect to each natrual coordinate
% 3) Calculate the inverse of the Jacobian
% 4) Calculate elements of the deformation gradient
% 5) Compute Green strains based on deformation gradient
% -------------------------------------------------------------------------

% Step 1: Compute displacement (u and v) of each dot
u = [];
v = [];

for i = 1:2:size(data,2)
    % u displacement
    u(:,end+1) = data(:,i)-data(ref,i);
end

for i = 2:2:size(data,2)
    % v displacement
    v(:,end+1) = data(:,i)-data(ref,i);
end

% Step 2: Assemble Jacobian from the partial derivatives of each catesian
%          coordinate with respect to each natural coordinate
        
alpha = 0;
beta = 0;

if size(data,2)==8
    % Four node rectangle
    signLookup = [1,-1;-1,-1;-1,1;1,1];
    
        % dx/da
    dxda = 0.25.*sum(data(ref,1:2:end).*(1+(beta.*signLookup(:,2)')).*(signLookup(:,1)')); 

        % dx/db
    dxdb = 0.25.*sum(data(ref,1:2:end).*(1+(alpha.*signLookup(:,1)')).*(signLookup(:,2)')); 
       
        % dy/da
    dyda = 0.25.*sum(data(ref,2:2:end).*(1+(beta.*signLookup(:,2)')).*(signLookup(:,1)'));   
                   
        % dy/db
    dydb = 0.25.*sum(data(ref,2:2:end).*(1+(alpha.*signLookup(:,1)')).*(signLookup(:,2)'));
else
    % Three node triangle
        % dx/dL2 (x2-x1)
    dxda = (data(ref,3)-data(ref,1));
    
        % dx/dL3 (x3-x1)
    dxdb = (data(ref,5)-data(ref,1));
    
        % dy/dL2 (y2-y1)
    dyda = (data(ref,4)-data(ref,2));
    
        % dy/dL3 (y3-y1)
    dydb = (data(ref,6)-data(ref,2));    
end

J = [dxda,dyda;dxdb,dydb];

% Step 3: Calculate the inverse of the Jacobian
IJ = inv(J);
A = IJ(1,1);
B = IJ(1,2);
C = IJ(2,1);
D = IJ(2,2);
        
% Step 4: Calculate elements of the deformation gradient
if size(data,2)==8
    % Four node rectangle
        % du/da
    duda = 0.25.*sum(u.*(1+(beta.*signLookup(:,2)')).*(signLookup(:,1)'),2);
        
        % du/db
    dudb =  0.25.*sum(u.*(1+(alpha.*signLookup(:,1)')).*(signLookup(:,2)'),2);
    
        % dv/da
    dvda = 0.25.*sum(v.*(1+(beta.*signLookup(:,2)')).*(signLookup(:,1)'),2);
        
        % dv/db
    dvdb =  0.25.*sum(v.*(1+(alpha.*signLookup(:,1)')).*(signLookup(:,2)'),2);
else
    % Three node triangle
        % du/da
    duda = u(:,2)-u(:,1);
    
        % du/db
    dudb = u(:,3)-u(:,1);
    
        % dv/da
    dvda = v(:,2)-v(:,1); 
    
        % dv/db
    dvdb = v(:,3)-v(:,1);
end
   
        % dudx
    dudx = (A.*duda) + (B.*dudb);
    
        % dudy
    dudy = (C.*duda) + (D.*dudb);

        % dvdx
    dvdx = (A.*dvda) + (B.*dvdb);
    
        % dvdy
    dvdy = (C.*dvda) + (D.*dvdb);

    
% Step 5: Compute Green strains based on deformation gradient
F = [reshape(dudx,1,1,[])+1,reshape(dvdx,1,1,[]);reshape(dudy,1,1,[]),reshape(dvdy,1,1,[])+1];
%lamZ=1./((dudx+1).*(dvdy+1)-dudy.*dvdx);
%Ezz=0.5*(lamZ.^2-1);

for i = 1:size(F,3)
    E(:,:,i) = 0.5.*(F(:,:,i)'*F(:,:,i) - eye(2));
end
%E(3,3,:) = Ezz; % Assuming incompressibility
    
for i = 1:size(E,3)
    [dir(:,:,i),princ(:,:,i)] = eig(E(:,:,i));
    princ(:,:,i) = rot90(princ(:,:,i),2);
    dir(:,:,i) = fliplr(dir(:,:,i));
end

% Step 6: Assemble data structure
for i = 1:size(F,3)
    out(i).frame = i-ref;
    out(i).greenStrain = E(:,:,i);
    out(i).deformation = F(:,:,i);
    out(i).principleStrain = princ(:,:,i);
    out(i).principleDirection = dir(:,:,i);
end

end