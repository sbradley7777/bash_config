#!/usr/bin/env python

import cookielib
import urllib
import urllib2
from urllib.parse import urlparse

values = {'email-email' : 'john@example.com',
          'password-clear' : 'Combination',
          'password-password' : 'mypassword' }
url = ""
values = {}
data = urllib.urlencode(values)
cookies = cookielib.CookieJar()

opener = urllib2.build_opener(
    urllib2.HTTPRedirectHandler(),
    urllib2.HTTPHandler(debuglevel=0),
    urllib2.HTTPSHandler(debuglevel=0),
    urllib2.HTTPCookieProcessor(cookies))

response = opener.open(url, data)
the_page = response.read()
#http_headers = response.info()
# The login cookies should be contained in the cookies variable
print the_page
print

parsed_url = urlparse(url)
print parsed_url.path
