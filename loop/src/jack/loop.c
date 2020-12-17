#include <stdio.h>
#include <errno.h>
#include <unistd.h>
#include <stdlib.h>
#include <string.h>
#include <jack/jack.h>
#include <math.h>
#include "constants.h"
#include "variables.h"
#include "filter.c"

#define DEBUG 1

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
      // PROCESS!
      filter(&in1[i], &out1[i], inputbuffer1, impulseresponse1, range1, limit);
      filter(&in2[i], &out2[i], inputbuffer2, impulseresponse2, range2, limit);
      tickcount = (tickcount+1)%FILTERLENGTH;
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
	const char *client_name = "loop";
	const char *server_name = NULL;
	jack_options_t options = JackNullOption;
	jack_status_t status;
  FILE *fp;

  printf("Compensation Filter Loop\n");
  
  // Load filter coefficients
  fp = fopen("configuration/impulseresponse1.bin","rb");
  if(fp == NULL) {
    printf("Error opening 'configuration/impulseresponse1.bin'\n");
		exit (1);
  }
  fread(impulseresponse1,sizeof(impulseresponse1),1,fp);
  fclose(fp);
  fp = fopen("configuration/impulseresponse2.bin","rb");
  if(fp == NULL) {
    printf("Error opening 'configuration/impulseresponse2.bin'\n");
		exit (1);
  }
  fread(impulseresponse2,sizeof(impulseresponse2),1,fp);
  fclose(fp);

  // Load FILTER RANGE
  fp = fopen("configuration/range1.bin","rb");
  if(fp == NULL) {
    printf("Error opening 'configuration/range1.bin'\n");
		exit (1);
  }
  fread(range1,sizeof(range1),1,fp);
  fclose(fp);
  fp = fopen("configuration/range2.bin","rb");
  if(fp == NULL) {
    printf("Error opening 'configuration/range2.bin'\n");
		exit (1);
  }
  fread(range2,sizeof(range2),1,fp);
  fclose(fp);

  // Load clipping limit
  fp = fopen("configuration/limit.bin","rb");
  if(fp == NULL) {
    printf("Error opening 'configuration/limit.bin'\n");
		exit (1);
  }
  fread(limit,sizeof(limit),1,fp);
  fclose(fp);
    
#ifdef DEBUG
  printf("\n");
  printf("SAMPLERATE: %i\n",SAMPLERATE);
  printf("TICKSAMPLES: %i\n",TICKSAMPLES);
  printf("FILTERLENGTH: %i\n",FILTERLENGTH);
  printf("range1[0,1] = [%i %i]\n",range1[0],range1[1]);
  printf("range2[0,1] = [%i %i]\n",range2[0],range2[1]);
  printf("limit = %.8f\n",limit[0]);
  printf("\n");

  for (int i=0;i<TICKSAMPLES*FILTERLENGTH;i++) {
    printf("impulseresponse1[%i] = [%.8f]\n",i,impulseresponse1[i]);
  }
  printf("\n");
  for (int i=0;i<TICKSAMPLES*FILTERLENGTH;i++) {
    printf("impulseresponse2[%i] = [%.8f]\n",i,impulseresponse2[i]);
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
