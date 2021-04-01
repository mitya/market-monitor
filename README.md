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

    coffee bin/tinkoff.coffee stocks > db/data/stocks.json

    https://spbexchange.ru/ru/listing/securities/list/
    iconv -f CP1251 -t UTF8 db/data/spbex.csv > db/data/spbex-utf.csv


# Run once in a while

rake iex:stats
rake iex:price_targets
rake iex:insider-transactions set=main


# Run daily

rake day aggregate

// rake iex:candles:days:previous iex:prices:all iex:candles:days:today
// rake tinkoff:candles:day:latest tinkoff:prices:uniq
// rake iex:prices:all tinkoff:prices:uniq
// rake iex:prices:premium tinkoff:prices:all


# Seeking Alpha

    Array.from(document.querySelectorAll('.a-info > span:first-child')).map(e => e.innerText)
    tickers = []
    Instrument.reject_missing(tickers).join(' ')

# Adding new tickers

rake tinkoff:premium:import tickers='TEVA ARCH BTU'
rake iex:candles:days:on_dates tickers='TEVA ARCH BTU'
rake iex:stats tickers='TEVA ARCH BTU' company=1
rake iex:set_sectors_from_tops
rake iex:logos:download tickers='TEVA ARCH BTU'
