#!/usr/bin/env python
# -*- coding: utf-8 -*-

import sys
sys.path.append('/data/project/cadastre.openstreetmap.fr/bin/cadastre-housenumber/bano')
import addr_2_db as a
import place_2_db as p
import log_2_file as e
import outils_de_gestion as o
import os,os.path
import codecs
import cgi
import cgitb

cgitb.enable()

# Wrap sys.stdout with a writer that knows how to handle encoding
# Unicode data.
wrapped_stdout = codecs.getwriter('UTF-8')(sys.stdout)
# Replace sys.stdout with a writer
sys.stdout = wrapped_stdout

def get_cadastre_format(pgc,insee):
	format_cadastre = None
	str_query = "SELECT format_cadastre FROM code_cadastre WHERE insee_com = '{:s}';".format(insee)
	cur = pgc.cursor()
	cur.execute(str_query)
	if cur:
		r = cur.fetchone()
		format_cadastre = r[0]
	return format_cadastre

def main():
	print "Content-Type: application/json"
	print ""
	
	params = cgi.FieldStorage()
	insee_com = params['insee'].value
	pgc = a.get_pgc()
	format_cadastre = get_cadastre_format(pgc,insee_com)
	try:
		a.main(['',insee_com,'OSM',False])
		if format_cadastre == 'VECT':
			a.main(['',insee_com,'CADASTRE',False])
		p.main(['',insee_com])
		statut = '1'
	except :
		statut = '0'
	print(statut)
if __name__ == '__main__':
    main()
