Server Setup

Ubuntu Dependencies:<br>
-Python 2.7<br>
-MongoDB<br>
-Apache w/ mod_wsgi

Python Dependencies:<br>
$ pip install numpy pandas easyjson webob

Apache Mods:<br>
$ apt-get install libapache2-mod-wsgi

Add to VirtualHost in /etc/apache2/sites-available/000-default.conf:

    <Directory /var/www/bitvisual/>
        Options +ExecCGI +FollowSymLinks +Indexes
        Order allow,deny
        Allow from all
        Require all granted
        AddHandler wsgi-script .py 
    </Directory>

Place bitcoin.py, get_markets.py, and price_history.py in /var/www/bitvisual/python

Setup schedule:<br>
$ crontab -e

Add following lines:

    @hourly /usr/bin/python /root/BitVisual/server/hourly_updater.py
    @daily /usr/bin/mongodump -o /data/dump
    * * * * * /usr/bin/python /root/BitVisual/server/markets_updater.py

Optinal: Setup git hooks to copy the 3 server files to /var/www/bitvisual/python after commits
