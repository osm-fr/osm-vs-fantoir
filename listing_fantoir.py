#!/usr/bin/env python
# -*- coding: utf-8 -*-

import cgi
import cgitb
import json
import sys
sys.path.append('/data/project/cadastre.openstreetmap.fr/bin/cadastre-housenumber/bano')
from pg_connexion import get_pgc
from requete_fantoir import get_data_from_pg

cgitb.enable()
print "Content-Type: application/json"
print ""

pgc = get_pgc()
params = cgi.FieldStorage()
insee_com = params['insee'].value

infos_commune = get_data_from_pg(pgc,'infos_commune_insee',insee_com)
if infos_commune:
	nom_commune = infos_commune[0][0]
else:
	nom_commune = []

str_query = "SELECT code_insee||id_voie||cle_rivoli,* FROM fantoir_voie WHERE code_insee = '{:s}';".format(insee_com)
cur = pgc.cursor()
cur.execute(str_query)
r = cur.fetchall()
a = json.JSONEncoder().encode([[nom_commune],r])
print(a)