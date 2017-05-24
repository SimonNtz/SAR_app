
Sentinel 1 data pre-processing
===============================

This projects is a use case of Sentinel 1 data preparation for further quantitative analysis on Earth observation.

The processing takes a list of satellite image in input and output them merged into an animated GIF.

The app is automated and deployed on a cloud cluster using SlipStream.


## Prerequisites

### In order to execute successfully the application you should have,

1. A SlipStream account

1. Your cloud credentials added to your SlipStream Account

1. pip installed (https://pypi.python.org/pypi/pip)

1. SlipStream Client installed (https://pypi.python.org/pypi/slipstream-client/3.14)


## Instructions

* In 'product_list.cfg' insert your product names line per line.

* Run the client script with

`bash client_script.sh <YOUR_CLOUD_SERVICE>`

--------------------------------------------------------------------------------

Scope
------

Earth observation and in situ data have been made available online by space agencies including notably ESA https://scihub.copernicus.eu/dhus/#/home and ASF https://vertex.daac.asf.alaska.edu/. Those datasets are continuously updated what makes possible time series analysis and many others applications. Such implementations, however, are highly demanding in ressources.

Implementation
---------------

The processing of the satelite images is distributed in a cluster and follows the MapReduce model.

The input and ouput files are stored in a object store located in the cluster's cloud.

The implementation aims to minimize the execution time

*NOTE: in-progress, not fully optimize yet.*

Processing stages
-----------------

1. Subset
2. Calibrate
3. Speckle-Filter (Dopler effect correction)
4. Terrain correction
5. PNG conversion
