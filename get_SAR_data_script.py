#!/usr/bin/python

#
# Usage:
#
#    In a terminal/command line, cd to the directory where this file lives. Then...
#
#    With embedded urls: ( download the hardcoded list of files in the 'files = []' block below)
#
#       python ./download-all-2017-4-12_9-10-11.py
#
#    Download all files in a Metalink/CSV: (downloaded from ASF Vertex)
#
#       python ./download-all-2017-4-12_9-10-11.py /path/to/downloads.metalink localmetalink.metalink localcsv.csv
#
#    Compatibility: python >= 2.6.5, 2.7.5, 3.0
#
#    For more information, navigate to https://www.asf.alaska.edu/data-tools/bulk-download/
#

import sys, csv
import os, os.path
import tempfile, shutil

import base64
import time
import getpass

import xml.etree.ElementTree as ET

#############
# This next block is a bunch of Python 2/3 compatability

try:
   # Python 2.x Libs
   from urllib2 import build_opener, install_opener, Request, urlopen, HTTPError
   from urllib2 import URLError, HTTPHandler, HTTPRedirectHandler, HTTPCookieProcessor
   from urllib import addinfourl

   from cookielib import CookieJar
   from StringIO import StringIO

except ImportError:
   # Python 3.x Libs
   from urllib.request import build_opener, install_opener, Request, urlopen
   from urllib.request import HTTPHandler, HTTPRedirectHandler, HTTPCookieProcessor
   from urllib.response import addinfourl
   from urllib.error import HTTPError, URLError

   from http.cookiejar import CookieJar
   from io import StringIO

# List of files to download
files = [  "https://datapool.asf.alaska.edu/GRD_HD/SA/S1A_IW_GRDH_1SDV_20151226T182813_20151226T182838_009217_00D48F_5D5F.zip", "https://datapool.asf.alaska.edu/GRD_HD/SA/S1A_IW_GRDH_1SDV_20160915T182824_20160915T182849_013067_014B77_1FCD.zip", "https://datapool.asf.alaska.edu/GRD_HD/SA/S1A_IW_GRDH_1SDV_20160822T182823_20160822T182848_012717_013FFE_90AF.zip", "https://datapool.asf.alaska.edu/GRD_HD/SA/S1A_IW_GRDH_1SDV_20160729T182822_20160729T182847_012367_013456_E8BF.zip", "https://datapool.asf.alaska.edu/GRD_HD/SA/S1A_IW_GRDH_1SDV_20160705T182820_20160705T182845_012017_0128E1_D4EE.zip", "https://datapool.asf.alaska.edu/GRD_HD/SA/S1A_IW_GRDH_1SDV_20160611T182819_20160611T182844_011667_011DC0_391B.zip", "https://datapool.asf.alaska.edu/GRD_HD/SA/S1A_IW_GRDH_1SDV_20160518T182817_20160518T182842_011317_011291_936E.zip", "https://datapool.asf.alaska.edu/GRD_HD/SA/S1A_IW_GRDH_1SDV_20160424T182813_20160424T182838_010967_010769_AA98.zip"]
# Local stash of datapool cookie so we don't always have to ask
cookie_file_path = os.path.join( os.path.expanduser('~'), ".asf_datapool_cookie.txt")

# Some internal URS4 Auth stuff
asf_urs4 = { 'url': 'https://urs.earthdata.nasa.gov/oauth/authorize',
             'client': 'BO_n7nTIlMljdvU6kRRB3g',
             'redir': 'https://vertex.daac.asf.alaska.edu/services/urs4_token_request'}

# Get and validate a cookie
def get_cookie():
   cookie = None

   # check for existing datapool cookie
   if os.path.isfile( cookie_file_path ):
      with open(cookie_file_path, 'r') as cookie_file:
         cookie = cookie_file.read()

      # make sure cookie is still valid
      if check_cookie(cookie):
         print(" > Re-using previous valid datapool cookie.")
         return (cookie)
      else:
         cookie = None

   # We don't have a valid cookie, prompt user or creds
   if cookie is None:
      print ("No existing datapool access cookie found, please enter Earthdata username & password:")
      print ("(Credentials will not be stored, saved or logged anywhere)")

   # Keep trying 'till user gets the right U:P
   while cookie is None:
      cookie = get_new_cookie()

   return cookie

