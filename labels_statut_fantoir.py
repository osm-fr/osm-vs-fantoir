#!./venv37/bin/python
# -*- coding: utf-8 -*-

import cgi
import cgitb
import json

import db


cgitb.enable()
print ("Content-Type: application/json")
print ("")

with db.bano_db.cursor() as cur:
    cur.execute("SELECT id_statut,label_statut FROM labels_statuts_fantoir ORDER BY tri;")
    print(json.JSONEncoder().encode(cur.fetchall()))
