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

    # both set to 0 if querying most recent n records
	if start == 0 and end == 0:
		num_records = int(request.params['records'])
	
	client = pymongo.MongoClient('localhost',27017)
	db = client.mydb

	if frequency == 'd':
		sec_per_day = 3600 * 24
		if end == 0:
			#get most recent data, iterate back 'records' times with daily frequency
			last_record = db[symbol].find().sort('date',-1).limit(1)
			end = int(last_record[0]['date'])
			start = end - (sec_per_day * num_records)
		diff = end - start
		query_dates = []
		for i in range (start,end,sec_per_day):
			query_dates.append(i)
		prices = db[symbol].find({'date':{'$in':query_dates}}, {'_id':False,'price':1,'date':1})
	elif frequency == 'h':
		if end == 0:
			prices = db[symbol].find().sort('date',-1).limit(num_records)
		else:
			prices = db[symbol].find({'date':{'$gte':start,'$lte':end}},{'_id':False,'price':1, 'date':1})

	dlist = dumps(prices)
	
	client.close()

	status = '200 OK'
        response_headers = [('Content-type', 'text/plain')]
        start_response(status, response_headers)
	
	return dlist
