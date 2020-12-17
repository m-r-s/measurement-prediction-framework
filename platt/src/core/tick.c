/*
 * This file is part of the PLATT reference implementation
 * Author (2018-2020) Marc René Schädler (marc.rene.schaedler@uni-oldenburg.de)
 */

#ifdef PERFDEBUG
#include <time.h>
struct timeval t0, t1, t2;
#endif

int
tick(float const * const in1, float const * const in2, float * const out1, float * const out2)
{
  
#ifdef PERFDEBUG
printf("[PERFDEBUG]");
gettimeofday(&t1, NULL);
t0 = t1;
#endif

// Gammatonemax
  gammatonemax(coeff,
               calibration,
               thresholds_normal,
               in1,
               state1,
               buffer1,
               maxima1,
               age1);
  gammatonemax(coeff,
               calibration,
               thresholds_normal,
               in2,
               state2,
               buffer2,
               maxima2,
               age2);

#ifdef PERFDEBUG
gettimeofday(&t2, NULL);
printf(" gt=%04.0f",(double) (t2.tv_usec - t1.tv_usec));
gettimeofday(&t1, NULL);
#endif

// Calculate layers
  for (int i=0;i<NUMLAYERS;i++) {
    calculatelayers(maxima1,
                    &layerbuffer1[i*2*NUMFILTERS],
                    &layers1[i*NUMFILTERS],
                    i);
  }
  for (int i=0;i<NUMLAYERS;i++) {
    calculatelayers(maxima2,
                    &layerbuffer2[i*2*NUMFILTERS],
                    &layers2[i*NUMFILTERS],
                    i);
  }

#ifdef PERFDEBUG
gettimeofday(&t2, NULL);
printf(" cl=%04.0f",(double) (t2.tv_usec - t1.tv_usec));
gettimeofday(&t1, NULL);
#endif

// Calculate differences
  for (int i=0;i<NUMLAYERS-1;i++) {
    calculatedifferences(&layers1[i*NUMFILTERS],
                         &layers1[(i+1)*NUMFILTERS],
                         &differences1[i*NUMFILTERS]);
  }
  for (int i=0;i<NUMLAYERS-1;i++) {
    calculatedifferences(&layers2[i*NUMFILTERS],
                         &layers2[(i+1)*NUMFILTERS],
                         &differences2[i*NUMFILTERS]);
  }

#ifdef PERFDEBUG
gettimeofday(&t2, NULL);
printf(" cd=%04.0f",(double) (t2.tv_usec - t1.tv_usec));
gettimeofday(&t1, NULL);
#endif

// MAP BASE
  mapbase(&layers1[(NUMLAYERS-1)*NUMFILTERS],
          gt1,
          target1);
  mapbase(&layers2[(NUMLAYERS-1)*NUMFILTERS],
          gt2,
          target2);

#ifdef PERFDEBUG
gettimeofday(&t2, NULL);
printf(" mb=%04.0f",(double) (t2.tv_usec - t1.tv_usec));
gettimeofday(&t1, NULL);
#endif

// Check max levels
  checkmaxlevels(mute1,
                 maxlevel1,
                 target1);
  checkmaxlevels(mute2,
                 maxlevel2,
                 target2);

// Avoid spectral masking in output taking transmission loss into account
  spectralmasking(spectralmask,
                  transmission1,
                  spectralbuffer,
                  transmissionbuffer,
                  target1);
  spectralmasking(spectralmask,
                  transmission2,
                  spectralbuffer,
                  transmissionbuffer,
                  target2);

// Check max levels again
  checkmaxlevels(mute1,
                 maxlevel1,
                 target1);
  checkmaxlevels(mute2,
                 maxlevel2,
                 target2);

#ifdef PERFDEBUG
gettimeofday(&t2, NULL);
printf(" sm=%04.0f",(double) (t2.tv_usec - t1.tv_usec));
gettimeofday(&t1, NULL);
#endif

  for (int i=0;i<NUMLAYERS-1;i++) {
    adddynamic(&differences1[i*NUMFILTERS],
               expansion1,
               spectralbuffer,
               compressionbuffer,
               compression,
               maxlevel1,
               io1,
               target1,
               i);
  }
  for (int i=0;i<NUMLAYERS-1;i++) {
    adddynamic(&differences2[i*NUMFILTERS],
               expansion2,
               spectralbuffer,
               compressionbuffer,
               compression,
               maxlevel2,
               io2,
               target2,
               i);
#ifdef PERFDEBUG
    gettimeofday(&t2, NULL);
    printf(" ad%i=%04.0f",i,(double) (t2.tv_usec - t1.tv_usec));
    gettimeofday(&t1, NULL);
#endif
  }

// Resynthesis
  resynthesis(calibration,
              gainrate,
              buffer1,
              maxima1,
              target1,
              gain1,
              out1);
  resynthesis(calibration,
              gainrate,
              buffer2,
              maxima2,
              target2,
              gain2,
              out2);

#ifdef PERFDEBUG
gettimeofday(&t2, NULL);
printf(" rs=%04.0f t=%04.0f",(double) (t2.tv_usec - t1.tv_usec),(double) (t2.tv_usec - t0.tv_usec));
printf("\n");
#endif
	return 0;
}
