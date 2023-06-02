#!/bin/bash

source /data/work/vdct/bano_venv_v3/bin/activate

SCRIPT_DIR=/data/project/bano_v3
cd $SCRIPT_DIR
source config
bano rapprochement --code_insee ${1}
