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
	fq = open('sql/{:s}.sql'.format(data_type),'rb')
	str_query = fq.read().replace('__com__',insee_com)
	fq.close()
	cur = pgc.cursor()
	cur.execute(str_query)
	res = cur.fetchall()
		
	return res
	
print "Content-Type: application/json"
print ""

pgc = get_pgc()
params = cgi.FieldStorage()
data = [get_data_from_pg('voies_adresses_non_rapprochees_insee',params['insee'].value),get_data_from_pg('voies_adresses_rapprochees_insee',params['insee'].value)]

a = json.JSONEncoder().encode(data)

print(a)
