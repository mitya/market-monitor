# Фичи скринера
— список бумаг с динамикой за неделю / месяц / от интересных дат
— инсайдерские покупки по своему списку
— консенсус прогнозы по своему списку
— идентификация простейших паттернов типа ползучего роста

— отслеживание взрывов на пятиминутках
— автоматическое выставление заявок в Тинькове на уровнях для спекуляций

— загружать текущие котировки, EOD данные, инсайдерские сделки, прогнозы, общая инфа по тикерам
— UI для просмотра списка бумаг с фильтрами
— опционы?



# Data Sources

https://financialmodelingprep.com/
https://gocharting.com/
https://github.com/rrag/react-stockcharts
https://icebergh.io
https://www.interactivebrokers.com/en/index.php?f=14193

    coffee bin/tinkoff.coffee stocks > db/data/stocks.json

    https://spbexchange.ru/ru/listing/securities/list/
    iconv -f CP1251 -t UTF8 db/data/spbex.csv > db/data/spbex-utf.csv


# Run once in a while

rake iex:stats
rake iex:price_targets
rake iex:insider_transactions iex:insider_transactions:cache
rake iex:days:missing
rake set_average_volume
rake levels:hits:week

# Run daily

rake main
rake prices
rake tinkoff:candles:import:5min:last
rake tinkoff:prices:pre
rake options:day
rake iex:insider_transactions
rake iex:days:missing ok=1 since=2021-07-01

// rake iex:candles:days:previous iex:prices:all iex:candles:days:today
// rake tinkoff:candles:day:latest tinkoff:prices:uniq
// rake iex:prices:all tinkoff:prices:uniq
// rake iex:prices:premium tinkoff:prices:all

rake tinkoff:hours:import

# Adding new tickers

## IEX
rake tinkoff:premium:import

## Tinkoff
rake tinkoff:instruments:sync ok=1
rake SetIexTickers
rake empty
export tickers=''
rake tinkoff:logos:download iex:stats company=1 iex:tops:set_sectors iex:logos:download iex:symbols:peers iex:price_targets
rake iex:days:missing since=2020-01-01 special=1 ok=1 # rake tinkoff:days:year tinkoff:days:special
rake candles:set_prev_closes candles:set_average_change

## Optional
rake set_first_date_auto tickers='GTX'
rake set_first_date ticker=GRUB date=2021-03-25
rake iex:symbols:load iex:symbols:refresh
rake iex:days:period period=ytd
rake t:destroy ticker=CHK ok=1
rake tinkoff:days:year tinkoff:days:special tickers=FLOT

## Import List
rake list:clear tickers=''
rake list:import list=portfolio


rake options:day
rake options:week
rake signals:import


## Dates

* splits were synced on 2021-09-11
