#!./venv37/bin/python
# -*- coding: utf-8 -*-

import cgi
import cgitb
import json
import sys

import db

cgitb.enable()
print("Content-Type: application/json\n")

params = cgi.FieldStorage()
insee_com = params['insee'].value
statut = params['statut'].value
fantoir = params['fantoir'].value
numero = params['numero'].value
source = params['source'].value

try:
    with db.bano_db.cursor() as cur:
        cur.execute(f"INSERT INTO statut_numero VALUES ('{numero}','{fantoir}','{source}',{statut},(SELECT EXTRACT(epoch from now())::integer),'{insee_com}');")
except:
	statut = -1

print(json.JSONEncoder().encode(statut))
