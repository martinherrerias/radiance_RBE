
%% Generate test and training data sets

% clear all

DT = minutes(15);
SRC = 'EUO';
load(pickfile([SRC '*' isoduration(DT) '*.mat']),'MD');

[X_fit,X_test,info] = knkd_density_prep(MD,DT);

clear MD

%% Fit transition probability models:

% Define transition-probability models: conditioning variables are in curly brackets, model
%   combinations are marked with (a)x(b). Constant, special cases are recognized by name.
TESTS = {'uniform','constant',{'cosz'},{'lastkn'},{'lastkd'},{'lastkn','lastkd'},...
         '(lastkd)x(lastkn)','(cosz)x(lastkn+lastkd)','(cosz)x(lastkd)x(lastkn)'};

% Include additional parameters to modify grid of evaluation points:
% ..,'gridtype','a','gridsteps',30,'uniformshare',0.5,'minstep',1e-4,'gridrange',[0,Inf]};

TPM = knkd_density_fit(X_fit,info,TESTS);

save([TPM.Properties.UserData.name '.mat'],'TPM','X_test');

%% Test models

% load(pickfile(['knkd_density_' SRC '_' isoduration(DT) '*.mat']),'TPM','X_test');

TPM = knkd_density_test(TPM,X_test);
save([TPM.Properties.UserData.name '.mat'],'TPM','X_test');

% Display scores
TPM = sortrows(TPM,'discrepancy');
TPM(:,{'ignorance','energy','discrepancy'})

persistance = hypot(X_test.lastkd - X_test.kd,X_test.lastkn - X_test.kn);
fprintf('Persistance Energy Score (RMSE): %0.4f\n',sqrt(mean(persistance.^2)));

%% Compare best model(s) against persistance

[~,idx] = cellfun(@(f) min(TPM.(f)),{'ignorance','energy','discrepancy'});
tocompare = TPM.Properties.RowNames(unique(idx));

plot_metrics(NaN,NaN,persistance,'Det. pers.');
knkd_density_test(TPM,X_test,tocompare,'-plot');
