#!./venv37/bin/python
# -*- coding: utf-8 -*-

from sql import sql_get_data

def get_code_dept_from_insee(code_insee):
    code_dept = code_insee[0:2]
    if code_dept == '97':
        code_dept = code_insee[0:3]
    return code_dept

def escape_quotes(s):
    return s.replace('\'','\'\'')

def get_dict_labels():
    labels = sql_get_data('labels_statut_fantoir',{})
    dict_labels = {kv[0]:kv[1] for kv in labels}
    return dict_labels
