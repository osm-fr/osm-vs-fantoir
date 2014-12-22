#!/usr/bin/env python
# -*- coding: utf-8 -*-

import urllib2
import time
import calendar
# import cgitb

def main():
	print "Content-Type: text/plain"
	print ""
	
	st_url = "http://osm2pgsql-monde.openstreetmap.fr/~osm2pgsql/state.txt"

	resp = urllib2.urlopen(st_url)
	full = resp.read()
	s = full.split('\n')[2].split('timestamp=')[1]
	st = time.localtime(calendar.timegm(time.strptime(s,'%Y-%m-%dT%H\:%M\:%SZ')))
	print(time.strftime('%d/%m/%Y %H:%M:%S',st))
if __name__ == '__main__':
    main()
