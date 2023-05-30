#!/bin/bash

source ./venv37/bin/activate

SCRIPT_DIR=/data/project/bano_v3
cd $SCRIPT_DIR

source config

pip install -qqe .
bano rapprochement --code_insee ${1}
