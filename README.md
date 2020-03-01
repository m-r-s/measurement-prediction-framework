# Measurement and prediction framework for aided-patient performance prediction
This repository holds most of the necessary files to understand and reproduce the experiment *"Individual aided speech recognition performance and predictions of benefit for listeners with impaired hearing employing FADE"*.
The experiment aims to predict the aided speech recognition performance of listeners with impaired hearing by means of simulations with a re-purposed, individualized automatic speech recognition system.
In the near future, a manuscript describing the experiment and discussing its results will be published.

Author: Marc René Schädler (2020)
E-mail: marc.r.schaedler@uni-oldenburg.de


## Aim and scope
The aim of publishing these files is to facilitate the reconstruction of the steps described in the corresponding, to-be-published manuscript.
It might be useful for experienced scientists with a solid background in hearing research including impaired hearing, speech recognition, psychoacoustics, and computer science.
The experiment employed several software packages and materials, of which some cannot be freely distributed.
Only the files that can be freely distributed are included here, while links/hints to the required proprietary portions are given.

The original code was back-ported to the current (now free) versions of the used software packages.
This should help to avoid diversions and still provide everything that is needed to perform a similar study.
The remainder of this file will provide tutorial-like indications on how to run each experimental step with the provided software.


## Related and required software packages
This software was developed and tested with [Ubuntu Linux 19.10](https://ubuntu.com/).

The code is based on the [Measurement and Prediction Framework](https://github.com/m-r-s/measurement-prediction-framework) (version 3.0.1).
This framework relies on the [Essential Measurement Applications](https://github.com/m-r-s/measurement-prediction-framework/blob/master/ema/) (version 3.0.1) for measurements with listeners and on the [Framework for Auditory Discrimination Experiments (FADE)](https://github.com/m-r-s/fade) for simulations of measurements.
In addition, the [Open Master Hearing Aid (openMHA)](http://openmha.org) (version 4.11.0) is used to perform the signal processing of the hearing device.

You will need:

1. A working installation of [FADE](https://github.com/m-r-s/fade). Follow the instructions on the project website.
2. A working installation of [openMHA](http://openmha.org). Use the provided deb-repositories for an easy installation.
3. At least the following additional packages: build-essential gawk octave octave-signal liboctave-dev jackd2 libjack-jackd2-dev mplayer


## Data structure of this repository
Here is an overview of the most important files and folders in this repository.
Please note that there are many symbolic links which are not listed here.

* **data/** (scripts and signals needed for stimulus generation, used by EMA and FADE)
    * *matrix/* (matrix sentence test material and maskers)
    * *processing/* (files for openMHA-based signal processing)
    * *stimulus/* (generation scripts for psychoacoustic stimuli)
        * gensweep.m (tone stimulus generation script)
        * gensweepinnoise.m  (tone-in-noise stimulus generation script)
* **ema/** (files for measurements with the Essential Measurement Applications)
    * *data/* (measurement results, i.e., observed data, and individual hearing device configurations)
    * *mfiles/* (implementations of measurements)
        * measure_matrix.m (matrix sentence test)
        * measure_sweep.m (measurement of tone detection thresholds)
        * measure_sweepinnoise.m (measurement of tone-in-noise detection thresholds)
        * siam.m (implementation of the [single-interval adjustment matrix (SIAM)](https://github.com/m-r-s/siam-toolkit) procedure)
    * *ema.sh* (main script to run the Essential Measurement Applications)
* **evaluation/** (scripts to evaluate the model predictions)
    * *figures/* (generated figures)
    * *matrix_simulated_data.txt* (simulation results)
    * *play_evaluate.sh* (Load observed and simulated data and generates figures with thresholds)
    * *play_statistics.sh* (Load observed and simulated data and generates tables with statistical analyses)
* **fade/** (files for simulations of measurements with FADE)
    * *features/hzappp-full* (feature extraction which includes the individualization)
        * load_hearingstatus.m (script that determines model parameters from psychoacoustic measurements)
        * play_plot_mapping.m (script that visualizes the mapping from tone-in-noise detection thresholds to the model parameter level uncertainty)
        * ul2tintable.txt (simulated tone-in-noise detection thresholds that are used for model parameter inference, cf. *run_ul2tin_mapping.sh*)
        * tin2ul.m and ul2tin.m (mapping functions that use the data in *ul2tintable.txt*)
    * *fade_simulate.sh* (script to set up and run one FADE simulation)
    * *run_matrix_simulations.sh* (script that runs all matrix sentence FADE simulations)
    * *run_ul2tin_mapping.sh* (script that runs the tone-in-noise detection simulations required to generate the mapping table *ul2tintable.txt*)
* **loop/** (JACK plugin that can be used to perform headphone compensation)
    * *tools/update_configuration.m* (script to generate compensation filters)
* **platt/** (code to generate calibration stimuli for EMA)
* **source/** (files required to set up the matrix sentence test)
    * *hrir/* (head-related impulse responses)
    * *masker/* (masker signals)
    * *noise/* (microphone noise signal)
    * *speech/* (German matrix sentences, named, e.g., 00456.wav etc.)
* **make.sh** (script to compile and set up tools in *loop/* and *platt/*)
* **play_prepare_matrix.m** (script that prepares files for *data/matrix/*)

## Set up
The script **play_prepare_matrix.m** sets up the speech and masker signals as described in the corresponding publications.
Therefore the following resources are needed.

A copy of the [German matrix sentence test](https://www.hoertech.de/en/home-ht.html).
The speech files need to be placed in *source/speech*.
The test specific noise file needs to be placed in *source/maskers*.

A copy of the [ICRA noises](https://icra-audiology.org/Repository/icra-noise) and the [ICRA5-250 noise](http://medi.uni-oldenburg.de/download/ICRA/).
The files need to be placed in *source/noises*.

A copy of [the head-related impulse responses from Kayser et. al](https://medi.uni-oldenburg.de/hrir/).
The files need to be placed in *source/hrir*.

Please see *source-filelist.txt* for the naming schemes and exact folders.

Run

> make.sh

to compile and setup the tools in **loop/** and **platt/**.

Run

> ./play_prepare_matrix.m

to generate the matrix sentence test material in *data/matrix/*.


## Calibration
The calibration and compensation tools reside in **loop/**.
Please have a close look to the configuration in *loop/tools/update_configuration.m*.
The parameters for the calibration of your setup can be set there.

The provided configuration works for the original equipment (Focusrite Scarlett 2i2 sound card and Sennheiser HDA 200 headphones).
*ema/ema.sh* provides a menu for checking the calibration with narrow band noise signals.
Please note that the compensation filter for the Sennheiser HDA 200 headphones is included in the openMHA configurations.

In any case, you will need to run update the configuration of loop and compile the required binaries.

To do so, run:
> ./make.sh

See the [EMA project website](https://github.com/m-r-s/measurement-prediction-framework) for warnings and more information on calibration.


## Measurements with the Essential Measurement Applications
The main application script is *ema/ema.sh*, which starts the console-based user interface.
The measurement blocks and conditions are defined in this script as well.
The measurements are implemented in GNU/Octave scripts (*ema/mfiles/measure_*).
Results are documented in *ema/data*.

Open *ema/ema.sh*, configure your sound device (use "aplay -l" to get a list) and run

> ./ema/ema.sh

to start the user interface (UI).
The UI asks to select or create a user.
Selecting one will bring you to the main menu.

You may select now from the measurements block that were performed in the study.
If you correctly installed openMHA you can now perform the tests under the individually aided conditions for that listener.
You may check the log files in *ema/log* if you don't hear any sound.

The tools to determine the individual gain tables (e.g. according to NAL-NL1) cannot be provided.
The employed individual gain tables are included in the openMHA configuration along with the individual measurement results in *ema/data/*.
The corresponding back-ported individual openMHA configurations can be found in *ema/data/listener*/processing/*.


## Simulations with FADE
The two main simulation scripts are *fade/run_matrix_simulations.sh* and *fade/run_ul2tin_mapping.sh*.
The employed feature-extraction scripts, which implement the individually impaired hearing, can be found in *fade/features*.
The simulations require a correct installation of FADE and openMHA (e.g., added to PATH).

Run

> ./fade/run_ul2tin_mapping.sh

if you want to re-simulate the tone-in-noise detection thresholds and re-generate the *ul2tintable.txt* file that is used in the feature-extraction stage to infer the level-uncertainty model parameter.
The results will be written to *fade/tin-data/*.
*ul2tintable.txt* will be generated after all simulations finished.
This should always be done if the feature extraction is **modified IN ANY WAY**, because the mapping is specific to the feature extraction.

You may check the mapping with the script *play_plot_mapping.m*.
Just run inside the feature extraction folder *fade/features/hzappp-full*:

> ./play_plot_mapping.m

which will generate the figure *tin_mapping.eps* in the same folder, showing the data and the used polynomial fits.

Run

> ./fade/run_matrix_simulations.sh

to re-do all individual matrix sentence test simulations with FADE.
The results will be written to *fade/matrix-data/* and collected to *evaluation/matrix_simulated_data.txt* after all simulations finished.


## Evaluation
The two main evaluation scripts are *evaluate/play_evaluate.m* and *evaluate/play_statistics.m*.
The evaluation is implemented in GNU/Octave.

Run

> (cd evaluation/ && octave --gui ./play_evaluate.m)

to re-generate the figures in *evaluate/figures*.


Run

> (cd evaluation/ && ./play_statistics.m)

to re-do the statistical analyses and re-generate the tables (will be printed to console).