#!/bin/bash

source /data/work/vdct/bano_venv37/bin/activate

SCRIPT_DIR=/data/project/bano_prod
cd $SCRIPT_DIR

source config

pip install -qqe .

bano ban2fantoir --code_insee ${1}
bano process_commune OSM --code_insee ${1}
bano process_commune BAN --code_insee ${1}
bano process_commune_lieux-dits --code_insee ${1}