# Stash cookie so we don't alway ask for auth
def write_cookie_to_file(cookie):

   if os.path.isfile( cookie_file_path ):
      if os.access(cookie_file_path, os.W_OK) is False:
         print ("Cannot write cookie file!")
         return False

   cookie_file = open(cookie_file_path, 'w')
   cookie_file.write(cookie)
   return True

# Validate cookie before we begin
def check_cookie (cookie):
   if cookie is None:
      return False

   # File we know is valid, used to validate cookie
   file_check = 'https://datapool.asf.alaska.edu/GEOTIFF/SS/SS_01499_STD_F1309_tif.zip'

   #catch redirects, since that would mean a problem w/ the cookie
   class NoRedirectHandler(HTTPRedirectHandler):
      def http_error_302(self, req, fp, code, msg, headers):
         infourl = addinfourl(fp, headers, req.get_full_url())
         infourl.status = code
         infourl.code = code
         return infourl
      http_error_300 = http_error_302
      http_error_301 = http_error_302
      http_error_303 = http_error_302

   # Apply custom Redirect Hanlder
   opener = build_opener(NoRedirectHandler())
   install_opener(opener)

   # Attempt a HEAD request
   request = Request(file_check)
   request.add_header('Cookie', 'datapool='+cookie)
   request.get_method = lambda : 'HEAD'
   try:
      response = urlopen(request)
      resp_code = response.getcode()

   except HTTPError as e:
      # If we ge this error, again, it likely means the user has not agreed to current EULA
      print ("\nIMPORTANT: ")
      print ("Your user appears to lack permissions to download data from the ASF Datapool.")
      print ("\n\nNew users: you must first log into Vertex and accept the EULA. In addition, your Study Area must be set at Earthdata https://urs.earthdata.nasa.gov")
      exit(-1)

   # This return codes indicate the USER has not been approved to download the data
   if resp_code in (300, 301, 302, 303):
      try:
         redir_url = response.info().getheader('Location')
      except AttributeError:
         redir_url = response.getheader('Location')

      #Funky Test env:
      if ("vertex.daac.asf.alaska.edu" in redir_url and "test" in asf_urs4['redir']):
         print ("Cough, cough. It's dusty in this test env!")
         return True

      print ("Redirect ({0}) occured, invalid datapool cookie value!".format(resp_code))
      return False

   # These are successes!
   if resp_code in (200, 307):
      return True

   return False

def get_new_cookie():

   # Start by prompting user to input their credentials

   # Another Python2/3 workaround
   try:
      new_username = raw_input("Username: ")
   except NameError:
      new_username = input("Username: ")
   new_password = getpass.getpass(prompt="Password (will not be displayed): ")

   # Build URS4 Cookie request
   auth_cookie_url = asf_urs4['url'] + '?client_id=' + asf_urs4['client'] + '&redirect_uri=' + asf_urs4['redir'] + '&response_type=code&state=';

   try:
      #python2
      user_pass = base64.b64encode (bytes(new_username+":"+new_password))
   except TypeError:
      #python3
      user_pass = base64.b64encode (bytes(new_username+":"+new_password, "utf-8"))
      user_pass = user_pass.decode("utf-8")

   # Authenticate against URS, grab all the cookies
   cj = CookieJar()
   opener = build_opener(HTTPCookieProcessor(cj), HTTPHandler())
   request = Request(auth_cookie_url, headers={"Authorization": "Basic {0}".format(user_pass)})

   # Watch out cookie rejection!
   try:
      response = opener.open(request)
   except HTTPError as e:
      if e.code == 401:
         print (" > Username and Password combo was not successful. Please try again.")
         return None
      else:
         # If an error happens here, the user most likely has not confirmed EULA.
         print ("\nIMPORTANT: There was an error obtaining a download cookie!")
         print ("Your user appears to lack permission to download data from the ASF Datapool.")
         print ("\n\nNew users: you must first log into Vertex and accept the EULA. In addition, your Study Area must be set at Earthdata https://urs.earthdata.nasa.gov")
         exit(-1)
   except URLError as e:
      print ("\nIMPORTANT: There was a problem communicating with URS, unable to obtain cookie. ")
      print ("Try cookie generation later.")
      exit(-1)

   # Did we get a cookie?
   for cookie in cj:
      if cookie.name == 'datapool':
         #COOKIE SUCCESS!
         write_cookie_to_file(cookie.value)
         return cookie.value

   # if we aren't successful generating the cookie, nothing will work. Stop here!
   print ("WARNING: Could not generate new cookie! Cannot proceed. Please try Username and Password again.")
   print ("Response was {0}.".format(response.getcode()))
   print ("\n\nNew users: you must first log into Vertex and accept the EULA. In addition, your Study Area must be set at Earthdata https://urs.earthdata.nasa.gov")
   exit(-1)

