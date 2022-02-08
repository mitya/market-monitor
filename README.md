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

## Swing
* Future charts — keep an eye on all commodity futures on one page
+ MA scanner — look for those who visit the MA first time in a while
* Sell-off exhaustions scanner — look for the first green on spiked up day after a downtrend
* Random date comparer
* Low volume scan — lowest vol in N days

## Intraday
* DMA hits intraday
* double tops (0.5%) on 5m charts (with 2+ bars between hits)
* breakouts of today top, brewakouts of yesterday top (& breakdowns)
* retests of day open / yesterday close after 1%+ move
* x-large volume on 1/3/5m charts
* Low volume scan — lowest vol in N bars
* intraday low-high change, low-current change, last 10 min change


# Run once in a while

rake iex:insider_transactions
rake iex:stats
rake iex:price_targets
rake iex:recommendations
rake set_average_volume
rake candles:set_average_change
rake candles:set_d5_volume

rake iex:days:missing
rake tinkoff:days:missing ok=1 tickers='SPBE' since=2021-09-01
rake tinkoff:days:year tickers=''

rake levels:hits:week

# Run daily
rake main
rake prices

rake tinkoff:candles:import:5min:last
rake tinkoff:prices:pre
rake options:day


# Run if haven't used for a whilte
rake     iex:days:missing since=2022-01-01 ok=1
rake tinkoff:days:missing since=2022-01-01 ok=1 tickers=''

# Destroying tickers

rake t:destroy ticker=SLG ok=1
rake tinkoff:instruments:sync ok=1


# Adding new tickers

## IEX
rake iex:symbols:load
rake tinkoff:premium:import

## Tinkoff
rake tinkoff:instruments:sync ok=1
rake SetIexTickers
rake empty:iex
export tickers=''
rake tinkoff:logos:download iex:stats company=1 iex:tops:set_sectors iex:logos:download 
rake iex:symbols:peers iex:price_targets
rake iex:days:missing since=2020-01-01 special=1 ok=1 reverse=1
rake candles:set_prev_closes candles:set_average_change


## Optional
rake set_first_date_auto tickers='AORT'
rake set_first_date ticker=GRUB date=2021-03-25
rake iex:symbols:load iex:symbols:refresh
rake iex:days:period period=ytd
rake tinkoff:days:year tinkoff:days:special tickers='VKCO LENT POSI'
rake tinkoff:days:year tinkoff:days:special

## Import List
rake list:clear tickers=''
rake list:import list=portfolio


## Intraday

rake intraday:sync
