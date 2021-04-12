#!./venv37/bin/python
# -*- coding: utf-8 -*-

import cgi
import cgitb
import os.path
import sys
import json

import db

def get_data(lon,lat):
    dbconn = db.bano_cache

    with open(os.path.join(os.path.dirname(os.path.abspath(__file__)),'sql/insee_from_coords.sql'),'r') as fq:
        with dbconn.cursor() as cur:
            cur.execute(fq.read().replace('__lon__',lon).replace('__lat__',lat))

            return cur.fetchone()

params = cgi.FieldStorage()
lon = params['lon'].value
lat = params['lat'].value

print("Content-Type: application/json\n")
print(json.JSONEncoder().encode(get_data(lon,lat)))
