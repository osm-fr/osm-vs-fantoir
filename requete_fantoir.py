#!/usr/bin/env python
# -*- coding: utf-8 -*-

import cgi
import cgitb
import json
import sys
sys.path.append('/data/project/cadastre.openstreetmap.fr/bin/cadastre-housenumber/bano')
from pg_connexion import get_pgc
from addr_2_db import get_code_cadastre_from_insee

cgitb.enable()
def get_code_dept_from_insee(insee_com):
	code_dept = insee_com[0:2]
	if insee_com[0:2] == '97':
		code_dept = insee_com[0:3]
	return code_dept
def get_data_from_pg(data_type,insee_com):
	fq = open('sql/{:s}.sql'.format(data_type),'rb')
	str_query = fq.read().replace('__com__',insee_com)
	fq.close()
	cur = pgc.cursor()
	cur.execute(str_query)
	res = cur.fetchall()
	return res
def get_fin_etape(etape,cadastre_com):
	fq = open('sql/fin_etape_cadastre_com.sql','rb')
	str_query = fq.read().replace('__cadastre_com__',cadastre_com).replace('__etape__',etape)
	fq.close()
	cur = pgc.cursor()
	cur.execute(str_query)
	res = cur.fetchall()
	return res
def get_fin_etape_dept(etape,dept):
	fq = open('sql/date_cache_dept.sql','rb')
	str_query = fq.read().replace('__dept__',dept).replace('__etape__',etape)
	fq.close()
	cur = pgc.cursor()
	cur.execute(str_query)
	res = cur.fetchall()
	return res
print "Content-Type: application/json"
print ""

pgc = get_pgc()
params = cgi.FieldStorage()
insee_com = params['insee'].value
cadastre_com = get_code_cadastre_from_insee(insee_com)
dept = get_code_dept_from_insee(insee_com)

nom_commune = get_data_from_pg('nom_commune_insee',insee_com)
if nom_commune:
	nom_commune = nom_commune[0][0]
else:
	nom_commune = []
date_import_cadastre = ''
date_fin_cumul = ['','']
if cadastre_com:
	fin_etape = get_fin_etape('recupCadastre',cadastre_com)
	if fin_etape:
		date_import_cadastre = fin_etape
	fin_etape = get_fin_etape('loadCumul',cadastre_com)
	if len(fin_etape) == 1:
		date_fin_cumul = [[],fin_etape[0]]
	else:
		date_fin_cumul = fin_etape
date_cache_hsnr = get_fin_etape_dept('cache_dept_hsnr_insee',dept)[0]
date_cache_highway = get_fin_etape_dept('cache_dept_highway_insee',dept)[0]
date_cache_highway_relation = get_fin_etape_dept('cache_dept_highway_relation_insee',dept)[0]

data = [[nom_commune,date_import_cadastre,date_fin_cumul[0],date_fin_cumul[1],date_cache_hsnr,date_cache_highway,date_cache_highway_relation],get_data_from_pg('voies_adresses_non_rapprochees_insee',insee_com),get_data_from_pg('voies_adresses_rapprochees_insee',insee_com)]

a = json.JSONEncoder().encode(data)
print(a)
