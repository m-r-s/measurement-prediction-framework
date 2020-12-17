# Measurement and prediction framework
This expert software framework can be used to implement, perform, and simulate (i.e. model) simple psychoacoustic and speech-recognition experiments.
Measurements and simulations are tightly integrated, such that all implemented measurements can be performed and simulated with the same code base.
The implementations are modular, such that they can be exchanged or used in other contexts.

Author (2020) Marc René Schädler

E-mail: marc.rene.schaedler@uni-oldenburg.de

The repository currently contains a largely undocumented (but fully functional) code drop.
The documentation will be added on demand over time.
Please contact me if you are interested in the documentation of a specific portion.
This software was developed and tested under Ubuntu Linux 19.10.


## Warning and disclaimer
First, a few words of warning:

Hearing aids are medical products!
You use these instructions and the software at you own risk.
Some audio playback devices can produce very high sound levels.
**Exposure to high sound levels can permanently damage your hearing!**
*You* are responsible for the configuration of the device and the protection of your hearing.

Please read about the consequences of noise induced hearing loss before proceeding to the fun part: https://www.nidcd.nih.gov/health/noise-induced-hearing-loss


## Measurements with EMA
Measurements are performed with the Essential Measurement Applications (EMA).
Simple psychoacoustic and speech-recognition experiments are supported.
The scripts reside in `ema`.
The main application script is `ema/ema.sh`, which starts the console based user interface.
The measurements are implemented in GNU/Octave scripts (`ema/mfiles/measure_*`).
Results are documented in `ema/data`.

The EMA are part of this repository and require, at least, the following software packages to work (maybe I forgot some):
> sudo apt install build-essential gawk octave octave-signal liboctave-dev jackd2 libjack-jackd2-dev

Some example measurements conditions are defined in `ema/ema.sh`.
Also, you need to set your audio device name there.
You can get a list of available audio devices it with the command:
> aplay -l

However, your audio setup needs to be calibrated before using it.


## Calibration
The calibration and compensation tools reside in `loop`.
Please have a look at the `loop/tools/update_configuration.m`.
The parameters for the calibration of your setup can be set there.
Comment out the line which deliberately throws an error.

The provided configuration works well for the Focusrite Scarlett 2i2 sound card and Sennheiser HDA 200 headphones.
`ema/ema.sh` provides a menu for checking the calibration with narrow band noise signals.

In any case, you will need to run update the configuration of loop and compile the required binaries.

To do so, run:
> ./make.sh


## Simulations with FADE
Simulations are performed with the Simulation Framework for Auditory Discrimination Experiments (FADE) from [1].

Set up the simulation framework for auditory discrimination experiments (FADE) as described on the [project website](https://github.com/m-r-s/fade#installation).

The FADE-related scripts reside in `fade`.
The main simulation script is `fade/run_experiments.sh`, where some working examples are defined.
This script can be run in any directory, preferably one on a fast solid-state disk.
The results are collected to `results.txt` in that directory after the simulation.

The same code that is used to describe the measurement condition in EMA (e.g., sweepinnoise-500,l for a sweep in noise detection threshold at 500 Hz with the left ear) can be used there to perform the simulation of the experiment.


## Available experiments
Currently, three measurements are implemented: Sweep detection in quiet, sweep detection in noise, and the German matrix sentence test.

The tone detection experiments are implemented with the [Single-Interval Adjustment Matrix (SIAM) toolkit](https://github.com/m-r-s/siam-toolkit) from [2].
However, the implementation is included in this repository.

The stimuli for the matrix sentence test need to be copied to `ema/data/matrix/speech` (cf. README.md there), and desired noise maskers to `ema/data/matrix/noise`.
The stimulus generation scripts for the tone detection experiments reside in `ema/data/stimulus`.


## Available hearing aid models
For aided measurements or simulations, a working installation of the [open Master Hearing Aid](http://openmha.org) from [3] is required.
In this way, it is possible to share configurations with the [mobile hearing aid prototype](https://github.com/m-r-s/hearingaid-prototype).
Please have a look at the preconfigured example in `data/processing/openMHA9_unaided`.

All measurements can be combined with all hearing device models, which allows to measure the aided performance in psychoacoustic and speech recognition tasks.

It is also easy to extend the framework with own JACK plugins for aided measurements.
For example the [PLATT dynamic compressor](https://github.com/m-r-s/platt) is also available.
PLATT is an implementation of a [patented dynamic compression scheme](https://www.innowi.de/de/unsere_patente/details/dynamikkompression-uol169) that aims to preserve speech intelligibility.
Its engineered towards the use in hearing devices (it's fast).
Still, it produces high quality signals (it minimizes compression).

# References
[1] Schädler, M. R., Warzybok, A., Ewert, S. D., Kollmeier, B. (2016) "A simulation framework for auditory discrimination experiments: Revealing the importance of across-frequency processing in speech perception", Journal of the Acoustical Society of America, Volume 139, Issue 5, pp. 2708–2723, URL: http://link.aip.org/link/?JAS/139/2708

[2] Kaernbach, C. (1990). A single‐interval adjustment‐matrix (SIAM) procedure for unbiased adaptive testing. The Journal of the Acoustical Society of America, 88(6), 2645-2655. https://doi.org/10.1121/1.399985

[3] Herzke, T., Kayser, H., Loshaj, F., Grimm, G., Hohmann, V. "Open signal processing software platform for hearing aid research (openMHA)", in Proceedings of the Linux Audio Conference. Université Jean Monnet, Saint-Étienne, pp. 35-42, 2017.


