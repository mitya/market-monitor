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

rake iex:candles:days:previous tinkoff:prices:uniq tinkoff:candles:day
rake iex:prices:all iex:candles:days:today # after US open

// rake tinkoff:prices:all # morning only
// rake iex:prices:all tinkoff:prices:uniq
// rake iex:prices:premium tinkoff:prices:all


# Seeking Alpha

    Array.from(document.querySelectorAll('.a-info > span:first-child')).map(e => e.innerText)
    tickers = []
    Instrument.reject_missing(tickers).join(' ')

# Adding new tickers

rake tinkoff:premium:import tickers='TEVA ARCH BTU'
rake iex:stats tickers='TEVA ARCH BTU' company=1
rake iex:candles:days:on_dates tickers='TEVA ARCH BTU'
