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
	num_fails=0
	num_successes = 0
	fail_list = ''
	
	for s in btccharts_symbols:
		res = bitcoin.update_trades(db, s,'btc_charts')	
		if res == 0:
			num_fails += 1
			fail_list += ', ' + s
		elif res > 0:
			num_successes += 1
			n += res

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
		res = bitcoin.update_trades(db, s,'btc_avg')
		if res == 0:
			num_fails += 1
			fail_list += ', ' + s
		elif res > 0:
			num_successes += 1	
			n += res

	bitcoin.mongo_disconnect(db)
	t2 = time.time()
	
	msg = str(num_successes) + '/' + str((num_fails+num_successes)) + ' exchanges updated.'
	
	if num_fails > 0:
		msg += ' Failed: ' + fail_list[2:] + '. '
	
	msg += str(n) + ' trades updated in ' + str(int((t2-t1)*1000)) + 'ms'

	bitcoin.log(msg)
