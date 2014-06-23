# Library for managing trade data from exchanges and storing in mongodb
# Author: Sean Estey

import datetime
import os
import time
import os.path
import logging
import numpy as np
import pandas as pd
from time import strftime
logging.basicConfig(filename='/var/www/bitvisual/log.log',level=logging.DEBUG)	


def update_btcavg_markets():
	import simplejson
	import json
	import urllib2
	import pymongo
	import httplib

	request = urllib2.Request('https://api.bitcoinaverage.com/ticker/all')
	try:
		response = urllib2.urlopen(request, timeout=30)
	except urllib2.HTTPError, e:
		logging.info(strftime('%Y-%m-%d %H:%M') + ': update_btcavg_markets() HTTPError = ' + str(e.reason))
		return False
	except urllib2.URLError, e:
		logging.info(strftime('%Y-%m-%d %H:%M') + ': update_btcavg_markets() URLError = ' + str(e.reason))
		return False
	except httplib.HTTPException, e:
		logging.info(strftime('%Y-%m-%d %H:%M') + ': update_btcavg_markets() HTTPException = ' + str(e.reason))
		return False
	except Exception:
		import traceback
		logging.info(strftime('%Y-%m-%d %H:%M') + ': update_btcavg_markets() generic exception: ' + traceback.format_exc())
		return False

	data = simplejson.load(response)
	client = pymongo.MongoClient('localhost',27017)
	db = client.mydb
	mongo_collections = db.collection_names()
	# iteritems() converts dict to array with [0] element key and [1] element is value
	for item in data.iteritems():
		symbol = 'btcavg' + item[0]
		if symbol in mongo_collections:
			timestamp = item[1]['timestamp']
			# convert datetime "Sat, 31 May 2014 20:36:56 -0000" to timestamp
			timestamp = timestamp[:-6]
			import calendar
			timestamp = calendar.timegm(time.strptime(timestamp, '%a, %d %b %Y %H:%M:%S'))
			db['markets'].update({'symbol':symbol}, { '$set': {'time':timestamp, 'close':int(item[1]['last'])}}, True)

	return True

def update_btccharts_markets():
	import simplejson
	import json
	import urllib2
	import pymongo
	import httplib

	request = urllib2.Request('http://api.bitcoincharts.com/v1/markets.json')
	try:
		response = urllib2.urlopen(request, timeout=30)
	except urllib2.HTTPError, e:
		logging.info(strftime('%Y-%m-%d %H:%M') + ': update_btccharts_markets() HTTPError = ' + str(e.reason))
		return False
	except urllib2.URLError, e:
		logging.info(strftime('%Y-%m-%d %H:%M') + ': update_btccharts_markets() URLError = ' + str(e.reason))  
		return False
	except httplib.HTTPException, e:
		logging.info(strftime('%Y-%m-%d %H:%M') + ': update_btccharts_markets() HTTPException = ' + str(e.reason))
		return False
	except Exception:
		import traceback
		logging.info(strftime('%Y-%m-%d %H:%M') + ': update_btccharts_markets() generic exception: ' + traceback.format_exc())    
		return False

	data = simplejson.load(response)
	client = pymongo.MongoClient('localhost',27017)
	db = client.mydb
	mongo_collections = db.collection_names()

	for (i, item) in enumerate(data):
		symbol = item['symbol']
		if symbol in mongo_collections and item['avg'] > 0 and item['close'] is not None:
			# update symbol collection, insert new document if symbol doesn't exist (upsert)
			db['markets'].update({'symbol':symbol}, { '$set': {'time':item['latest_trade'], 'close':int(item['close'])}}, True)

	return True

def create_markets_json():
	import simplejson
	import json
	import urllib2
	url = urllib2.Request('http://api.bitcoincharts.com/v1/markets.json')
	opener = urllib2.build_opener()
	f = opener.open(url)
	data = simplejson.load(f)
	prices = [[0 for x in xrange(2)] for x in xrange(len(data))]
	index = 0
	for (i, item) in enumerate(data):
		if item['avg'] > 0 and item['close'] is not None:	
			prices[index] = [item['symbol'], int(item['close'])]
			index = index + 1
		else:
			del prices[index]
	with open('/var/www/bitvisual/data/markets', 'w') as outfile:
		json.dump(prices,outfile)

