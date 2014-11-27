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

str_query = "SELECT id_statut,label_statut FROM labels_statuts_fantoir ORDER BY tri;"
cur = pgc.cursor()
cur.execute(str_query)
r = cur.fetchall()
a = json.JSONEncoder().encode(r)
print(a)
