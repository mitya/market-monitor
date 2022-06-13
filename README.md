## Run daily

    rake main

## Run during trading hours to get intraday signals

    rake sync:ru
    rake sync:us

# Run if was not used for a while

    rake tinkoff:days:missing since=2022-04-07 ok=1
    rake tinkoff:days:missing since=2022-04-07 ok=1 tickers='XX YY'
    rake tinkoff:days:years tickers='XX YY'
    rake levels:hits:week

## Destroying tickers

    rake t:destroy ticker='DKNG' ok=1

## IEX

    rake iex:days:missing since=2022-01-01
    rake iex:symbols:load iex:symbols:refresh    
    rake iex:insider_transactions
    rake iex:stats
    rake iex:price_targets
    rake iex:recommendations
    rake iex:stats company=1 iex:tops:set_sectors iex:logos:download iex:symbols:peers
    rake iex:days:missing since=2021-12-01 special=1 ok=1 reverse=1 tickers='XX'

## Tinkoff

    rake tinkoff:instruments ok=1
    rake empty:iex
    export tickers='XX YY'
    rake tinkoff:logos:download
    rake tinkoff:days:years tinkoff:days:special
    rake set_first_date_auto
    rake set_first_date ticker=XX date=2021-03-25
