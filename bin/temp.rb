Iex.import_day_candles 'SPB@US', period: 'previous'




/usr/local/Cellar/postgresql@13/13.4/bin/postgres -D /usr/local/var/postgres
/usr/local/Cellar/postgresql@13/13.4/bin/pg_ctl start -D /usr/local/var/postgres

/usr/local/opt/postgresql/bin/pg_upgrad
/usr/local/opt/postgresql
/usr/local/opt/postgresql/bin/pg_upgrade -r -b /usr/local/Cellar/postgresql@13/13.4/bin -B /usr/local/opt/postgresql/bin -d /usr/local/var/postgresql\@13/ -D /usr/local/var/postgres --checkll
