# Measurement and prediction framework for the evaluation of PLATT
This repository holds most of the necessary files to understand and reproduce the experiment *"Thoughts on the potential to compensate a hearing loss in noise"*.
The experiment aims to demonstrate that the partial compensation of a hearing loss in noise, that is, one which can not be compensated by simple amplification, might be possible.
This hypothesis is based on simulations with a variant of the simulation framework for auditory discrimination experiments (FADE, a re-purposed, individualized automatic speech recognition system) that was successfully used to accurately predict the individual aided speech recognition performance of listeners with impaired hearing.
*In the simulations*, a partial compensation of a (simulated) hearing loss in noise was achieved with a patented dynamic range manipulation scheme (PLATT) that was specifically designed for this purpose.
The sources of a current draft of the manuscript which describes the experiment and discusses its results can be found in the folder `manuscript`.
In the discussion section of the manuscript, listening experiments suitable to test the hypothesis are described.
This repository also contains many of the bits required to implement these listening experiments.

Author: Marc René Schädler (2021)
E-mail: marc.rene.schaedler@uni-oldenburg.de


## Aim and scope
The aim of publishing these resources is to facilitate the reproduction of the experiment and to encourage, foster, and accelerate the verification and adoption of the methods presented in the manuscript.
Its aimed at experienced scientists with a solid background in hearing research including impaired hearing, speech recognition, and computer science.
The experiment employed several software packages and materials, of which some cannot be freely distributed.
Only the files that can be freely distributed are included here, while links/hints to the required proprietary portions are given.
The remainder of this file will provide tutorial-like indications on how to run each experimental step with the provided software.


