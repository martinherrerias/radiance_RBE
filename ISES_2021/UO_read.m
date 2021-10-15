function data = UO_read(file)
% TT = UO_READ(FILE) - read data from the University of Oregon, as described in [1]. Returns a
%   TIMETABLE object with columns named according to 'Type of Measurement'.
%
% [1] Peterson, Josh, and Frank Vignola. “Structure of a Comprehensive Solar Radiation Dataset.” 
%     Solar Energy 211 (November 15, 2020): 366–74. https://doi.org/10.1016/j.solener.2020.08.092.
% [2] Get data from: http://solardat.uoregon.edu/index.html

    if nargin == 0, file = pickfile(); end

    fID = fopen(file,'r');
    janitor = onCleanup(@(x) fclose(fID));
    
    header = textscan(fID,'%[^\n\r]',9);
    header = cellfun(@(x) strsplit(x,','),header{1},'unif',0);
    header = cat(1,header{:});

    % let anything that looks like a number be a number
    x = str2double(header);
    idx = ~isnan(x); 
    x = mat2cell(x(idx),ones(nnz(idx),1));
    header(idx) = x;

    idx = strcmpi(header,'-');
    header(idx) = deal({''});

    station = cell2struct(header(1:7,2),{'station_id','name','location','latitude','longitude','altitude','TimeZone'});
    vars = cell2struct(header(1:9,8:end-1),{'type','element','SN','short_name','responsivity','uncertainty','sample','units','notes'},1);
    notes = header(2:end,end);

    % skip aggregated daily values
    textscan(fID,'%[^\n\r]',1);
    for j = 1:33
        l = textscan(fID,'%[^\n\r]',1);
        if isempty(setdiff(l{1},',-')), break; end
    end
    textscan(fID,'%[^\n\r]',1);

    % year.fractionofyear,dayofyear.fractionofday,YYYY-MM-DD--HH:MM:SS,SZA,AZM,ETR,ETRn,...
    fmt = ['%*f%*f%s' repmat('%f',1,numel(vars)+4) '%*s'];
    data = textscan(fID,fmt,'delim',',','TreatAsEmpty','NA');
    
        % in theory it should be possible to use %{yyyy-MM-dd--HH:mm:ss}D' above, but DATETIME
        % seems to have a hard time understanding the time 24:00:00
        x = cat(1,data{1}{:});
        x = datetime(x(:,1:10)) + duration(cellstr(x(:,13:end)));
        data{1} = x;
        
    [vars(end+1:end+4).type] = deal('sza','azm','etr','etrn');
    [vars(end-3:end).units] = deal('app.deg.','deg.N2E?','W/m^2','W/m^2');
    vars = vars([end-3:end,1:end-4]);

    data = timetable(data{1},data{2:end});
    data.Properties.VariableNames = matlab.lang.makeUniqueStrings({vars.type});
    data.Properties.VariableUnits = {vars.units};
    data.Properties.Description = strjoin(notes,newline());
    data.Properties.UserData.station = station;

    vars = struct2table(rmfield(vars,{'type','units'}));
    for j = 1:size(vars,2)
        f = vars.Properties.VariableNames{j};
        data = addprop(data,f,'variable');
        data.Properties.CustomProperties.(f) = vars{:,j}';
    end                                                                                                                                                                         
end