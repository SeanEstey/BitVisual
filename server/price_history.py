import pymongo
from bson.json_util import dumps

def application(environment, start_response):
	from webob import Request, Response
	request = Request(environment)
	
	symbol = request.params['symbol']
	symbol = symbol.encode('ascii','ignore')
	start = int(request.params['start'])
	end = int(request.params['end'])
	frequency = request.params['freq']
	frequency = frequency.encode('ascii','ignore')
	
	client = pymongo.MongoClient('localhost',27017)
	db = client.mydb

	if frequency == 'd':
		diff = end - start
		sec_per_day = 3600 * 24
		query_dates = []
		for i in range (start,end,sec_per_day):
			query_dates.append(i)
		prices = db[symbol].find({'date':{'$in':query_dates}}, {'_id':False,'price':1,'date':1})
	elif frequency == 'h':
		prices = db[symbol].find({'date':{'$gte':start,'$lte':end}},{'_id':False,'price':1, 'date':1}) 

	#for n in prices[1:len(prices)-1]:
#	client.disconnect()

	dlist = dumps(prices)
	
	client.close()

	status = '200 OK'
        response_headers = [('Content-type', 'text/plain')]
        start_response(status, response_headers)
	
	return dlist