def read_raw_btccharts_csv(f):
    # reads csv format: [unixtime, price, amount]
	# returns csv format: [date (datetime) price amount]
	import urllib2
	import httplib
    
	try:
		response = urllib2.urlopen(f, timeout=30)
	except urllib2.HTTPError, e:
		logging.info(strftime('%Y-%m-%d %H:%M') + ': read_raw_btccharts_csv() HTTPError = ' + str(e.reason))
		return pd.DataFrame([])
	except urllib2.URLError, e:
		logging.info(strftime('%Y-%m-%d %H:%M') + ': read_raw_btccharts_csv() URLError = ' + str(e.reason))
		return pd.DataFrame([])
	except httplib.HTTPException, e:
		logging.info(strftime('%Y-%m-%d %H:%M') + ': read_raw_btccharts_csv() HTTPException = ' + str(e.reason))
		return pd.DataFrame([])
	except Exception:
		import traceback
		logging.info(strftime('%Y-%m-%d %H:%M') + ': read_raw_btccharts_csv() generic exception: ' + traceback.format_exc())
		return pd.DataFrame([])

	try:
		df = pd.read_csv(response, header=None, index_col=0, error_bad_lines=False)
	except Exception:
		import traceback
		logging.info(strftime('%Y-%m-%d %H:%M') + ': read_raw_btccharts_csv() read_csv(): url fail: ' + f + '. Raised generic exception: ' + traceback.format_exc())
		return pd.DataFrame([])

	df.columns = ['price','amount']
	df.index = pd.to_datetime(df.index,unit='s') 
	df.index.name = 'date'
	return df

def read_raw_btcavg_csv(f):
	# reads csv format: [datetime (YYYY-MM-DD) high low average volume] 
	# returns csv format: [date (datetime) price amount]
	import urllib2
	import httplib

	try:
		response = urllib2.urlopen(f, timeout=30)
	except urllib2.HTTPError, e:
		logging.info(strftime('%Y-%m-%d %H:%M') + ': read_raw_btcavg_csv() HTTPError = ' + str(e.reason))
		return pd.DataFrame([])
	except urllib2.URLError, e:
		logging.info(strftime('%Y-%m-%d %H:%M') + ': read_raw_btcavg_csv() URLError = ' + str(e.reason))
		return pd.DataFrame([])
	except httplib.HTTPException, e:
		logging.info(strftime('%Y-%m-%d %H:%M') + ': read_raw_btcavg_csv() HTTPException = ' + str(e.reason))
		return pd.DataFrame([])

	df = pd.read_csv(response,index_col=0)
	df = df.drop('high',axis=1)
	df = df.drop('low',axis=1)
#	df.columns = ['price', 'amount']
	df.columns = ['price']
	df.index = pd.to_datetime(df.index,unit='s')
	df.index.name = 'date'
	return df

def create_db_collection(symbol, df):
	import pymongo
	client = pymongo.MongoClient('localhost',27017)
	dlist = df.to_dict('records')
	db = client.mydb
	db.create_collection(symbol)
	db[symbol].insert(dlist)
	db[symbol].ensure_index('date')
	logging.info(strftime('%Y-%m-%d %H:%M') + ': created collection ' + symbol + ' with ' + str(len(df)) + ' records')

def process_raw_csv(df, has_volume):
	# reads CSV from with format [datetime price amount]
	# resamples data to hourly frequency, calculates mean price with summed volume
	if has_volume == True:
		df = df.resample('1h', how={'price':np.mean, 'amount':np.sum})
		df = df.fillna(method='ffill') #fill NAN with last valid previous value
		df['price'] = np.round(df['price'],2)
		df['amount'] = np.round(df['amount'],4)   
		df.index = df.index.astype(np.int64) // 10**9
		df = df.reset_index()
		df.columns = ['date','price','amount']
	else:
		df = df.resample('1h', how={'price':np.mean})
		df = df.fillna(method='ffill') #fill NAN with last valid previous value
		df['price'] = np.round(df['price'],2)
		df.index = df.index.astype(np.int64) // 10**9
		df = df.reset_index()
		df.columns = ['date','price']
	return df

def update_trades(symbol, source):
	# update latest trades since last timestamp and insert to db
	# returns number of trades added to db (0 if error)
	import pymongo	
	client = pymongo.MongoClient('localhost',27017)
	db = client.mydb
	last_record = db[symbol].find().sort('date',-1).limit(1)
	last_timestamp = int(last_record[0]['date'])
	
	if source == 'btc_charts':
		url = 'http://api.bitcoincharts.com/v1/trades.csv?symbol=' + symbol + '&start=' + str(last_timestamp)
		df = read_raw_btccharts_csv(url)
		if df.empty:
			return 0
		else:
			db[symbol].remove({'date':last_timestamp})
			df = process_raw_csv(df,True)
	elif source == 'btc_avg':
		currency = symbol[len(symbol)-3:]
		url = 'https://api.bitcoinaverage.com/history/' + currency + '/per_hour_monthly_sliding_window.csv'
		df = read_raw_btcavg_csv(url)
		if df.empty:
			return 0
		else:
			db[symbol].remove({'date':last_timestamp})
			df = process_raw_csv(df,False)
			current_index = df.date[df.date==last_timestamp].index[0]	
			df = df[current_index:] # remove all records prior to last_timestamp

	if len(df) > 1000:
		logging.info(strftime('%Y-%m-%d %H:%M') + symbol + ' update failed because > 1000 new trades')  
	else:
		dlist = df.to_dict('records')
		db[symbol].insert(dlist)
	
	return len(df)

