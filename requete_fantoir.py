#!/usr/bin/env python
# -*- coding: utf-8 -*-

import cgi
import cgitb
import json
import sys
sys.path.append('/data/project/cadastre.openstreetmap.fr/bin/cadastre-housenumber/bano')
from pg_connexion import get_pgc

cgitb.enable()
def get_data_from_pg(data_type,insee_com):
	a_res = []
	fq = open('sql/{:s}.sql'.format(data_type),'rb')
	str_raw_query = fq.read().replace('__com__',insee_com)
	fq.close()
	str_query = str_raw_query.replace('__null__clause__','NULL')
	cur = pgc.cursor()
	cur.execute(str_query)
	res = cur.fetchall()
	a_res.append(res)
	str_query = str_raw_query.replace('__null__clause__','NOT NULL')
	cur = pgc.cursor()
	cur.execute(str_query)
	res = cur.fetchall()
	a_res.append(res)
	
	# res = []
	# for lt in cur:
		# res.append(eval(list(lt)))
		
	return a_res
	
print "Content-Type: application/json"
print ""

pgc = get_pgc()
params = cgi.FieldStorage()
a = json.JSONEncoder().encode(get_data_from_pg('voie_insee',params['insee'].value))

print(a)
