#! /bin/bash
# trim silently but no ext2 because not supoorted
# PvSA 30.5.24 
fstrim -a -t noext2
