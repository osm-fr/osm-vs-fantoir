#!./venv37/bin/python
# -*- coding: utf-8 -*-

import cgi
import cgitb
import os.path
import sys
import json

import db

def get_data(data_type,insee,fantoir):
    with open(os.path.join(os.path.dirname(os.path.abspath(__file__)),'sql/{:s}.sql'.format(data_type)),'r') as fq:
        with db.bano.cursor() as cur:
            cur.execute(fq.read().replace('__com__',insee).replace('__fantoir__',fantoir))

            return cur.fetchall()

params = cgi.FieldStorage()
# insee = '95219'
# fantoir = '952191024B'
# dept = '92'
insee = params['insee'].value
fantoir = params['fantoir'].value
requete = 'inspect_numeros'

print("Content-Type: application/json\n")
print(json.JSONEncoder().encode(get_data(requete,insee,fantoir)))
