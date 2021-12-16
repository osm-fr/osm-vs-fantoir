#!./venv37/bin/python
# -*- coding: utf-8 -*-

import cgi
import cgitb
# import os.path
import sys
import json

import db

def get_data_from_pg(conn,data_type,substitutions):
    with conn.cursor() as cur:
        with open(f"sql/{data_type}.sql",'r') as fq:
            str_query = fq.read()
            for s in substitutions:
                str_query = str_query.replace(s[0],s[1])
            # print(str_query)
            cur.execute(str_query)
            return cur.fetchall()

params = cgi.FieldStorage()
dept = params['dept'].value
# dept = '29'

data = get_data_from_pg(db.bano_cache,'anomalies_fantoir',[['__dept__',dept]])
# data = get_data_from_pg(db.bano_cache,'anomalies_fantoir_point',[['__dept__',dept]])
# data_ligne = get_data(db.bano_cache,'anomalies_fantoir_ligne',[[dept,'__dept__']])
# data_polygone = get_data(db.bano_cache,'anomalies_fantoir_polygone',[[dept,'__dept__']])
# data_relation = get_data(db.bano_cache,'anomalies_fantoir_relation',[[dept,'__dept__']])

print("Content-Type: application/json\n")

print(json.JSONEncoder().encode(data))