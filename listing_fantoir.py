#!./venv37/bin/python
# -*- coding: utf-8 -*-

import cgi
import cgitb
import json

from requete_fantoir import get_data_from_bano, get_data_from_bano_cache

cgitb.enable()
print ("Content-Type: application/json\n\n")

params = cgi.FieldStorage()
insee_com = params['insee'].value
# insee_com = '85047'

infos_commune = get_data_from_bano_cache('infos_commune_insee',insee_com)
if infos_commune:
	nom_commune = infos_commune[0][0]
else:
	nom_commune = []

print(json.JSONEncoder().encode([[nom_commune],get_data_from_bano('listing_fantoir',insee_com)]))