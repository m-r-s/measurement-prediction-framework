/*
 * This file is part of the PLATT reference implementation
 * Author (2018-2020) Marc René Schädler (marc.rene.schaedler@uni-oldenburg.de)
 */

void
calculatedifferences(float const * const layers_ref,
                     float const  * const layers_diff,
                     float * const differences) {
  for (int i=0;i<NUMFILTERS;i++) {
    differences[i] = layers_ref[i] - layers_diff[i];
  }
}
