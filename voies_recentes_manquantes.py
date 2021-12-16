#!./venv37/bin/python
# -*- coding: utf-8 -*-

import cgi
import cgitb
import os.path
import sys
import json

import db

def get_data(data_type):
    with open(os.path.join(os.path.dirname(os.path.abspath(__file__)),'sql/{:s}.sql'.format(data_type)),'r') as fq:
        with db.bano.cursor() as cur:
            cur.execute(fq.read())

            return cur.fetchall()

data = get_data('voies_recentes_manquantes')
a = json.JSONEncoder().encode(data)
f = open('./json/voies_recentes_manquantes.json','w')
f.write(a)
f.close()
