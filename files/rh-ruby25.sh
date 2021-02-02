#!/bin/bash
source /opt/rh/rh-ruby25/enable
export X_SCLS="`scl enable rh-ruby25 'echo $X_SCLS'`"
export PATH=$PATH:/opt/rh/rh-ruby25/root/usr/bin
