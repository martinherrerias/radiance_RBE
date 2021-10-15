
%% Load sensor configuration file
% (Sensor IDs must match table headers, they might need adjustments for other years)
[S,Loc] = MeteoSensor.readsensorspecs('EUO_2019.sensors');

%% Read data
datadir = './data';
try
    load(pickfile('EUO*_raw.mat',1,'ui',-1),'R');
catch

    files = pickfile([datadir '/*.csv'],Inf);
    assert(~isempty(files),'Download and unzip data, and place in the "data" folder');
    vars2keep = {S.ID};

    R = cell(numel(files),1);
    for k = 1:numel(files)
        TT = UO_read(files{k});
        R{k} = TT(:,vars2keep);
    end
    R = cat(1,R{:});
    R.Time.TimeZone = checktimezone(R.Properties.UserData.station.TimeZone);

    name = meteofilename(Loc,R.Time(1),R.Time(end),minutes(1));
    save([name '_raw.mat'],'R');
end

%% Parse into MeteoData object

try
    load(pickfile('EUO*PT1M_2019_MD.mat',1,'ui',-1),'MD');
catch
    MD = MeteoData(R,'location',Loc,'interval','e','sensors',S,'useweb',false);

    % Merge data flags into the single bit 'other'
    % see http://solardat.uoregon.edu/QualityControlFlags.html
    
    MD.flags = rmflag(MD.flags,{'u11','u12'});                     % 'raw/processed data' 
    MD.flags = mergeflags(MD.flags,{'u31','u32','u82'},'other');   % not described
    MD.flags.flags = parselist(MD.flags.flags,{'num','u99'; 'interp','u22'},'-soft');

    % Some unit adjustments, to avoid warnings
    MD.Patm = MD.Patm*100;
    MD.RH = MD.RH/100;
    
    % Label GHI sensors by model, instead of GHI_Aux(#)
    [~,idx] = parselist(getsourceof(MD,'GHI'),{MD.sensors.ID});
    lbl = matlab.lang.makeUniqueStrings({MD.sensors(idx).model});
    lbl = cellfun(@(lbl) ['GHI_{' lbl '}'],lbl,'unif',0);
    MD.source{'GHI'} = lbl;
    [MD.sensors(idx).ID] = deal(lbl{:});

    % Prettier labels for GTI sensors...
    [~,idx] = parselist(getsourceof(MD,'GTI'),{MD.sensors.ID});
    m = [MD.sensors(idx).mount];
    tilt = [m.tilt];
    azimuth = [m.azimuth];
    lbl = {'N','NNE','NE','ENE','E','ESE','SE','SSE','S','SSW','SW','WSW','W','WNW','NW','NNW'};
    lbl = lbl(mod(round(azimuth/22.5),16)+1);
    lbl = arrayfun(@(t,a) sprintf('GTI_{%d%s}',t,a{1}),tilt,lbl,'unif',0);
    MD.source{'GTI'} = lbl;
    [MD.sensors(idx).ID] = deal(lbl{:});

    % Get solar position, apply QC, ....
    MD = completemeteodata(MD);
    name = meteofilename(MD.location,MD.t(1),MD.t(end),MD.timestep);

    % Apply a 'shaded' flag to data affected by trees
    plot(MD,'shade'); hold on;
        
        % Horizon profile from http://solardat.uoregon.edu/EugenePhoto.html
        H = [2,1;21,2; 40,3; 59,0.5; 70,1; 79,5; 106,3; 152,4; 175,2; 180,2; 184,4; 198,5; 230,2; ...
            236,5; 240,9; 266,12; 274,6; 286,10; 289,9; 302 14; 314 7; 323 0.5; 346 6];
        H(:,1) = solarposition.fixazimuth(H(:,1),'N2E','Eq0',MD.location.latitude);
        plot(H(:,1),H(:,2),'r-')
    
        % % Draw horizon profile interactively
        % m = drawpolyline('color','g');
        % H = round(m.Position);
        % H(:,1) = solarposition.fixazimuth(H(:,1),'Eq0','N2E',MD.location.latitude);
        % H(:,1) = mod(H(:,1)+360,360);
    
        % Modified horizon profile
        H = [2 1;41 3;56 1;73 2;76 4;90 4;93 2;101 2;103 3;152 4;179 2;184 4;198 5;230 2;...
            232 5;238 4;243 6;245 10;251 3;253 6;257 8;261 12;272 3;275 4;278 10;285 10;289 6;...
            294 6;296 8;302 14;314 7;323 1;346 6];

        H(:,1) = solarposition.fixazimuth(H(:,1),'N2E','Eq0',MD.location.latitude);
        plot(H(:,1),H(:,2),'g-')

        shaded = MD.sunel < interp1(H(:,1),H(:,2),MD.sunaz) & MD.sunel > 0;
        MD.flags = checkfield(MD.flags,MD,@(x) ~shaded,'shaded',{'BNI','GHI','GTI'});
    
    % Update clearness indices, ignoring the flagged values
    MD = bestimate(MD);
    MD.t.TimeZone = MD.location.TimeZone;
    plot(MD,'heatmap');
    plot(MD,'ktrd');
    
    save([name '_MD.mat'],'MD');
end

%% Downsample to 15 min

MD.interval = 'c';
MD = resamplestructure(MD,[1,15],'-centered');
% MD = bestimate(MD);
name = meteofilename(MD.location,MD.t(1),MD.t(end),MD.timestep);
save([name '_MD.mat'],'MD');

