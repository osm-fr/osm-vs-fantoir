#!/usr/bin/env python
# -*- coding: utf-8 -*-

import cgi
import cgitb
import os.path
import sys
import json
sys.path.append('/data/project/cadastre.openstreetmap.fr/bin/cadastre-housenumber/bano')
from pg_connexion import get_pgc

def get_data(data_type,dept):
	fq = open(os.path.join(os.path.dirname(os.path.abspath(__file__)),'sql/{:s}.sql'.format(data_type)),'rb')
	str_query = fq.read().replace('__dept__',dept)
	fq.close()
	pgc = get_pgc()
	cur = pgc.cursor()
	try:
		cur.execute(str_query)
	except psycopg2.Error, e:
		return (e.diag.severity)
	r = cur.fetchall()
	return (r)
def main():
	params = cgi.FieldStorage()
	dept = params['dept'].value
	print "Content-Type: application/json"
	print ""
	# data_type = 'voies_recentes_manquantes_dept'
	data = get_data('voies_recentes_manquantes_dept',dept)
	a = json.JSONEncoder().encode(data)
	print(a)
if __name__ == '__main__':
    main()