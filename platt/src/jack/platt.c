#include <stdio.h>
#include <errno.h>
#include <unistd.h>
#include <stdlib.h>
#include <string.h>
#include <jack/jack.h>
#include <math.h>
#include "constants.h"
#include "variables.h"
#include "gammatonemax.c"
#include "calculatelayers.c"
#include "calculatedifferences.c"
#include "mapbase.c"
#include "checkmaxlevels.c"
#include "spectralmasking.c"
#include "adddynamic.c"
#include "resynthesis.c"
#include "tick.c"

#ifdef CALIBRATE
float rms_in1 = 0.0;
float rms_in2 = 0.0;
float rms_out1 = 0.0;
float rms_out2 = 0.0;
unsigned long int tickcount = 0;
#endif

jack_port_t *input_port1, *input_port2;
jack_port_t *output_port1, *output_port2;
jack_client_t *client;

int
process (jack_nframes_t nframes, void *arg)
{
  jack_default_audio_sample_t *in1, *in2, *out1, *out2;

  in1 = jack_port_get_buffer (input_port1, nframes);
  in2 = jack_port_get_buffer (input_port2, nframes);
  out1 = jack_port_get_buffer (output_port1, nframes);
  out2 = jack_port_get_buffer (output_port2, nframes);

  if (nframes%TICKSAMPLES != 0) {
    printf("ERROR! nframes (%i) no multiple of %i\n",nframes,TICKSAMPLES);
    return 1;
  } else {
    for (int i=0; i<nframes; i+=TICKSAMPLES) {
#ifdef CALIBRATE
// Update rms
      {
        float rms_tmp;
        rms_tmp = 0.0;
        for (int j=0; j<TICKSAMPLES; j++) {
          rms_tmp += pow(in1[i+j],2);
        }
        rms_in1 = rms_in1*0.999 + sqrt(rms_tmp/TICKSAMPLES)*0.001;
        rms_tmp = 0.0;
        for (int i=0; i<TICKSAMPLES; i++) {
          rms_tmp += pow(in2[i+2],2);
        }
        rms_in2 = rms_in2*0.999 + sqrt(rms_tmp/TICKSAMPLES)*0.001;
      }
#endif

      // PROCESS!
      tick(&in1[i], &in2[i], &out1[i], &out2[i]);

#ifdef CALIBRATE
// Update rms
  {
    float rms_tmp;
    rms_tmp = 0.0;
    for (int i=0; i<TICKSAMPLES; i++) {
      rms_tmp += out1[i]*out1[i];
    }
    rms_out1 = rms_out1*0.999 + sqrt(rms_tmp/TICKSAMPLES)*0.001;
    rms_tmp = 0.0;
    for (int i=0; i<TICKSAMPLES; i++) {
      rms_tmp += out2[i]*out2[i];
    }
    rms_out2 = rms_out2*0.999 + sqrt(rms_tmp/TICKSAMPLES)*0.001;
    if (tickcount%1000 == 0) {
      printf("%04.1f  %04.1f  ->  %04.1f  %04.1f\n",LOG2DB*log(rms_in1),LOG2DB*log(rms_in2),LOG2DB*log(rms_out1),LOG2DB*log(rms_out2));
    }
  }
  tickcount++;
#endif
    }
  }
  return 0;
}

/**
 * JACK calls this shutdown_callback if the server ever shuts down or
 * decides to disconnect the client.
 */
void
jack_shutdown (void *arg)
{
	exit (1);
}