## Related and required software packages
This software was developed and tested with [Ubuntu Linux 20.04 and 20.10](https://ubuntu.com/).

The code is based on the [Measurement and Prediction Framework](https://github.com/m-r-s/measurement-prediction-framework) (version 3.1.1).
The prediction part of the framework relies on the [Framework for Auditory Discrimination Experiments (FADE)](https://github.com/m-r-s/fade) (version 2.4.0) for simulations of measurements.

You will need:

1. A working installation of [FADE](https://github.com/m-r-s/fade) (version 2.4.0). Follow the instructions on the project website.
2. At least the following additional packages (let me know if I missed some): build-essential gawk octave octave-signal liboctave-dev jackd2 libjack-jackd2-dev sox git
3. A copy of the German matrix sentence test and the test-specific noise signal <https://www.hoertech.de/en/devices/olsa.html>
4. A copy of the ICRA5-250 noise <http://medi.uni-oldenburg.de/download/ICRA/index.html> (please rename the file to icra5.wav)


## Data structure of this repository
Here is an overview of the most important files and folders in this repository.
Please note that there are many symbolic links which are not listed here.

* ***data/*** (scripts and signals needed for stimulus generation, used by EMA and FADE)
    * *matrix/* (matrix sentence test and maskers signal)
        * *maskers/* (prepared masker signals)
        * *source/* (source masker signals)
        * prepare_signals.sh (script to resample masker signals with sox)
        * *speech/* (speech signals)
            * *default/* (prepared speech signals)
            * *source/* (source speech signals)
            * prepare_signals.sh (script to resample speech signals with sox)
    * *processing/* (files for openMHA-based signal processing)
        * *platt/* (PLATT reference configuration)
        * generate_processings.sh (script to generate PLATT-1 to PLATT-8 variants from reference configuration)
* ***ema/*** (files for measurements with the Essential Measurement Applications, not needed for simulations with FADE)
    * ema.sh (main script to run the Essential Measurement Applications)
* ***fade/*** (files for simulations of measurements with FADE)
    * *evaluation/* (scripts to evaluate the simulation results)
        * play_evaluate.m (script to plot Plomp curves)
        * play_psyfun.m (script to plot psychometric functions)
        * play_tables.m (script to generate average improvements table)
        * results.txt (simulation results)
        * psyfun-data.txt (psychometric functions of selected simulation results)
    * *features/sgbfb-abel-full/* (feature extraction)
        * feature_extraction.m (main feature extraction script, implements level uncertainty and limited frequency range)
    * fade_simulate.sh (script to set up and run one FADE simulation)
    * run_experiments.sh (script that runs all matrix sentence FADE simulations)
    * snippets.txt (misc BASH code fragements, e.g., to read out psychometric functions from FADE experiments)
* ***loop/*** (JACK plugin that can be used to perform headphone compensation)
    * 'tools/'update_configuration.m (script to generate compensation filters)
* ***manuscript/*** (manuscript source files)
    * ms.tex (main LaTeX file, to be compiled with pdflatex)
* ***platt/*** (PLATT implementation and configuration scripts)
    * *src/* (source code of PLATT implementation)
        * *configuration/* (output directory of binary configuration files)
        * *core/* (PLATT C routines)
        * *jack/* (PLATT JACK plugin)
        * *octave/* (PLATT octave wrapper functions and demo script)
            * play_demo.m (extensive commented demo script)
    * *tools/* (scripts to generate and update binary PLATT configuration files)
        * configuration.m (PLATT "user" configuration file)
        * mel_gammatone_iir.m (script to calculate filter bank coefficients used by PLATT for the signal analysis/resynthesis)
        * play_mel_gammatone_demo.m (script to demonstrate properties of filter bank with figures)
        * set_configuration.m (script to complete PLATT "user" configuration)
        * write_configuration.m (script to write binary configuration files)
        * update_configuration.m (script to read "user" configuration from configuration.m and write binary configuration to ../src/configuration)
    * live.sh (script to start PLATT on mobile hearing aid prototype)
* ***make.sh*** (script to compile and set up tools in *loop/* and *platt/*)


## Initial set up
Run

> ./make.sh

in the root directory of the repository to compile and setup the tools in *loop/* and *platt/*.
However, for this command to succeed, the line that starts with "error(" in loop/tools/update_configuration.m has to be deleted or commented out.
If you are only interested in the simulations with FADE, just remove the line.
The file controls the calibration/compensation of the playback (not used by FADE, only by EMA).

Run

> ./generate_processings.sh

in the folder *data/processing/* to generate the binary configuration files for PLATT-1 to PLATT-8.

Further, for the simulations with FADE, the matrix sentence signals and noise masker signals need to be prepared.
FADE interprets a root-mean-square (RMS) of 1 as 130dB SPL.
Speech and noise files are expected to scaled to 65dB SPL, that is -65dB FS.
You need to scale the source material accordingly (and don't forget to save the result with 32 bits per sample).

The matrix sentence speech files need to be placed in *data/matrix/speech/source/*.
Then run the script `prepare_signals.sh` in *data/matrix/speech/*.

The noise masker files needs to be placed in *data/matrix/source/*.
Then run the script `prepare_signals.sh` in *data/matrix/*.

The "prepare_signals.sh" scripts just resample the corresponding source signals to 48kHz with sox, because the Octave resample function had a [funny bug](https://savannah.gnu.org/bugs/?func=detailitem&item_id=59149).


## Mentionable details of FADE setup
The simulations require a correct installation of FADE.
It is required that FADE was [added to the PATH environment variable}(https://github.com/m-r-s/fade/tree/2.4.0#fade).

Also, the default parallel configuration of FADE will be used.
Almost always, using the maximum number of available threads, as reported by `nproc`, is far from optimal.
Some initial benchmarking can save many simulation hours.
Probably I will write a script that automates this step some day.
For now, you can look at the [corresponding FADE tutorial](https://github.com/m-r-s/fade/blob/2.4.0/tutorials/ADVANCED_PARALLELIZATION.md).

For a system with a Ryzen 9 3900X CPU with 12/24 cores/threads and 64Gb RAM, the following parallel configuration was optimal in these experiments:

> CORPUS_THREADS=8
> PROCESSING_THREADS=24
> FEATURES_THREADS=10
> TRAINING_THREADS=16
> RECOGNITION_THREADS=12


## Simulations with FADE
The main simulation script is `fade/run_experiments.sh`.
You should now be able to run it, which would start the 1760 FADE simulations.

To test if everything works, it is generally a good idea to start with one representative simulation which can be configured at the beginning of the `run_experiments.sh` script, for example:

> MEASUREMENTS=( matrix,platt4-default,icra5,70,b )
> INDIVIDUALS=( P-4000-14 )

The simulations use the default ramdisk in Ubuntu Linux, for which approximately 24Gb space in /dev/shm are needed.
This behavior can be changed with the variable WORKDIR in `fade/fade_simulate.sh`.

Running

> ./run_experiments.sh

in the folder *fade/* will output sparse information on simulation progress.
The simulation log is saved to the file `simulation.log`.
You can use the command `tail -f simulation.log` to follow the simulation log live in a separate terminal window.
Finally, the simulation results will be collected to the results file `results.txt`.


## Evaluation of simulation results
The results file `results.txt` can be copied to the *fade/evaluation* folder.
The `results.txt` from my simulations is provided.

Now, the Octave scripts `play_evaluate.m` and `play_tables.m` can be used to generate the Plomp-curve figures and the table presented in the manuscript.

## Manuscript
The manuscript sources can be found in the folder *manuscript/*

Run

pdflatex ms.tex

to generate a PDF document.
You will probably need to install the texlive-full package.
