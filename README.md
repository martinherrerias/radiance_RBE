# radiance_RBE
Recursive Bayesian Estimation of Irradiance Components

## Reference

"Probabilistic Estimation of Irradiance Components:
A State Space Framework to Integrate Empirical Models,
Forecasts, and Imperfect Sensor Measurements",
Martin Herrerias Azcue & Annette Hammer. 
ISES SWC 2021, 28.10.2021.

## Use
#### 1. Clone the repository (*with submodules!*):

`git clone --recurse-submodules git@github.com:martinherrerias/radiance_RBE.git`

#### 2. Add all code to the matlab path:
```
addpath(genpath('matlab-pvmeteo'));
addpath(genpath('external'));
```
#### 3. Download test data set (Eugene, Oregon, 2019) from: 
[solardat.uoregon.edu](http://solardat.uoregon.edu/SelectArchivalUpdatedFormat.html), 
and unpack .csv files directly into the `data` folder.

#### 4. Run the code blocks in the scripts:

- `UO_batch_read.m`: Read, format and automatic QC of data
- `prior_fit_test_EUO.m`: Fit and test Transition Probability AKD estimates
- `inverse_transposition_test_EUO.m`: Test full RBE algorithm

#### 5. Let me know how it went

I'll be happy to help getting it going, and will really appreciate the feedback.

## Requirements

Matlab 2020a, with _possibly_ the following toolboxes:

- Control System Toolbox
- Optimization Toolbox
- Signal Processing Toolbox
- Mapping Toolbox
- Statistics and Machine Learning Toolbox
- Financial Toolbox
- Econometrics Toolbox