# Download the file
def download_file_with_cookie(file,cookie, cnt, total):

   # see if we've already download this file
   download_file = os.path.basename(file)
   if os.path.isfile(download_file):
      print (" > Download file {0} exists! \n > Skipping download of {1}. ".format(download_file, file))
      print (" > If you want to re-download it, move or remove that file.")
      return None

   # attempt https connection
   try:
      request = Request(file)
      request.add_header('Cookie', 'datapool='+cookie)
      response = urlopen(request)

      # Watch for redirect
      resp_code = response.getcode()
      if response.geturl() != file:
         print (" > Temporary Redirect download @ ASF Remote archive:\n > {0}".format(response.geturl()))

      # seems to be working
      print ("({0}/{1}) Downloading {2}".format(cnt, total, file))

      # Open our local file for writing and build status bar
      tf = tempfile.NamedTemporaryFile(mode='w+b', delete=False)
      chunk_read(response, tf, report_hook=chunk_report)

      tempfile_name = tf.name
      tf.close()

   #handle errors
   except HTTPError as e:
      print ("HTTP Error:", e.code, file)
      if e.code == 401:
         print (" > IMPORTANT: Your user does not have permission to download this type of data!")
      return False

   except URLError as e:
      print ("URL Error:", e.reason, file)
      return False

   # Return the file size
   shutil.copy(tempfile_name, download_file)
   os.remove(tempfile_name)
   return os.path.getsize(download_file)

#  chunk_report taken from http://stackoverflow.com/questions/2028517/python-urllib2-progress-hook
def chunk_report(bytes_so_far, chunk_size, total_size):
   percent = float(bytes_so_far) / total_size
   percent = round(percent*100, 2)
   sys.stdout.write(" > Downloaded %d of %d bytes (%0.2f%%)\r" %
       (bytes_so_far, total_size, percent))

   if bytes_so_far >= total_size:
      sys.stdout.write('\n')

#  chunk_read modified from http://stackoverflow.com/questions/2028517/python-urllib2-progress-hook
def chunk_read(response, local_file, chunk_size=8192, report_hook=None):
   try:
      total_size = response.info().getheader('Content-Length').strip()
   except AttributeError:
      total_size = response.getheader('Content-Length').strip()
   total_size = int(total_size)
   bytes_so_far = 0

   while 1:
      chunk = response.read(chunk_size)
      try:
         local_file.write(chunk)
      except TypeError:
         local_file.write(chunk.decode(local_file.encoding))
      bytes_so_far += len(chunk)

      if not chunk:
         break

      if report_hook:
         report_hook(bytes_so_far, chunk_size, total_size)

   return bytes_so_far

# Get download urls from a metalink file
def process_metalink(ml_file):

   print ("Processing metalink file: {0}".format(ml_file))
   with open(ml_file, 'r') as ml:
      xml = ml.read()

   # Hack to remove annoying namespace
   it = ET.iterparse(StringIO(xml))
   for _, el in it:
      if '}' in el.tag:
         el.tag = el.tag.split('}', 1)[1]  # strip all namespaces
   root = it.root

   dl_urls = []
   files = root.find('files')
   for dl in files:
      dl_urls.append(dl.find('resources').find('url').text)

   if len(dl_urls) > 0:
      return dl_urls
   else:
      return None

