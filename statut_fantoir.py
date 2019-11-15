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

try:
    with db.bano.cursor() as cur:
        cur.execute(f"INSERT INTO statut_fantoir VALUES ('{fantoir}',{statut},(SELECT EXTRACT(epoch from now())::integer),'{insee_com}');COMMIT;")
except:
	statut = -1

print(json.JSONEncoder().encode(statut))
