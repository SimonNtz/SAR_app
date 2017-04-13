
import os,sys
sys.path.append('/home/snap-engine/snap-python/src/main/resources/snappy')
import snappy
from snappy import GPF
from snappy import HashMap
jpy = snappy.jpy
import matplotlib
matplotlib.use('Agg')
import numpy as np
import matplotlib.pyplot as plt
import scipy
from scipy import ndimage
import gc
#s1paths = ( "S1A_IW_GRDH_1SDV_20151226T182813_20151226T182838_009217_00D48F_5D5F", "S1A_IW_GRDH_1SDV_20160424T182813_20160424T182838_010967_010769_AA98", "S1A_IW_GRDH_1SDV_20160518T182817_20160518T182842_011317_011291_936E", "S1A_IW_GRDH_1SDV_20160611T182819_20160611T182844_011667_011DC0_391B", "S1A_IW_GRDH_1SDV_20160705T182820_20160705T182845_012017_0128E1_D4EE", "S1A_IW_GRDH_1SDV_20160729T182822_20160729T182847_012367_013456_E8BF", "S1A_IW_GRDH_1SDV_20160822T182823_20160822T182848_012717_013FFE_90AF", "S1A_IW_GRDH_1SDV_20160915T182824_20160915T182849_013067_014B77_1FCD" )

#TODO check with zipped files
s1paths = list(sys.argv[1].split(','))
s1meta = "manifest.safe"

products = []

for s1path in s1paths:

    s1prd= "/home/data/%s.SAFE/%s" % (s1path, s1meta)
    reader = ProductIO.getProductReader("SENTINEL-1")
    product = reader.readProductNodes(s1prd, None)
    products.append(product)


# Extract information about the Sentinel-1 GRD products:

for product in products:

    width = product.getSceneRasterWidth()
    height = product.getSceneRasterHeight()
    name = product.getName()
    band_names = product.getBandNames()
    print("Product: %s, %d x %d pixels" % (name, width, height))
    print("Bands:   %s" % (list(band_names)))



WKTReader = snappy.jpy.get_type('com.vividsolutions.jts.io.WKTReader')

geom = WKTReader().read('POLYGON((-4.51 14.69,-4.477 14.227,-4.076 14.243,-4.054 14.642,-4.51 14.69))');

HashMap = jpy.get_type('java.util.HashMap')
GPF.getDefaultInstance().getOperatorSpiRegistry().loadOperatorSpis()

parameters = HashMap()
parameters.put('copyMetadata', True)
parameters.put('geoRegion', geom)

subsets = []

for product in products:

    subset = GPF.createProduct('Subset', parameters, product)
    subsets.append(subset)

# Step 1: Pre-processing - Calibration

parameters = HashMap()

parameters.put('auxFile', 'Latest Auxiliary File')
parameters.put('outputSigmaBand', True)
parameters.put('selectedPolarisations', 'VV')

calibrates = []

for subset in subsets:

    calibrate = GPF.createProduct('Calibration', parameters, subset)
    calibrates.append(calibrate)

# Step 2: Pre-processing - Speckle filtering

parameters = HashMap()

parameters.put('filter', 'Lee')
parameters.put('filterSizeX', 7)
parameters.put('filterSizeY', 7)
parameters.put('dampingFactor', 2)
parameters.put('edgeThreshold', 5000.0)
parameters.put('estimateENL', True)
parameters.put('enl', 1.0)

speckles = []

for calibrate in calibrates:

    speckle = GPF.createProduct('Speckle-Filter', parameters, calibrate)
    speckles.append(speckle)

parrameters = HashMap()

parameters.put('demResamplingMethod', 'NEAREST_NEIGHBOUR')
parameters.put('imgResamplingMethod', 'NEAREST_NEIGHBOUR')
parameters.put('demName', 'SRTM 3Sec')
parameters.put('pixelSpacingInMeter', 10.0)
parameters.put('sourceBands', 'Sigma0_VV')

terrains = []


for speckle in speckles :

    terrain = GPF.createProduct('Terrain-Correction', parameters, speckle)
    terrains.append(terrain)

parameters = HashMap()

lineartodbs= []

for terrain in terrains:

    lineartodb = GPF.createProduct('linearToFromdB', parameters, terrain)
    lineartodbs.append(lineartodb)

def rot_crop(c, ang):
    rot_c = ndimage.rotate(c, ang)
    lx, ly = rot_c.shape
    crop_rot =  rot_c[lx/6:-lx/6, ly/6:-ly/6]
    return(crop_rot)


#TODO Try to use ImageIO instead of pyplot
def printBand(product, band, vmin, vmax):

    band = product.getBand(band)
    w = band.getRasterWidth()
    h = band.getRasterHeight()

    band_data = np.zeros(w * h, np.float32)
    band.readPixels(0, 0, w, h, band_data)

    band_data.shape = h, w
    name = product.getName()

    plt.imshow(rot_crop(band_data, -10.75), cmap=plt.cm.binary_r, vmin=vmin, vmax=vmax)
    plt.axis('off')
    plt.tight_layout(pad=0, w_pad=0, h_pad=0)
    plt.savefig(name + '.png', frameon=False)
    #plt.show()
    print('Printed!')
    plt.clf()

for lineartodb in lineartodbs :
    printBand(lineartodb, 'Sigma0_VV_db', -25, 5)
    plt.close()
    #del calibrates, terrrains, speckles, lineartodbs
    gc.collect()

                                                                                                    198,0-1       Bot
