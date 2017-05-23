
Cloud app of Sentinel 1 data pre-processsing
=============================================

This project provides a solution of Sentinel 1 data pre-processsing via a cloud application hosted by SlipStream. 

It takes in input a list of Sentinel 1 name products and merged their corrected image in an animated GIF.

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

Instructions
--------------

Follow the SlipStream client installation [SlipStream Client Installation]
(https://github.com/slipstream/SlipStreamDocumentation/blob/master/docs/tutorials/ss/automating-slipstream.rst)

Insert your product names in 'product_list.cfg' files one per line.

Edit the variable CLOUD in client_script2.sh by choosing your cloud provider (i.e. Amazon, Cesnet, Exoscale).

Finally run,

`<bash client_script2.cfg>`


Instructions
------------

1. Ensure the environment has been prepared (run "datacube system check")
2. Define the products (run "datacube product add productdef.yaml")
3. Preprocess some scenes (run "bulk.sh example_list.txt")
4. For each newly preprocessed scene, run a preparation script (e.g. "python prep.py output1.dim") to generate metadata (yaml) in an appropriate format for datacube indexing.
5. For each of those prepared scenes, index into the datacube (e.g. "datacube dataset add output*.yaml --auto-match")
6. Verify the data using the datacube API (e.g. a python notebook).