# Get download urls from a csv file
def process_csv(csv_file):

   print ("Processing csv file: {0}".format(csv_file))

   dl_urls = []
   with open(csv_file, 'r') as csvf:
      try:
         csvr = csv.DictReader(csvf)
         for row in csvr:
            dl_urls.append(row['URL'])
      except csv.Error as e:
         print ("WARNING: Could not parse file %s, line %d: %s. Skipping." % (csv_file, csvr.line_num, e))
         return None
      except KeyError as e:
         print ("WARNING: Could not find URL column in file %s. Skipping." % (csv_file))

   if len(dl_urls) > 0:
      return dl_urls
   else:
      return None

if __name__ == "__main__":

   # Make sure we can write it our current directory
   if os.access(os.getcwd(), os.W_OK) is False:
      print ("WARNING: Cannot write to current path! Check permissions for {0}".format(os.getcwd()))
      exit(-1)

   # grab a cookie
   cookie = get_cookie()

   # Check if user handed in a Metalink:
   if len(sys.argv) > 0:
      download_files = []
      input_files = []
      for arg in sys.argv[1:]:
          if arg.endswith('.metalink') or arg.endswith('.csv'):
              if os.path.isfile( arg ):
                 input_files.append( arg )
                 if arg.endswith('.metalink'):
                    new_files = process_metalink(arg)
                 else:
                    new_files = process_csv(arg)
                 if new_files is not None:
                    for file_url in (new_files):
                       download_files.append( file_url )
              else:
                 print (" > I cannot find the input file you specified: {0}".format(arg))
          else:
              print (" > Command line argument '{0}' makes no sense, ignoring.".format(arg))

      if len(input_files) > 0:
         if len(download_files) > 0:
            print (" > Processing {0} downloads from {1} input files. ".format(len(download_files), len(input_files)))
            files = download_files
         else:
            print (" > I see you asked me to download files from {0} input files, but they had no downloads!".format(len(input_files)))
            print (" > I'm super confused and exiting.")
            exit(-1)

   # summary
   total_bytes = 0
   total_time = 0
   cnt = 0
   success = []
   failed = []
   skipped = []

   for file in files:

      # download counter
      cnt += 1

      # set a timer
      start = time.time()

      # run download
      size = download_file_with_cookie(file, cookie, cnt, len(files))

      # calculte rate
      end = time.time()

      # stats:
      if size is None:
         skipped.append(file)

      elif size is not False:
         # Download was good!
         elapsed = end - start
         elapsed = 1.0 if elapsed < 1 else elapsed
         rate = (size/1024**2)/elapsed

         print ("Downloaded {0}b in {1:.2f}secs, Average Rate: {2:.2f}mb/sec".format(size, elapsed, rate))

         # add up metrics
         total_bytes += size
         total_time += elapsed
         success.append( {'file':file, 'size':size } )

      else:
         print ("There was a problem downloading {0}".format(file))
         failed.append(file)

   # Print summary:
   print ("\n\nDownload Summary ")
   print ("--------------------------------------------------------------------------------")
   print ("  Successes: {0} files, {1} bytes ".format(len(success), total_bytes))
   for success_file in success:
      print ("           - {0}  {1:.2f}mb".format(success_file['file'],(success_file['size']/1024.0**2)))
   if len(failed) > 0:
      print ("  Failures: {0} files".format(len(failed)))
      for failed_file in failed:
         print ("          - {0}".format(failed_file))
   if len(skipped) > 0:
      print ("  Skipped: {0} files".format(len(skipped)))
      for skipped_file in skipped:
         print ("          - {0}".format(skipped_file))
   if len(success) > 0:
      print ("  Average Rate: {0:.2f}mb/sec".format( (total_bytes/1024.0**2)/total_time))
   print ("--------------------------------------------------------------------------------")
