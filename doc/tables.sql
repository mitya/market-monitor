CREATE TABLE candles_m1 (
    id bigint PRIMARY KEY,
    ticker character varying NOT NULL,
    interval character varying NOT NULL DEFAULT '1min'::character varying,
    date date NOT NULL,
    time time without time zone NOT NULL,
    open numeric(20,4) NOT NULL,
    close numeric(20,4) NOT NULL,
    high numeric(20,4) NOT NULL,
    low numeric(20,4) NOT NULL,
    volume integer NOT NULL,
    source character varying NOT NULL DEFAULT 'iex'::character varying,
    ongoing boolean NOT NULL DEFAULT false,
    analyzed boolean NOT NULL DEFAULT false,
    created_at timestamp without time zone NOT NULL DEFAULT now(),
    updated_at timestamp without time zone NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX candles_m1_pkey ON candles_m1(id int8_ops);
CREATE INDEX candles_m1_ticker_idx ON candles_m1(ticker text_ops);
CREATE INDEX candles_m1_ticker_interval_date_idx ON candles_m1(ticker text_ops,date date_ops);



-- DDL generated by Postico 1.5.19
-- Not all database features are supported. Do not use for backup.

-- Table Definition ----------------------------------------------

CREATE TABLE aggregates (
    id BIGSERIAL PRIMARY KEY,
    ticker character varying NOT NULL,
    date date NOT NULL,
    current boolean NOT NULL DEFAULT false,
    close numeric(20,4),
    close_change double precision,
    d1 double precision,
    d1_vol double precision,
    d2 double precision,
    d2_vol double precision,
    d3 double precision,
    d3_vol double precision,
    d4 double precision,
    d4_vol double precision,
    w1 double precision,
    w1_vol double precision,
    w2 double precision,
    w2_vol double precision,
    m1 double precision,
    m1_vol double precision,
    y2021 double precision,
    nov06 double precision,
    mar23 double precision,
    feb19 double precision,
    y2020 double precision,
    y2019 double precision,
    y2018 double precision,
    y2017 double precision,
    days_up integer,
    lowest_day_date date,
    lowest_day_gain double precision,
    d1_volume double precision,
    d2_volume double precision,
    d3_volume double precision,
    d4_volume double precision,
    w1_volume double precision,
    w2_volume double precision,
    m1_volume double precision,
    ema_20 numeric(20,4),
    ema_50 numeric(20,4),
    ema_200 numeric(20,4),
    ema_20_trend integer,
    ema_50_trend integer,
    ema_200_trend integer,
    data jsonb DEFAULT '{}'::jsonb,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);

-- Indices -------------------------------------------------------

CREATE INDEX index_aggregates_on_ticker ON aggregates(ticker text_ops);
CREATE UNIQUE INDEX index_aggregates_on_ticker_and_date ON aggregates(ticker text_ops,date date_ops);
CREATE INDEX index_aggregates_on_current ON aggregates(current bool_ops);
