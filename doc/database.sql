select * from candles where interval = 'day' and date = '2021-05-31' and ticker in (select ticker from instruments where currency = 'USD')
delete from candles where interval = 'day' and date = '2021-05-31' and ticker in (select ticker from instruments where currency = 'USD')
