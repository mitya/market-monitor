select * from candles where interval = 'day' and date = '2021-05-31' and ticker in (select ticker from instruments where currency = 'USD')
delete from candles where interval = 'day' and date = '2021-05-31' and ticker in (select ticker from instruments where currency = 'USD')


CREATE TABLE candles_d1_tinkoff (
    id bigint PRIMARY KEY,
    ticker character varying NOT NULL,
    interval character varying NOT NULL DEFAULT 'day'::character varying,
    date date NOT NULL,
    time timestamp without time zone NOT NULL,
    open numeric(20,4) NOT NULL,
    close numeric(20,4) NOT NULL,
    high numeric(20,4) NOT NULL,
    low numeric(20,4) NOT NULL,
    volume integer NOT NULL,
    source character varying NOT NULL DEFAULT 'tinkoff'::character varying,
    ongoing boolean NOT NULL DEFAULT false,
    analyzed boolean NOT NULL DEFAULT false,
    created_at timestamp without time zone NOT NULL DEFAULT now(),
    updated_at timestamp without time zone NOT NULL DEFAULT now()
);

-- Indices -------------------------------------------------------

CREATE UNIQUE INDEX candles_d1_tinkoff_pkey ON candles_d1_tinkoff(id int8_ops);
CREATE INDEX candles_d1_tinkoff_ticker_idx ON candles_d1_tinkoff(ticker text_ops);
CREATE INDEX candles_d1_tinkoff_ticker_interval_date_idx ON candles_d1_tinkoff(ticker text_ops,date date_ops);
