# Library for managing trade data from exchanges and storing in mongodb.
# Author: Sean Estey

import datetime
import os
import time
import os.path
import logging
import numpy as np
import pandas as pd
import pymongo

def log(msg):
	logger = logging.getLogger('logger')
	for h in logger.handlers:
		logger.removeHandler(h)
	logger.addHandler(logging.FileHandler('/var/www/bitvisual/log.log'))
	from time import strftime
	logger.error(strftime('%Y-%m-%d %H:%M: ') + msg)

def log_exception(msg):
	exc_logger = logging.getLogger('exc_logger')
	for h in exc_logger.handlers:
		exc_logger.removeHandler(h)	
	exc_logger.addHandler(logging.FileHandler('/var/www/bitvisual/exceptions.log'))
	from time import strftime
	import traceback
	exc_logger.error(strftime('%Y-%m-%d %H:%M: ') + msg + ': stack dump:' + traceback.format_exc())

def mongo_connect():
	try:
		client = pymongo.MongoClient('localhost', 27017)
	except pymongo.errors.ConnectionFailure:
		log_exception('couldnt connect to mongodb')
		return

	return client.mydb

def mongo_disconnect(db):
	return db.connection.close()
	
def update_markets(db, url, source):
	import simplejson
	import urllib2

	if source == 'btc_avg':
		url = 'https://api.bitcoinaverage.com/ticker/all'
	elif source == 'btc_charts':
		url = 'http://api.bitcoincharts.com/v1/markets.json'

	try:
		response = urllib2.urlopen(url, timeout=1)
	except urllib2.URLError, e:
		log('URLError opening ' + url + ': ' + str(e.reason))
		return False
	except Exception:
		log_exception('update_btcavg_markets')
		return False

	data = simplejson.load(response)
	mongo_collections = db.collection_names()
	
	if source == 'btc_avg':
		for item in data.iteritems():
			symbol = 'btcavg' + item[0]
			if symbol in mongo_collections:
				timestamp = item[1]['timestamp']
				# convert datetime "Sat, 31 May 2014 20:36:56 -0000" to timestamp
				timestamp = timestamp[:-6]
				import calendar
				timestamp = calendar.timegm(time.strptime(timestamp, '%a, %d %b %Y %H:%M:%S'))
				collection = {'symbol':symbol}
				query = {'$set': {'time':timestamp, 'close':int(item[1]['last'])}}
				db['markets'].update(collection, query, True)
	
	elif source == 'btc_charts':
		for (i, item) in enumerate(data):
			symbol = item['symbol']
			if symbol in mongo_collections and item['avg'] > 0 
			and item['close'] is not None:
				# update symbol collection, insert new document if symbol doesn't exist (upsert)
				collection = {'symbol':symbol} 
				query = {'$set': {'time':item['latest_trade'], 'close':int(item['close'])}}
				db['markets'].update(collection, query, True)
	
	return True

def parse_raw_trades(url, source):
	# returns pandas dataframe in format: [date price amount]
	# where date is in datetime format
	import urllib2
    
	try:
		response = urllib2.urlopen(url, timeout=1)
	except urllib2.URLError, e:
		log('URLError opening ' + url + ': ' + str(e.reason))
		return pd.DataFrame([])
	except Exception:
		log_exception('Exception opening ' + url)
		return pd.DataFrame([])

	if source == 'btc_charts':
		# csv format: [unixtime, price, amount]
		try:
			df = pd.read_csv(response, header=None, index_col=0, error_bad_lines=False)
		except Exception:
			log_exception('Could not parse CSV from ' + url)
			return pd.DataFrame([])
	elif source == 'btc_avg':
		# csv format: [datetime (YYYY-MM-DD) high low average volume] 
		try:
			df = pd.read_csv(response,index_col=0, error_bad_lines=False)
		except Exception:
			log_exception('Could not parse CSV from ' + url)
			return pd.DataFrame([])
			
	if source == 'btc_charts':
		df.columns = ['price','amount']
		df.index = pd.to_datetime(df.index,unit='s') 
		df.index.name = 'date'
		return df
	elif source == 'btc_avg':
		df = df.drop('high',axis=1)
		df = df.drop('low',axis=1)
	#	df.columns = ['price', 'amount']
		df.columns = ['price']
		df.index = pd.to_datetime(df.index,unit='s')
		df.index.name = 'date'
		return df

def process_raw_trades(df, has_volume):
	# reads dataframe returned from parse_raw_trades
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

def create_db_collection(db, symbol, df):
	dlist = df.to_dict('records')
	db.create_collection(symbol)
	db[symbol].insert(dlist)
	db[symbol].ensure_index('date')
	log('created collection ' + symbol + ' with ' + str(len(df)) + ' records')

def update_trades(db, symbol, source):
	# update latest trades since last timestamp and insert to db
	# returns number of trades added to db (0 if error)
	last_record = db[symbol].find().sort('date',-1).limit(1)
	last_timestamp = int(last_record[0]['date'])
	
	if source == 'btc_charts':
		url = 'http://api.bitcoincharts.com/v1/trades.csv?symbol=' + symbol + '&start=' + str(last_timestamp)
		df = parse_raw_trades(url, 'btc_charts')
		if df.empty:
			return 0
		else:
			db[symbol].remove({'date':last_timestamp})
			df = process_raw_trades(df,True)
	elif source == 'btc_avg':
		currency = symbol[len(symbol)-3:]
		url = 'https://api.bitcoinaverage.com/history/' + currency + '/per_hour_monthly_sliding_window.csv'
		df = parse_raw_trades(url, 'btc_avg')
		if df.empty:
			return 0
		else:
			db[symbol].remove({'date':last_timestamp})
			df = process_raw_trades(df,False)
			current_index = df.date[df.date==last_timestamp].index[0]	
			df = df[current_index:] # remove all records prior to last_timestamp

	if len(df) > 1000:
		log('update failed. > 1000 trades. something might be wrong.')
	else:
		dlist = df.to_dict('records')
		db[symbol].insert(dlist)
	
	return len(df)
