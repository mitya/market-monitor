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
rake iex:insider_transactions iex:insider_transactions:cache
rake iex:days:missing

# Run daily

rake main
rake prices

// rake iex:candles:days:previous iex:prices:all iex:candles:days:today
// rake tinkoff:candles:day:latest tinkoff:prices:uniq
// rake iex:prices:all tinkoff:prices:uniq
// rake iex:prices:premium tinkoff:prices:all

rake tinkoff:hours:import

# Adding new tickers

## IEX
export tickers='A AA AAIC'
rake tinkoff:premium:import
rake iex:days:missing since=2021-01-01 special=1 ok=1

## Tinkoff
rake tinkoff:instruments:sync ok=1
export tickers='OGN STE RUN CRSP'
rake tinkoff:logos:download

## All
rake iex:stats company=1 iex:tops:set_sectors iex:logos:download iex:symbols:peers iex:price_targets

## Optional
rake iex:days:period period=ytd
rake iex:price_targets:missing
rake instruments:remove ticker=ACIA


## Import List

rake clear_list tickers='NYSE:CLF,NASDAQ:ICPT,NASDAQ:TLRY,NASDAQ:HRTX,NYSE:M,NASDAQ:FATE,NYSE:X,NASDAQ:ATRA,NYSE:GOTU,MOEX:VTBR,NASDAQ:MRNA,NASDAQ:FOLD,MOEX:MAGN,NASDAQ:METC,NASDAQ:DISCA,NYSE:NRG,MOEX:YNDX,NASDAQ:COIN,MOEX:GMKN,NASDAQ:INCY,NYSE:TWTR,NASDAQ:YY,NYSE:BTU,NYSE:AYX,NYSE:XRX,NASDAQ:VIAC,MOEX:AGRO,MOEX:SMLT,NYSE:COG,NYSE:VALE,NYSE:PKI,NASDAQ:ATNX,NASDAQ:CRUS,NASDAQ:TPIC,NASDAQ:GTX,MOEX:FIVE,MOEX:LNTA,NYSE:ZIM,NYSE:AR,MOEX:MVID,NASDAQ:EHTH,NYSE:NI,NASDAQ:CERN,NASDAQ:QDEL,MOEX:SIBN,NYSE:RRC,MOEX:QIWI,NASDAQ:AMZN,MOEX:MAIL,NASDAQ:AAPL,NASDAQ:CEVA,MOEX:RSTI,NYSE:RIG,NYSE:RDS.A,NYSE:MAC,MOEX:GAZP,NYSE:SJI,NYSE:MO,NYSE:ET,NASDAQ:INTC,MOEX:AMEZ,MOEX:SBER,MOEX:GLTR,NYSE:SPG,NASDAQ:GOSS,MOEX:CHEP,MOEX:FLOT,NYSE:SWN,MOEX:POGR,NYSE:FRO,MOEX:RUAL,NYSE:KGC,MOEX:ETLN,AMEX:NUGT,NASDAQ:GTHX,MOEX:ROSN,NYSE:PAGS,NYSE:EQT,NASDAQ:ATEX,MOEX:SNGSP,NYSE:HHC,NASDAQ:VEON,MOEX:FESH,MOEX:NFAZ,XETR:TKA,NYSE:HII,NYSE:J,NASDAQ:TSLA,MOEX:POLY,NASDAQ:APEI,NYSE:EURN,NASDAQ:FB,NASDAQ:STRL,NYSE:FTI,NYSE:BABA,MOEX:AFKS,NYSE:CLR,NYSE:STNG,NYSE:CYD,NYSE:HCC,AMEX:PRNT,NASDAQ:QRVO,NASDAQ:FANG,MOEX:CHMK,NASDAQ:LITE,MOEX:RNFT,NASDAQ:VNOM,NYSE:NOK,NASDAQ:TENB,NYSE:FCX,NASDAQ:BYND,NYSE:NAT,NASDAQ:ETSY,NASDAQ:HLIT,NYSE:ESTC,NASDAQ:ALTO,NYSE:AI,NASDAQ:DOCU,NYSE:MATX,NYSE:ARCH,NASDAQ:ACHV,NASDAQ:CHEF,NYSE:FSLY,NYSE:DK,NASDAQ:CHX,NYSE:GTT,NYSE:MFGP,NYSE:SPR,NASDAQ:OSUR,NYSE:COTY,NYSE:LC,NYSE:TUP,NYSE:FTCH,MOEX:UWGN,NYSE:SPCE,NYSE:PBF,NASDAQ:BBBY,NYSE:UNFI'
