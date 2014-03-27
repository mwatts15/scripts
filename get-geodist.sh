#!/usr/bin/env python
import urllib2
import sys
import re
from HTMLParser import HTMLParser

if (len(sys.argv) < 5):
    print("You must provide two coordinate pairs\nUsage: %s lat1 long1 lat2 long2" % sys.argv[0])
lat1 = float(sys.argv[1])
long1 = float(sys.argv[2])
lat2 = float(sys.argv[3])
long2 = float(sys.argv[4])

xml = urllib2.urlopen("http://geographiclib.sourceforge.net/cgi-bin/GeodSolve?type=I&input=%f+%f+%f+%f&format=g&azi2=f&prec=3&option=Submit" % (lat1, long1, lat2, long2)).read()
class MyHTMLParser (HTMLParser):
    def __init__(self):
        self.next = False
        self.dist = -1.0
        HTMLParser.__init__(self)
    def handle_data(self, data):
        if self.next == True:
            data = data.strip()
            self.dist = float(data)
            self.next = False
            return
        match = re.search(r".*s12 \(m\)", data)
        if match:
            self.next = True
    def feed(self, xmlstring):
        HTMLParser.feed(self, xmlstring)
        return self.dist
parser = MyHTMLParser()
dist = parser.feed(xml)
print "distance = %f\n" % dist
