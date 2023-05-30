#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import time
import calendar
import cgitb

def main():
    print ("Content-Type: text/plain")
    print ("")
    
    with open('/data/download_v3/state.txt') as f:
        full = f.read()
        s = full.split('\n')[2].split('timestamp=')[1]
        st = time.localtime(calendar.timegm(time.strptime(s,'%Y-%m-%dT%H\:%M\:%SZ')))
        print(time.strftime('%d/%m/%Y %H:%M:%S',st))

if __name__ == '__main__':
    main()
