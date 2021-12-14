function imageData = xml2imagedata(xmlFilename)
% imageData = XML2IMAGEDATA(xmlFilename) reads the xml file, specified by
% xmlFilename, and outputs an easy to read structure, imageData, where
% all values in the xml file can be accessed.
%
% Created by: Alan Woessner (aewoessn@gmail.com) 11/10/21

% Parse xml file
xmlData = xml2struct(xmlFilename);

% Initialize new structure
imageData = struct();

% Pull out date and time
imageData.date = datetime(xmlData.PVScan.Attributes.date,'InputFormat','MM/dd/uuuu hh:mm:ss aa');

% Pull out all of the header information
tmpData = xmlData.PVScan.PVStateShard.PVStateValue;
for i = 1:size(tmpData,2)
    if isfield(tmpData{i}.Attributes,'value')
        % If only one value exists for an entry
        imageData.(matlab.lang.makeValidName(tmpData{i}.Attributes.key)) = tmpData{i}.Attributes.value;
    elseif isfield(tmpData{i},'IndexedValue') && isstruct(tmpData{i}.IndexedValue)
        % Weird special cases
        if isfield(tmpData{i}.IndexedValue.Attributes,'description')
            imageData.(tmpData{i}.Attributes.key).(matlab.lang.makeValidName(tmpData{i}.IndexedValue.Attributes.description)) = tmpData{i}.IndexedValue.Attributes.value;
        else
            imageData.(matlab.lang.makeValidName(tmpData{i}.Attributes.key)) = tmpData{i}.IndexedValue.Attributes.value;            
        end
    elseif isfield(tmpData{i},'IndexedValue') && ~isstruct(tmpData{i}.IndexedValue)
        % If more than one value exists for an entry
        for j = 1:size(tmpData{i}.IndexedValue,2)
            if isfield(tmpData{i}.IndexedValue{j}.Attributes,'description')
                imageData.(tmpData{i}.Attributes.key).(matlab.lang.makeValidName(tmpData{i}.IndexedValue{j}.Attributes.description)) = tmpData{i}.IndexedValue{j}.Attributes.value;                
            else
                imageData.(tmpData{i}.Attributes.key).(matlab.lang.makeValidName(tmpData{i}.IndexedValue{j}.Attributes.index)) = tmpData{i}.IndexedValue{j}.Attributes.value;
            end
        end
    elseif isfield(tmpData{i},'SubindexedValues')
        % Weird subindexed values
        for j = 1:size(tmpData{i}.SubindexedValues,2)
            if isstruct(tmpData{i}.SubindexedValues)
                for k = 1:size(tmpData{i}.SubindexedValues.SubindexedValue,2)
                    imageData.(tmpData{i}.Attributes.key).(matlab.lang.makeValidName(tmpData{i}.SubindexedValues.SubindexedValue{k}.Attributes.description)) = tmpData{i}.SubindexedValues.SubindexedValue{k}.Attributes.value;
                end
            else
                for k = 1:size(tmpData{i}.SubindexedValues{j}.SubindexedValue,2)
                    if isstruct(tmpData{i}.SubindexedValues{j}.SubindexedValue)
                        imageData.(tmpData{i}.Attributes.key).(matlab.lang.makeValidName(tmpData{i}.SubindexedValues{j}.Attributes.index)) = tmpData{i}.SubindexedValues{j}.SubindexedValue.Attributes.value;
                    else
                        imageData.(tmpData{i}.Attributes.key).(tmpData{i}.SubindexedValues{j}.Attributes.index).(matlab.lang.makeValidName(tmpData{i}.SubindexedValues{j}.SubindexedValue{k}.Attributes.description)) = tmpData{i}.SubindexedValues{j}.SubindexedValue{k}.Attributes.value;
                    end
                end
            end
        end
    end
end

% Go through each entry, and if it does not contain any letters, then
% assume it is a number
names = fieldnames(imageData);
for i = 2:size(names,1)
    if isstruct(imageData.(names{i}))
        subnames = fieldnames(imageData.(names{i}));
        for j = 1:size(subnames,1)
            if isstruct(imageData.(names{i}).(subnames{j}))
                subSubnames = fieldnames(imageData.(names{i}).(subnames{j}));
                for k = 1:size(subSubnames,1)
                    if isempty(regexpi(imageData.(names{i}).(subnames{j}).(subSubnames{k}),'[a-z]'))
                        imageData.(names{i}).(subnames{j}).(subSubnames{k}) = str2double(imageData.(names{i}).(subnames{j}).(subSubnames{k}));
                    end    
                end
            else
                if isempty(regexpi(imageData.(names{i}).(subnames{j}),'[a-z]'))
                    imageData.(names{i}).(subnames{j}) = str2double(imageData.(names{i}).(subnames{j}));
                end 
            end
        end
    else
        if isempty(regexpi(imageData.(names{i}),'[a-z]'))
            imageData.(names{i}) = str2double(imageData.(names{i}));
        end
    end
end
end