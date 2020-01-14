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
        with db.bano_cache.cursor() as cur:
            cur.execute(fq.read().replace('__dept__',dept))

            return cur.fetchall()

params = cgi.FieldStorage()
dept = params['dept'].value
requete = params['requete'].value
# dept = '92'
# requete = 'maj_population_2017'

print("Content-Type: application/json\n")
print(json.JSONEncoder().encode([get_data('infos_dept',dept),get_data(requete,dept)]))