int
main (int argc, char *argv[])
{
	const char *client_name = "platt";
	const char *server_name = NULL;
	jack_options_t options = JackNullOption;
	jack_status_t status;
  FILE *fp;

  printf("Next Generation Dynamic Compressor\n");
  // Load GAMMATONE CENTER FREQUENCIES
  fp = fopen("configuration/freqs.bin","rb");
  if(fp == NULL) {
    printf("Error opening 'configuration/freqs.bin'\n");
    return 1;
  }
  fread(freqs,sizeof(freqs),1,fp);
  fclose(fp);

  // Load GAMMATONE FILTER COEFFICIENTS
  fp = fopen("configuration/coeff.bin","rb");
  if(fp == NULL) {
    printf("Error opening 'configuration/coeff.bin'\n");
    return 1;
  }
  fread(coeff,sizeof(coeff),1,fp);
  fclose(fp);

  // Load CALIBRATION
  fp = fopen("configuration/calibration.bin","rb");
  if(fp == NULL) {
    printf("Error opening 'configuration/calibration.bin'\n");
    return 1;
  }
  fread(calibration,sizeof(calibration),1,fp);
  fclose(fp);

  // Load SPECTRAL MASKING
  fp = fopen("configuration/spectralmask.bin","rb");
  if(fp == NULL) {
    printf("Error opening 'configuration/spectralmask.bin'\n");
    return 1;
  }
  fread(spectralmask,sizeof(spectralmask),1,fp);
  fclose(fp);

  // Load LEFT IO
  fp = fopen("configuration/io_left.bin","rb");
  if(fp == NULL) {
    printf("Error opening 'configuration/io_left.bin'\n");
    return 1;
  }
  fread(io1,sizeof(io1),1,fp);
  fclose(fp);

  // Load RIGHT IO
  fp = fopen("configuration/io_right.bin","rb");
  if(fp == NULL) {
    printf("Error opening 'configuration/io_right.bin'\n");
    return 1;
  }
  fread(io2,sizeof(io2),1,fp);
  fclose(fp);

  // Load LEFT GT
  fp = fopen("configuration/gt_left.bin","rb");
  if(fp == NULL) {
    printf("Error opening 'configuration/gt_left.bin'\n");
    return 1;
  }
  fread(gt1,sizeof(gt1),1,fp);
  fclose(fp);

  // Load RIGHT GT
  fp = fopen("configuration/gt_right.bin","rb");
  if(fp == NULL) {
    printf("Error opening 'configuration/gt_right.bin'\n");
    return 1;
  }
  fread(gt2,sizeof(gt2),1,fp);
  fclose(fp);

  // Load LEFT EXPANSION
  fp = fopen("configuration/expansion_left.bin","rb");
  if(fp == NULL) {
    printf("Error opening 'configuration/expansion_left.bin'\n");
    return 1;
  }
  fread(expansion1,sizeof(expansion1),1,fp);
  fclose(fp);

  // Load RIGHT EXPANSION
  fp = fopen("configuration/expansion_right.bin","rb");
  if(fp == NULL) {
    printf("Error opening 'configuration/expansion_right.bin'\n");
    return 1;
  }
  fread(expansion2,sizeof(expansion2),1,fp);
  fclose(fp);

  // Load NORMAL HEARING THRESHOLDS
  fp = fopen("configuration/thresholds_normal.bin","rb");
  if(fp == NULL) {
    printf("Error opening 'configuration/thresholds_normal.bin'\n");
    return 1;
  }
  fread(thresholds_normal,sizeof(thresholds_normal),1,fp);
  fclose(fp);

  // Load NORMAL UNCOMFORTABLE LEVEL
  fp = fopen("configuration/uncomfortable_normal.bin","rb");
  if(fp == NULL) {
    printf("Error opening 'configuration/uncomfortable_normal.bin'\n");
    return 1;
  }
  fread(uncomfortable_normal,sizeof(uncomfortable_normal),1,fp);
  fclose(fp);

  // Load LEFT MAXLEVEL
  fp = fopen("configuration/maxlevel_left.bin","rb");
  if(fp == NULL) {
    printf("Error opening 'configuration/maxlevel_left.bin'\n");
    return 1;
  }
  fread(maxlevel1,sizeof(maxlevel1),1,fp);
  fclose(fp);

  // Load RIGHT MAXLEVEL
  fp = fopen("configuration/maxlevel_right.bin","rb");
  if(fp == NULL) {
    printf("Error opening 'configuration/maxlevel_right.bin'\n");
    return 1;
  }
  fread(maxlevel2,sizeof(maxlevel2),1,fp);
  fclose(fp);

  // Load LEFT MUTE CHANNELS
  fp = fopen("configuration/mute_left.bin","rb");
  if(fp == NULL) {
    printf("Error opening 'configuration/mute_left.bin'\n");
    return 1;
  }
  fread(mute1,sizeof(mute1),1,fp);
  fclose(fp);

  // Load RIGHT MUTE CHANNELS
  fp = fopen("configuration/mute_right.bin","rb");
  if(fp == NULL) {
    printf("Error opening 'configuration/mute_right.bin'\n");
    return 1;
  }
  fread(mute2,sizeof(mute2),1,fp);
  fclose(fp);

  // Load LEFT TRANSMISSION
  fp = fopen("configuration/transmission_left.bin","rb");
  if(fp == NULL) {
    printf("Error opening 'configuration/transmission_left.bin'\n");
    return 1;
  }
  fread(transmission1,sizeof(transmission1),1,fp);
  fclose(fp);

  // Load RIGHT TRANSMISSION
  fp = fopen("configuration/transmission_right.bin","rb");
  if(fp == NULL) {
    printf("Error opening 'configuration/transmission_right.bin'\n");
    return 1;
  }
  fread(transmission2,sizeof(transmission2),1,fp);
  fclose(fp);

  // Load GAIN RATE
  fp = fopen("configuration/gainrate.bin","rb");
  if(fp == NULL) {
    printf("Error opening 'configuration/gainrate.bin'\n");
    return 1;
  }
  fread(gainrate,sizeof(gainrate),1,fp);
  fclose(fp);


#ifdef DEBUG
  printf("\n");
  printf("SAMPLERATE: %i\n",SAMPLERATE);
  printf("NUMFILTERS: %i\n",NUMFILTERS);
  printf("ORDER: %i\n",ORDER);
  printf("TICKSAMPLES: %i\n",TICKSAMPLES);
  printf("TICKSIZE: %i\n",TICKSIZE);
  printf("MAXHOLDTICKS: %i\n",MAXHOLDTICKS);
  printf("MAXDECAY: %.3f\n",MAXDECAY);
  printf("LOG2DB: %.16f\n",LOG2DB);
  printf("NUMLAYERS: %i\n",NUMLAYERS);
  printf("\n");

  for (int i=0;i<NUMFILTERS;i++) {
    printf("freqs[%i] = [%.8f]\n",i,freqs[i]);
  }
  printf("\n");

  for (int i=0;i<4*NUMFILTERS;i+=4) {
    printf("coeff[%i...] = [%.8f %.8f %.8f %.8f]\n",i,coeff[i],coeff[i+1],coeff[i+2],coeff[i+3]);
  }
  printf("\n");

  for (int i=0;i<2*NUMFILTERS;i+=2) {
    printf("calibration[%i...] = [%.8f %.8f]\n",i,calibration[i],calibration[i+1]);
  }
  printf("\n");

  for (int i=0;i<2*NUMFILTERS-1;i++) {
    printf("spectralmask[%i...] = [%.8f]\n",i,spectralmask[i]);
  }
  printf("\n");

  for (int i=0;i<4*NUMFILTERS;i+=4) {
    printf("io1[%i...] = [%.8f %.8f %.8f %.8f]\n",i,io1[i],io1[i+1],io1[i+2],io1[i+3]);
  }
  printf("\n");

  for (int i=0;i<4*NUMFILTERS;i+=4) {
    printf("io2[%i...] = [%.8f %.8f %.8f %.8f]\n",i,io2[i],io2[i+1],io2[i+2],io2[i+3]);
  }
  printf("\n");

  for (int i=0;i<NUMFILTERS*GTLEVELS;i+=GTLEVELS) {
    printf("gt1[%i...] = ");
    for (int j=0;j<GTLEVELS;j++) {
      printf("%.3f ",gt1[i+j]);
    }
    printf("\n");
  }
  printf("\n");

  for (int i=0;i<NUMFILTERS*GTLEVELS;i+=GTLEVELS) {
    printf("gt2[%i...] = ");
    for (int j=0;j<GTLEVELS;j++) {
      printf("%.3f ",gt2[i+j]);
    }
    printf("\n");
  }
  printf("\n");

  for (int i=0;i<NUMFILTERS;i++) {
    printf("expansion1[%i] = [%.8f]\n",i,expansion1[i]);
  }
  printf("\n");

  for (int i=0;i<NUMFILTERS;i++) {
    printf("expansion2[%i] = [%.8f]\n",i,expansion2[i]);
  }
  printf("\n");

  for (int i=0;i<NUMFILTERS;i++) {
    printf("thresholds_normal[%i] = [%.8f]\n",i,thresholds_normal[i]);
  }
  printf("\n");

  for (int i=0;i<NUMFILTERS;i++) {
    printf("uncomfortable_normal[%i] = [%.8f]\n",i,uncomfortable_normal[i]);
  }
  printf("\n");

  for (int i=0;i<NUMFILTERS;i++) {
    printf("maxlevel1[%i] = [%.8f]\n",i,maxlevel1[i]);
  }
  printf("\n");

  for (int i=0;i<NUMFILTERS;i++) {
    printf("maxlevel2[%i] = [%.8f]\n",i,maxlevel2[i]);
  }
  printf("\n");

  for (int i=0;i<NUMFILTERS;i++) {
    printf("mute1[%i] = [%.8f]\n",i,mute1[i]);
  }
  printf("\n");

  for (int i=0;i<NUMFILTERS;i++) {
    printf("mute2[%i] = [%.8f]\n",i,mute2[i]);
  }
  printf("\n");

  for (int i=0;i<NUMFILTERS;i++) {
    printf("transmission1[%i...] = [%.8f]\n",i,transmission1[i]);
  }
  printf("\n");

  for (int i=0;i<NUMFILTERS;i++) {
    printf("transmission2[%i...] = [%.8f]\n",i,transmission2[i]);
  }
  printf("\n");

  for (int i=0;i<NUMFILTERS;i++) {
    printf("gainrate[%i] = [%.8f]\n",i,gainrate[i]);
  }
  printf("\n");

#endif

	/* open a client connection to the JACK server */
	client = jack_client_open (client_name, options, &status, server_name);
	if (client == NULL) {
		fprintf (stderr, "jack_client_open() failed, "
			 "status = 0x%2.0x\n", status);
		if (status & JackServerFailed) {
			fprintf (stderr, "Unable to connect to JACK server\n");
		}
		exit (1);
	}
	if (status & JackServerStarted) {
		fprintf (stderr, "JACK server started\n");
	}
	if (status & JackNameNotUnique) {
		client_name = jack_get_client_name(client);
		fprintf (stderr, "unique name `%s' assigned\n", client_name);
	}

  // Check if we are in spec
  if (jack_get_sample_rate (client) != SAMPLERATE) {
    fprintf (stderr, "sample rate (%i!=%i) not supported!\n", jack_get_sample_rate (client), SAMPLERATE);
   	exit (1);
  }

	/* tell the JACK server to call `process()' whenever
	   there is work to be done.
	*/

	jack_set_process_callback (client, process, 0);

	/* tell the JACK server to call `jack_shutdown()' if
	   it ever shuts down, either entirely, or if it
	   just decides to stop calling us.
	*/

	jack_on_shutdown (client, jack_shutdown, 0);

	/* display the current sample rate. 
	 */

	printf ("engine sample rate: %" PRIu32 "\n",
		jack_get_sample_rate (client));

	/* create two ports */

	input_port1 = jack_port_register (client, "input_1",
					 JACK_DEFAULT_AUDIO_TYPE,
					 JackPortIsInput, 0);
	input_port2 = jack_port_register (client, "input_2",
					 JACK_DEFAULT_AUDIO_TYPE,
					 JackPortIsInput, 0);

	output_port1 = jack_port_register (client, "output_1",
					  JACK_DEFAULT_AUDIO_TYPE,
					  JackPortIsOutput, 0);
	output_port2 = jack_port_register (client, "output_2",
					  JACK_DEFAULT_AUDIO_TYPE,
					  JackPortIsOutput, 0);

	if ((input_port1 == NULL) || (input_port2 == NULL) || (output_port1 == NULL) || (output_port2 == NULL) ) {
		fprintf(stderr, "no more JACK ports available\n");
		exit (1);
	}

	/* Tell the JACK server that we are ready to roll.  Our
	 * process() callback will start running now. */

	if (jack_activate (client)) {
		fprintf (stderr, "cannot activate client");
		exit (1);
	}

	/* keep running until stopped by the user */

	sleep (-1);

	/* this is never reached but if the program
	   had some other way to exit besides being killed,
	   they would be important to call.
	*/

	jack_client_close (client);
	exit (0);
}
