#!./venv37/bin/python
# -*- coding: utf-8 -*-

import subprocess
import cgi
import cgitb
import json

from pathlib import Path

cgitb.enable()
params = cgi.FieldStorage()
insee_com = params['insee'].value
    
try:
    subprocess.run([f"{(Path(__file__).resolve().parent / 'refresh.sh')}", insee_com],stdout=subprocess.DEVNULL)
    statut = '1'
except :
    statut = '0'

print ("Content-Type: application/json\n")
print(statut)
