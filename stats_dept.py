#!./venv37/bin/python
# -*- coding: utf-8 -*-

import cgi
import cgitb
import json
import sys

import db

def get_data_by_dept(data_type,dept):
    with open('sql/{:s}.sql'.format(data_type),'r') as fq:
        with db.bano.cursor() as cur:
            cur.execute(fq.read().replace('__dept__',f"{dept}"))
            return cur.fetchall()

def get_data_by_dept_like(data_type,dept):
    with open('sql/{:s}.sql'.format(data_type),'r') as fq:
        with db.bano.cursor() as cur:
            cur.execute(fq.read().replace('__dept__',f"{dept}"))
            return cur.fetchall()

cgitb.enable()
params = cgi.FieldStorage()
dept = params['dept'].value

print("Content-Type: application/json\n")
print(json.JSONEncoder().encode([get_data_by_dept('infos_dept',dept),get_data_by_dept_like('stats_dept',dept)]))