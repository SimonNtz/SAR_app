from slipstream.api import Api
from pprint import pprint as pp
api = Api()
api.login('simon1992', '12mc0v2ee64o9')
'''
	This module containing the necessary methods to send requests to Service-Offer
	using the 'CIMI' API.
'''

def push_req(specs, orderby=None):
    url   = api.endpoint + "/api/service-offer?$filter="
    print specs
    req   = url + (' and ').join(specs)

    if orderby:
       	req = req + '&$oderby=&$orderby=price:unitCost'
    print req
    return(api.session.get(req).json())

def push_req2(sl, pl,orderby=False):

    url   = api.endpoint + "/api/service-offer?$filter="
    req   = url + (' and ').join(sl)
    if pl:
    	p_req = ["resource:class='%s.SAFE'" % p.strip() for p in pl]
        req  =  req  + ' and ' +  (' or ').join(p_req)
    if orderby:
	req = req + '&$orderby=price:unitCost'
    print req
    return(api.session.get(req).json())

def push_req3(cl,sl, orderby=True):

    url   = api.endpoint + "/api/service-offer?$filter="
    req = cl[0] + ' and ' + (' and ').join(sl)
    for c in cl[1:]:
        req   = req + (' or ') + c + ' and ' + (' and ').join(sl)

    if orderby:
        req = req + '&$orderby=price:unitCost'
    print url + req
    return(api.session.get(url + req).json())


def test_p(s):
    print(s)
if __name__ == '__main__':

    specs 	= [ "resource:type='DATA'", "resource:platform='S3'"]
   # CHECK DATA LOCALISATION

    prd_list = ['S1A_IW_GRDH_1SDV_20151226T182813_20151226T182838_009217_00D48F_5D5F'
                'S1A_IW_GRDH_1SDV_20160424T182813_20160424T182838_010967_010769_AA98'
                'S1A_IW_GRDH_1SDV_20160518T182817_20160518T182842_011317_011291_936E'
                'S1A_IW_GRDH_1SDV_20160611T182819_20160611T182844_011667_011DC0_391B'
		'S1A_IW_GRDH_1SDV_20160705T182820_20160705T182845_012017_0128E1_D4EE'
		'S1A_IW_GRDH_1SDV_20160729T182822_20160729T182847_012367_013456_E8BF'
		'S1A_IW_GRDH_1SDV_20160822T182823_20160822T182848_012717_013FFE_90AF'
		'S1A_IW_GRDH_1SDV_20160915T182824_20160915T182849_013067_014B77_1FCD']

    data_loc = push_req2(specs  prd_list)['count']
    pp(data_loc)
   # pp(push_req(prd_req[0])['count'])
