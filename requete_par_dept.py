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

def format_csv(fetch):
    return ('Département;Code INSEE;Commune;FANTOIR;Voie;Adresses à intégrer;lon;lat\n'+'\n'.join([f'{c[0]};{c[1]};"{c[2]}";{c[4]};{c[3]};{c[7]};{c[5]};{c[6]}' for c in fetch]))

cache = True
params = cgi.FieldStorage()
dept = params['dept'].value
requete = params['requete'].value
format = params.getvalue('format','json')

if 'cache' in params:
    cache = not(params['cache'].value.lower() == 'false')

if format == 'json':
    print("Content-Type: application/json\n")
    print(json.JSONEncoder().encode([get_data('infos_dept',dept,True),get_data(requete,dept,cache)]))

if format == 'csv':
    print(f'Content-Type: text/csv\nContent-Disposition: Attachment; filename="Dept {dept} - top adresses manquantes.csv"\n')
    print(format_csv(get_data(requete,dept,cache)))
