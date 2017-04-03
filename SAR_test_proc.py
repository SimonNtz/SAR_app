#!/usr/bin/python
###################################################################
#
#  Alaska Satellite Facility DAAC
#
#  Sentinel Radiometric Terrain Correction using Sentinel Toolbox (SNAP)
#
###################################################################
#
# Copyright (C) 2016 Alaska Satellite Facility
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>
#
###################################################################
#
#  SNAPPY RTC script
#
# TO USE:
#    (1.) Install SNAP, Snappy, and S1Toolbox from ESA (http://step.esa.int/main/download/)
#    (2.) search file for the word <FIX> and replace with appropriate path on your system
#    (3.) Download the sample granules from ASF (https://vertex.daac.asf.alaska.edu/) by searching for these granule names:
#            S1A_S1_SLC__1SSV_20141018T142338_20141018T142403_002885_003443_6545
#            S1A_IW_GRDH_1SDV_20150316T235525_20150316T235550_005064_0065C2_6527
#    (O.) optionally search for <OPTIONAL> and do what's required
#
###################################################################

import os, sys
sys.path.append('/home/snappy')
sys.path.append('/opt/snap/')
sys.path.append('/home/s1tbx')

import snappy
from snappy import jpy
from snappy import GPF
from snappy import ProductIO
from snappy import String
from snappy import Product
from snappy import ProductData
from snappy import ProductIO
from snappy import ProductUtils
from snappy import VirtualBand
from snappy import HashMap
import numpy as np
import matplotlib.pyplot as plt
from Queue import *
from thread import *
from time import *

iDebug = True
iWriteEachStep = True
file1=""
filename=""
targetCalibrated=""
targetRTCd=""
GPF.getDefaultInstance().getOperatorSpiRegistry().loadOperatorSpis()

q = Queue()


def DestinationThread() :
  while True :
    f, args = q.get()
    f(*args)


def readFiles(filename1):
    global file1
    global filename

    if iDebug: print filename1
    file1 = ProductIO.readProduct(filename1)
    filename = file1.getName()
    if iDebug: print "Read file: " + file1.getName()


def writeFiles(target, strStep):
    global filename
    # <FIX>:  fix this path
    ofile = '/home/' + filename + strStep
    if target:
        ProductIO.writeProduct(target, ofile, 'GeoTIFF-BigTIFF')   # <Optional> change to other types here: BEAM-DIMAP, GeoTIFF-BigTIFF, etc.


def calibration():
	### Calibration
	global targetCalibrated
	global file1


	parameters = HashMap()
	if file1 == "":
		print "Error - File 1 missing"
		return

	targetCalibrated = GPF.createProduct("Calibration", parameters, file1)
	if iDebug: print "Calibration working"



def terrainCorrection():
    ###  Terrain-Correction
    global targetCalibrated
    global targetRTCd

    if targetCalibrated=="":
    	print "targetCalibrated missing"
    	return

    parameters = HashMap()
    # OPTIONAL: parameters.put('Search Window Accuracy in Azimuth Direction', 2)
    targetRTCd = GPF.createProduct("Terrain-Correction", parameters, targetCalibrated)
    if iDebug: print "TerrainCorrection working"




### Main ###
#
#
# <FIX>: download the sample file /or/ change this to your granule
# <OPTIONAL>:  fix this path
# SLC: filename1 = "/S1A_S1_SLC__1SSV_20141018T142338_20141018T142403_002885_003443_6545.zip"
# GRD: filename1 = "/S1A_IW_GRDH_1SDV_20150316T235525_20150316T235550_005064_0065C2_6527.zip"
filename1 = "S1A_IW_GRDH_1SDV_20150316T235525_20150316T235550_005064_0065C2_6527.zip"

start_new_thread( DestinationThread, tuple() )

print "Snappy RTC: start"
sleep( 1 )
q.put( (readFiles, [filename1]) )
sleep( 1 )

### Calibration step
q.put( (calibration, "") )
sleep( 1 )
if targetCalibrated and iWriteEachStep:
    q.put( (writeFiles, [targetCalibrated, "_Cal"]) )
    sleep( 1 )

if (targetCalibrated) and iDebug:
    print "Calibration completed"
elif not(targetCalibrated) and iDebug:
    print "Calibration failed to complete!"

### Terrain Correction step
q.put( (terrainCorrection, "") )
sleep( 1 )
if targetRTCd:
    q.put( (writeFiles, [targetRTCd, "_TC"]) )
    sleep( 1 )

if (targetRTCd) and iDebug:
    print "TerrainCorrection completed"
elif not(targetRTCd) and iDebug:
    print "TerrainCorrection failed to complete!"

print "Snappy RTC: end"


### CLeanup temporary image files
if iDebug: print "Cleanup tmp files"
myStr = "image"
path = "/home/.snap/var/cache/temp"
dirs = os.listdir( path )

for file in dirs:
    if iDebug: print file
    # make sure it's an image file
    if file.startswith(myStr):
        os.remove(path + "/" + file)
if iDebug: print "Cleanup complete"

###  Done
print "Thank you for using ASF's Snappy RTC script!"
