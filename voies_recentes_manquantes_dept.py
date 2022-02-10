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

def format_csv(fetch):
    return ('Département;Code INSEE;Commune;FANTOIR;Voie;Date de création;lon;lat\n'+'\n'.join([f'{c[0]};{c[1]};"{c[2]}";{c[4]};{c[3]};{c[7]};{c[5]};{c[6]}' for c in fetch]))

params = cgi.FieldStorage()
dept = params['dept'].value
format = params.getvalue('format','json')

if format == 'json':
    print("Content-Type: application/json\n")
    print(json.JSONEncoder().encode(get_data('voies_recentes_manquantes_dept',dept)))

if format == 'csv':
    print(f'Content-Type: text/csv\nContent-Disposition: Attachment; filename="Dept {dept} - voies recentes manquantes.csv"\n')
    print(format_csv(get_data('voies_recentes_manquantes_dept',dept)))
