
Sentinel 1 data pre-processing
===============================

This project is an use case of [Sentinel
1](https://sentinel.esa.int/web/sentinel/missions/sentinel-1) data preparation
for further quantitative analysis on Earth observation.  The processing takes a
list of satellite images as an input and outputs them merged into an animated
GIF. The automated deployment of the application on Cloud is performed using
https://nuv.la service which is based on
[SlipStream](http://sixsq.com/products/slipstream).


## Prerequisites

In order to successfully execute the application, you should have:

 1. An account on https://nuv.la.  Follow this
    [link](http://ssdocs.sixsq.com/en/latest/tutorials/ss/prerequisites.html#nuvla-account)
    where you'll find how to create the account.

 2. Cloud credentials added in your Nuvla user profile
    <div style="padding:14px"><img
    src="https://github.com/SimonNtz/SAR_app/blob/master/app/client/NuvlaProfile.png"
    width="75%"></div>

 3. Python `>=2.6 and <3` and python package manager `pip` installed. Usually
    can be done with `sudo easy_install pip`.

 4. SlipStream Client installed: `pip install slipstream-client`.


## Instructions

 1. Clone this repository with

    ```
    $ git clone https://github.com/SimonNtz/SAR_app.git
    ```

 2. Add the product names into the input file

    ```
    $ cd run/
    $ # edit product_list.cfg
    ```

 3. Set the environement variables

    ```
    $ export SLIPSTREAM_USERNAME=<nuv.la username>
    $ export SLIPSTREAM_PASSWORD=<nuv.la passowrd>
    ```

    and Run the SAR processor on https://nuv.la with

    ```
    $ ./SAR_run.sh <cloud>
    ```

    Where `<cloud>` is the connector instance name as defined on http://nuv.la
    service and the user has provided credential for it (see section 2. of
    Prerequisites).

 4. The command prints out the deployment URL which you should open in your
    browser and follow the progress of the deployment.  When the deployment is
    done, the link to the result of the computation becomes available as the
    run-time parameter `reducer.1:url.service` on the `reducer` component.

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
