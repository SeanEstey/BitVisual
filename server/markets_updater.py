import bitcoin

if __name__ == '__main__':
	db = bitcoin.mongo_connect()
	bitcoin.update_btccharts_markets(db)
	bitcoin.update_btcavg_markets(db)
	bitcoin.mongo_disconnect(db)
