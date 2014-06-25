import bitcoin
import time
import logging
from time import strftime

if __name__ == '__main__':
	
	db = bitcoin.mongo_connect()
	t1 = time.time()
	
	btccharts_symbols = ['virtexCAD', 
						'bitstampUSD', 
						'btceUSD', 
						'btcnCNY',
						'krakenUSD', 
						'krakenEUR', 
						'lakeUSD', 
						'bitfinexUSD', 
						'itbitUSD', 
						'hitbtcUSD', 'hitbtcEUR', 
						'localbtcUSD', 
						'btcdeEUR', 
						'1coinUSD', 
						'okcoinCNY', 
						'anxhkJPY', 'anxhkCAD', 'anxhkGBP', 'anxhkCHF', 'anxhkUSD', 'anxhkNZD', 'anxhkHKD',
						'bitcurexPLN', 
						'localbtcAUD', 
						'localbtcCAD'] 
	n = 0
	for s in btccharts_symbols:
		n += bitcoin.update_trades(db, s,'btc_charts')	

	btcavg_symbols = ['btcavgCAD', 
						'btcavgUSD', 
						'btcavgEUR', 
						'btcavgCNY', 
						'btcavgGBP', 
						'btcavgAUD', 
						'btcavgJPY', 
						'btcavgRUB', 
						'btcavgHKD', 
						'btcavgCHF', 
						'btcavgPLN']
	for s in btcavg_symbols:
		n += bitcoin.update_trades(db, s,'btc_avg')
	
	bitcoin.mongo_disconnect(db)
	t2 = time.time()
	bitcoin.log(str(n) + ' trades updated in ' + str(int((t2-t1)*1000)) + 'ms')
