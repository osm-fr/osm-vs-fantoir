#!./venv37/bin/python
# -*- coding: utf-8 -*-

import cgi
import cgitb
import os.path
import sys
import json

import db

def get_data(data_type,dept):
    with open(os.path.join(os.path.dirname(os.path.abspath(__file__)),'sql/{:s}.sql'.format(data_type)),'r') as fq:
        with db.bano.cursor() as cur:
            cur.execute(fq.read().replace('__dept__',dept))

            return cur.fetchall()

params = cgi.FieldStorage()
dept = params['dept'].value

print("Content-Type: application/json\n")
print(json.JSONEncoder().encode(get_data('voies_recentes_manquantes_dept',dept)))
