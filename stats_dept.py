#!/usr/bin/env python
# -*- coding: utf-8 -*-

import cgi
import cgitb
import json
import sys
sys.path.append('/data/project/cadastre.openstreetmap.fr/bin/cadastre-housenumber/bano')
from pg_connexion import get_pgc
from requete_fantoir import get_data_from_pg

def get_data_by_dept(data_type,dept):
	fq = open('sql/{:s}.sql'.format(data_type),'rb')
	str_query = fq.read().replace('__dept__','{:s}'.format(dept))
	fq.close()
	cur = pgc.cursor()
	cur.execute(str_query)
	r = cur.fetchall()
	return r
def get_data_by_dept_like(data_type,dept):
	fq = open('sql/{:s}.sql'.format(data_type),'rb')
	str_sql_dept_like = (dept+'___')[0:5]
	str_query = fq.read().replace('__dept__','{:s}'.format(str_sql_dept_like))
	fq.close()
	cur = pgc.cursor()
	cur.execute(str_query)
	r = cur.fetchall()
	return r
cgitb.enable()
print "Content-Type: application/json"
print ""

pgc = get_pgc()
params = cgi.FieldStorage()
dept = params['dept'].value
d = get_data_by_dept('infos_dept',dept)
r = get_data_by_dept_like('stats_dept',dept)
a = json.JSONEncoder().encode([d,r])
print(a)