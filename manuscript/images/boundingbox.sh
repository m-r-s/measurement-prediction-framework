#!/bin/bash

ls -1 *.eps | while read line; do epstool --bbox --copy "$line"{,.tmp.eps}; mv "$line"{.tmp.eps,};done
