#!./venv37/bin/python
# -*- coding: utf-8 -*-

import json

from sql import sql_get_data

print("Content-Type: application/json\n")
print(json.JSONEncoder().encode(sql_get_data('voies_a_cheval_stats',dict())))
