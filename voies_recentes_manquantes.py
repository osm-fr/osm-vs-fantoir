#!/usr/bin/env python
# -*- coding: utf-8 -*-

import cgi
import cgitb
import os.path
import sys
import json
sys.path.append('/data/project/cadastre.openstreetmap.fr/bin/cadastre-housenumber/bano')
from pg_connexion import get_pgc

def get_data(data_type):
	fq = open(os.path.join(os.path.dirname(os.path.abspath(__file__)),'sql/{:s}.sql'.format(data_type)),'rb')
	str_query = fq.read()
	fq.close()
	pgc = get_pgc()
	cur = pgc.cursor()
	cur.execute(str_query)
	r = cur.fetchall()
	return r
data = get_data('voies_recentes_manquantes')
a = json.JSONEncoder().encode(data)
f = open('./json/voies_recentes_manquantes.json','wb')
# f.write("Content-Type: application/json\n\n")
f.write(a)
f.close()
