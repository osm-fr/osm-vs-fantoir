#!./venv37/bin/python
# -*- coding: utf-8 -*-

import cgi
import cgitb
import json

import helpers as hp
import db
from sql import sql_get_data

cgitb.enable()

print("Content-Type: application/json\n")
print(json.JSONEncoder().encode(sql_get_data('commune_random',dict())))

