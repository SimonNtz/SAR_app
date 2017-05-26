
Sentinel 1 data pre-processing
===============================

This project is an use case of [Sentinel
1](https://sentinel.esa.int/web/sentinel/missions/sentinel-1) data preparation
for further quantitative analysis on Earth observation.  The processing takes a
list of satellite images as an input and outputs them merged into an animated
GIF. The automated deployment of the application on Cloud is performed using
https://nuv.la service which is based on
(SlipStream)[http://sixsq.com/products/slipstream].


## Prerequisites

In order to successfully execute the application, you should have:

 1. An account on https://nuv.la.

 2. Cloud credentials added in your Nuvla user profile
    <div style="padding:14px"><img
    src="https://github.com/SimonNtz/SAR_app/blob/master/app/client/NuvlaProfile.png"
    width="75%"></div>

 3. Python package manager `pip` installed. Usually can be done with
    `sudo easy_install pip`.

 4. SlipStream Client installed: `pip install slipstream-client`.


## Instructions

 1. Add the product names into the input file
    [product_list.cfg](https://github.com/SimonNtz/SAR_app/tree/master/app/client/product_list.cfg)

 2. Run the [client
    script](https://github.com/SimonNtz/SAR_app/blob/master/app/client/SAR_run.sh)
    with the cloud service as a parameter

      cd run/
      ./SAR_run.sh <YOUR_CLOUD_SERVICE>

## Scope

Earth observation and in situ data have been made available online by space
agencies including notably ESA https://scihub.copernicus.eu/dhus/#/home and ASF
https://vertex.daac.asf.alaska.edu/. Those datasets are continuously updated
what makes possible time series analysis and many others applications. Such
implementations, however, are highly demanding in resources.

## Implementation

The processing of the satellite images is distributed in a cluster and follows
the MapReduce model.  The input and ouput files are stored in a object store
located in the cluster's cloud.  The implementation aims to minimize the
execution time

*NOTE: in-progress, not fully optimize yet.*

## Processing stages

1. Subset
2. Calibrate
3. Speckle-Filter (Dopler effect correction)
4. Terrain correction
5. PNG conversion
