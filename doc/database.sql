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



DROP TABLE aggregates;

CREATE TABLE aggregates (
    id BIGSERIAL PRIMARY KEY,
    ticker character varying NOT NULL,
    date date NOT NULL,
    current boolean NOT NULL DEFAULT false,
    close numeric(20,4),
    close_change real,
    d1 real,
    d2 real,
    d3 real,
    d4 real,
    w1 real,
    w2 real,
    m1 real,
    d1_vol real,
    d2_vol real,
    d3_vol real,
    d4_vol real,
    w1_vol real,
    w2_vol real,
    m1_vol real,
    d1_volume real,
    d2_volume real,
    d3_volume real,
    d4_volume real,
    w1_volume real,
    w2_volume real,
    m1_volume real,
    d2020_0323 real,
    d2020_0219 real,
    d2020_1106 real,
    d2021_0512 real,
    d2021_0820 real,
    y2017 real,
    y2018 real,
    y2019 real,
    y2020 real,
    y2021 real,
    days_up integer,
    lowest_day_date date,
    lowest_day_gain real,
    data jsonb DEFAULT '{}'::jsonb,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);

-- Indices -------------------------------------------------------

CREATE INDEX index_aggregates_on_current ON aggregates(current bool_ops);
CREATE UNIQUE INDEX index_aggregates_on_ticker_and_date ON aggregates(ticker text_ops,date date_ops);
CREATE INDEX index_aggregates_on_ticker ON aggregates(ticker text_ops);
CREATE INDEX index_aggregates_on_d2021_0512 ON aggregates(d2021_0512);
CREATE INDEX index_aggregates_on_d2021_0820 ON aggregates(d2021_0820);
CREATE INDEX index_aggregates_on_y2021 ON aggregates(y2021);



-- DDL generated by Postico 1.5.19
-- Not all database features are supported. Do not use for backup.

-- Table Definition ----------------------------------------------

CREATE TABLE candles_m3 (
    id BIGSERIAL PRIMARY KEY,
    ticker character varying,
    interval character(4) NOT NULL,
    date date NOT NULL,
    time time without time zone NOT NULL,
    open numeric(20,4) NOT NULL,
    close numeric(20,4) NOT NULL,
    high numeric(20,4) NOT NULL,
    low numeric(20,4) NOT NULL,
    volume integer NOT NULL,
    source character varying NOT NULL,
    ongoing boolean DEFAULT false NOT NULL,
    analyzed boolean DEFAULT false NOT NULL
);

CREATE INDEX candles_m3_ticker_idx ON candles_m3(ticker text_ops);
CREATE INDEX candles_m3_ticker_date_idx ON candles_m3(ticker text_ops,date date_ops);



alter table candles_m3 ALTER COLUMN source TYPE candle_source using source::candle_source;
