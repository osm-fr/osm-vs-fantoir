#!./venv37/bin/python
# -*- coding: utf-8 -*-

import cgi
import cgitb
import json
import sys

import db

def get_data_by_dept(data_type,dept):
    with open('sql/{:s}.sql'.format(data_type),'r') as fq:
        with db.bano.cursor() as cur:
            cur.execute(fq.read().replace('__dept__',f"{dept}"))
            return cur.fetchall()

def get_data_by_dept_like(data_type,dept):
    with open('sql/{:s}.sql'.format(data_type),'r') as fq:
        with db.bano.cursor() as cur:
            cur.execute(fq.read().replace('__dept__',f"{dept}"))
            return cur.fetchall()

def format_csv(fetch):
    return ('Code INSEE\tCommune\tPct certif BAN\tVoies avec adresses rapprochées (a)\tToutes voies rapprochées (b)...\t...dont voies rapprochées sur lieux-dits FANTOIR\tVoies FANTOIR (c)\tVoies et lieux-dits FANTOIR (d)\tVoies avec adresses voies FANTOIR (a/c) en %\tVoies rapprochées voies FANTOIR (b/c) en %\tVoies rapprochées voies et lieux-dits FANTOIR (b/d) en %\tAdresses OSM\tAdresses BAN\tAdresses BAN sans voie rapprochées\tAdresse BAN avec voie rapprochée en %\tIndice 2020\n'+'\n'.join([f'{c[0]}\t{c[1]}\t"{c[2]}"\t{c[3]}\t{c[4]}\t{c[5]}\t{c[6]}\t{c[7]}\t{c[8]}\t{c[9]}\t{c[10]}\t{c[11]}\t{c[12]}\t{c[13]}\t{c[14]}\t{c[15]}' for c in fetch]))

cgitb.enable()
params = cgi.FieldStorage()
dept = params['dept'].value
format = params.getvalue('format','json')

if format == 'json':
    print("Content-Type: application/json\n")
    print(json.JSONEncoder().encode([get_data_by_dept('infos_dept',dept),get_data_by_dept_like('stats_dept',dept)]))

if format == 'csv':
    print(f'Content-Type: text/csv\nContent-Disposition: Attachment; filename="Dept {dept} - statistiques BANO par commune.csv"\n')
    print(format_csv(get_data_by_dept_like('stats_dept',dept)))
