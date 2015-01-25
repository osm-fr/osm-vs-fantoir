#!/usr/bin/env python
# -*- coding: utf-8 -*-

import cgi
import cgitb
import os.path
import sys
import json
sys.path.append('/data/project/cadastre.openstreetmap.fr/bin/cadastre-housenumber/bano')
from pg_connexion import get_pgc
# from requete_fantoir import get_data_from_pg

def get_data(data_type):
	fq = open(os.path.join(os.path.dirname(os.path.abspath(__file__)),'sql/{:s}.sql'.format(data_type)),'rb')
	str_query = fq.read()
	fq.close()
	pgc = get_pgc()
	cur = pgc.cursor()
	cur.execute(str_query)
	r = cur.fetchall()
	# data = []
	# for lt in cur:
		# l = list(lt)
		# data.append(l)
	# cur.close()
	return r
data = get_data('fantoir_errone')
delta = 0.0008
# print "Content-Type: text/html"
print "Content-Type: application/json"
print ""
# print "<html>\n<head>\n<meta charset=\"UTF-8\">\n<title>Fantoirs erronés</title>\n<link rel=\"stylesheet\" href=\"css/style.css\" type=\"text/css\"/>\n</head>\n<body>"

# for l in data:
	# print("{:s} <a href='http://127.0.0.1:8111/load_and_zoom?left={:f}&right={:f}&top={:f}&bottom={:f}'>JOSM</a> {:s}</br>\n").format(l[0],l[2]-delta,l[2]+delta,l[3]+delta,l[3]-delta,l[1])
# print "\n</body>\n</html>"

a = json.JSONEncoder().encode(data)
print(a)