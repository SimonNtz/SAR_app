import sys
from slipstream.api import Api
api = Api(cookie_file='/home/cookies-nuvla.txt')
event = {'acl': {u'owner': {u'principal': u'simon1992', u'type': u'USER'},
        u'rules': [{u'principal': u'simon1992',
        u'right': u'ALL',
        u'type': u'USER'},
        {u'principal': u'ADMIN',
        u'right': u'ALL',
        u'type': u'ROLE'}]},
'content': {u'resource': {u'href': u'run/'+ ''},u'state': sys.argv},'severity': u'low','timestamp': '',
        'type': u'state'}
    
api.cimi_add('events', event)
