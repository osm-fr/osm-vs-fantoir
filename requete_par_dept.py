#!./venv37/bin/python
# -*- coding: utf-8 -*-

import cgi
import cgitb
import os.path
import sys
import json

import db

def get_data(data_type,dept,cache_db):
    if cache_db:
        dbconn = db.bano_cache
    else:
        dbconn = db.bano
    with open(os.path.join(os.path.dirname(os.path.abspath(__file__)),'sql/{:s}.sql'.format(data_type)),'r') as fq:
        with dbconn.cursor() as cur:
            cur.execute(fq.read().replace('__dept__',dept))

            return cur.fetchall()

cache = True
params = cgi.FieldStorage()
dept = params['dept'].value
requete = params['requete'].value

if 'cache' in params:
    cache = not(params['cache'].value.lower() == 'false')

# requete = 'top_adresses_manquantes'
# dept = '92'

print("Content-Type: application/json\n")
print(json.JSONEncoder().encode([get_data('infos_dept',dept,True),get_data(requete,dept,cache)]))
