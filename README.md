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
rake iex:days:missing

# Run daily

rake main
rake prices

// rake iex:candles:days:previous iex:prices:all iex:candles:days:today
// rake tinkoff:candles:day:latest tinkoff:prices:uniq
// rake iex:prices:all tinkoff:prices:uniq
// rake iex:prices:premium tinkoff:prices:all


# Seeking Alpha

    Array.from(document.querySelectorAll('.a-info > span:first-child')).map(e => e.innerText)
    tickers = []
    Instrument.reject_missing(tickers).join(' ')

# Adding new tickers

## IEX
export tickers='ONEM DDD ATEN ABB ABEO ABM ACCD ACRX ACHV ACRS ACOR ADMP AEY ACET ADNT ADMA ASND CLLS KC TLK ADT ADWS ADES ADVM ADEYN AER AFMD AGRX AGNC API ALRN ATSG AIRFP EADSY AKBTY AKCA AKBA ACI ALEC ALKS ALNA ALVR AOSL AMR ALT ALTO ALTM AMRN AMBA AMC AXL AEP AMWL AMRS NGLOY AU ABI NLY AM AR APHA APOG APO AAOI APRE AQMS AQST ABR MT ARCH ARCO ASC AAIC AT1 ARRY APAM ASAN ASX ASML ASAZY ATNX AAWW TEAM ATO ATTU AUO ACB ATHM AVDL AVEO CAR AXNX AYRO AZRE'
rake tinkoff:premium:import
rake iex:days:missing since=2021-01-01

## Tinkoff
rake instruments:remove ticker=OBUV
rake tinkoff:instruments:sync ok=1
rake tinkoff:days:missing
rake tinkoff:days:year
// tinkoff logos

## All
rake iex:stats company=1
rake iex:set_sectors_from_tops
rake iex:logos:download
rake iex:symbols:peers
