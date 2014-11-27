#!/usr/bin/env python
# -*- coding: utf-8 -*-

import cgi
import cgitb
import json
import sys
sys.path.append('/data/project/cadastre.openstreetmap.fr/bin/cadastre-housenumber/bano')
from pg_connexion import get_pgc


cgitb.enable()
print "Content-Type: application/json"
print ""

pgc = get_pgc()
params = cgi.FieldStorage()
insee_com = params['insee'].value
statut = params['statut'].value
fantoir = params['fantoir'].value

try:
	str_insert = "INSERT INTO statut_fantoir VALUES ('{:s}',{:s},(select extract(epoch from now()))::integer,'{:s}');COMMIT;".format(fantoir,statut,insee_com);
	cur = pgc.cursor()
	cur.execute(str_insert)
except:
	statut = -1

a = json.JSONEncoder().encode(statut)
print(a)
