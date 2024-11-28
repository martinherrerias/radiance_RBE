
% clear all

DT = minutes(15);
SRC = 'EUO';

load(pickfile(['knkd_density_' SRC '_' isoduration(DT) '*.mat']),'TPM');
load(pickfile([SRC '*' isoduration(DT) '*.mat']),'MD');

MD = addsource(MD,'cosz',sind(MD.sunel),'cosz',1);

% % ... if using hourly-averaged MAP of Kt as conditioning variable
% Kt = circshift(movmean(MD.kt,[12,0]),1);
% MD = addsource(MD,'Kt',Kt);
        
%%
% SENSORS = {'GTI_{30S}','GTI_{90N}','GTI_{90S}'};
% SENSORS = 'GTI_{90S}','GHI_{LI200}'};
SENSORS = {'GTI_{30S}'};

RBE(MD,TPM,SENSORS,'mainmdl','constant','ndays',3,'-plot','-benchmark');


%%
NDAYS = 60;

[~,idx] = cellfun(@(f) min(TPM.(f)),{'ignorance','energy','discrepancy'});
TESTS = TPM.Properties.RowNames(unique(idx));

if ~isfolder('benchmarks'), mkdir('benchmarks'); end

F = MD.flags;
ok = ~MD.dark & ~MD.missing & MD.kd > 0;
ok = ok & all([F.kn,F.kd,F.kt,circshift(F.kn,1),circshift(F.kd,1)]== 0,2);
ok(1) = false;

T = table(TESTS,'VariableNames',{'TPM'});

for k = 1:numel(TESTS) 
% try
    filename = ['./benchmarks/' isoduration(MD.timestep) '_' strjoin(SENSORS,'+') '_' TESTS{k} '.mat'];
    if isfile(filename)
        load(filename,'RES');
    else
        tic()
        RES = RBE(MD,TPM,SENSORS,'mainmdl',TESTS{k},'ndays',NDAYS,'benchmark',k == 1); 
        save(filename,'RES'); 
        toc()
    end

    T.energy(k) = sqrt(mean(RES.energy(ok).^2,'omitnan'));
    T.rmse(k) = sqrt(mean(RES.rmse(ok).^2,'omitnan'));
    T.ignorance(k) =  median(RES.ignorance(ok),'omitnan');
    T.box_discrepancy(k) = discrepancy(RES.box(ok));
    T.kn_discrepancy(k) = discrepancy(RES.PIT(ok,1));
    T.kd_discrepancy(k) = discrepancy(RES.PIT(ok,2));

    plot_metrics(RES.ignorance,RES.box,RES.energy)
% end
end

   