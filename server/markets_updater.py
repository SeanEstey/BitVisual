import bitcoin

if __name__ == '__main__':
	db = bitcoin.mongo_connect()
	bitcoin.update_markets(db, 'btc_charts')
	bitcoin.update_markets(db, 'btc_avg')
	bitcoin.mongo_disconnect(db)
