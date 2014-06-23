import pymongo
from bson.json_util import dumps

def application(environment, start_response):
	from webob import Request, Response
	request = Request(environment)
		
	client = pymongo.MongoClient('localhost',27017)
	db = client.mydb
	market_data = db['markets'].find({}, {'_id':False,'symbol':1,'time':1,'close':1})
	dlist = dumps(market_data)
	
	status = '200 OK'
        response_headers = [('Content-type', 'text/plain')]
        start_response(status, response_headers)
	
	return dlist
