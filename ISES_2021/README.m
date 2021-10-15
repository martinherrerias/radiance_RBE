
    
% "Probabilistic Estimation of Irradiance Components:
% A State Space Framework to Integrate Empirical Models,
% Forecasts, and Imperfect Sensor Measurements";
% Martin Herrerias Azcue & Annette Hammer. 
% ISES SWC 2021, 28.10.2021.
% 
% For questions and comments: herrerias@hlrs.de

%% Download Eugene, Oregon data (2019) from:
% http://solardat.uoregon.edu/SelectArchivalUpdatedFormat.html

UO_batch_read();

%% Fit Transition Probability kernel density estimates

prior_fit_test_EUO();

%% Test full RBE algorithm

inverse_transposition_test_EUO();

