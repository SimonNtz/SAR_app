
Sentinel 1 data pre-processing
===============================

This project is a use case of Sentinel 1 data preparation for further quantitative analysis on Earth observation.
The processing takes a list of satellite images in input and output them merged into an animated GIF.
The app is automated and deployed on a cloud cluster using SlipStream client.


## Prerequisites

#### In order to execute successfully the application you should have:

1. a SlipStream account

1. Cloud credentials added in the analogous Nuvla profile
<img src="https://github.com/SimonNtz/SAR_app/blob/master/app/client/NuvlaProfile.png" width="75%">




1. pip installed (https://pypi.python.org/pypi/pip)

1. SlipStream Client installed (https://pypi.python.org/pypi/slipstream-client/3.14)


## Instructions

* Add the product names into the input file [**product_list.cfg**](https://github.com/SimonNtz/SAR_app/tree/master/app/client/product_list.cfg)

* Run the [client script](https://github.com/SimonNtz/SAR_app/blob/master/app/client/client_script.sh) with the cloud service in parameter

    `bash client_script.sh <YOUR_CLOUD_SERVICE>`

--------------------------------------------------------------------------------

Scope
------

Earth observation and in situ data have been made available online by space agencies including notably ESA https://scihub.copernicus.eu/dhus/#/home and ASF https://vertex.daac.asf.alaska.edu/. Those datasets are continuously updated what makes possible time series analysis and many others applications. Such implementations, however, are highly demanding in resources.

Implementation
---------------

The processing of the satellite images is distributed in a cluster and follows the MapReduce model.
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
