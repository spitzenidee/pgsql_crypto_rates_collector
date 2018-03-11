DROP SCHEMA IF EXISTS crypto_rates_collector CASCADE
;
CREATE SCHEMA IF NOT EXISTS crypto_rates_collector
;
COMMIT
;

-- Set the search path to the schema which we want to deploy all functionality in (don't include "public"
-- or we may end up there by accident):
SET search_path = crypto_rates_collector
;
DROP TABLE IF EXISTS t_config
;
CREATE TABLE IF NOT EXISTS t_config (
  cfg_key   text NOT NULL,
  cfg_value text NULL,
  comment   text NULL,
  UNIQUE (cfg_key, cfg_value)
);

COMMENT ON TABLE t_config             IS 'Holds all necessary config parameters for driving exchange API access via stored procedures';
COMMENT ON COLUMN t_config.cfg_key    IS 'The name/key of a configuration parameter';
COMMENT ON COLUMN t_config.cfg_value  IS 'The content/value of a configuration parameter';

-- Insert (default) data, with empty "cfg_value" where advised (API key and secret for example):
INSERT INTO t_config (cfg_key, cfg_value, comment) VALUES ('schema_version', '1', 'Indicates the version of schema "crypto_rates_collector" in case we need to update in the future (there is no strategy yet)');
INSERT INTO t_config (cfg_key, cfg_value, comment) VALUES ('api_access_delay', '3', 'Delay in seconds (e.g. "1", "2", "3.8") between accessing the same API in order to prevent API hammering and, consequently, IP blocking');
INSERT INTO t_config (cfg_key, cfg_value, comment) VALUES ('api_access_max_retries', '6', 'Maximum retries to get a tradepair from an exchange before giving up');

INSERT INTO t_config (cfg_key, cfg_value, comment) VALUES ('binance_api_uri', 'https://api.binance.com/api/v3', 'URL of the Binance API');
INSERT INTO t_config (cfg_key, cfg_value, comment) VALUES ('binance_api_access_active', 'false', 'May be "true" or "false". Only while "true" rates will be collected from this URI/API');

INSERT INTO t_config (cfg_key, cfg_value, comment) VALUES ('bitcoinde_api_key', '', 'API key for accessing the bitcoin.de API ("showRates" is sufficient at the moment)');
INSERT INTO t_config (cfg_key, cfg_value, comment) VALUES ('bitcoinde_api_secret', '', 'API secret for accessing the bitcoin.de API');
INSERT INTO t_config (cfg_key, cfg_value, comment) VALUES ('bitcoinde_api_uri', 'https://api.bitcoin.de/v2', 'URL of the bitcoin.de API');
INSERT INTO t_config (cfg_key, cfg_value, comment) VALUES ('bitcoinde_api_access_active', 'false', 'May be "true" or "false". Only while "true" rates will be collected from this URI/API');

INSERT INTO t_config (cfg_key, cfg_value, comment) VALUES ('bitstamp_api_uri', 'https://www.bitstamp.net/api/v2', 'URL of the Bitstamp API');
INSERT INTO t_config (cfg_key, cfg_value, comment) VALUES ('bitstamp_api_access_active', 'false', 'May be "true" or "false". Only while "true" rates will be collected from this URI/API');

INSERT INTO t_config (cfg_key, cfg_value, comment) VALUES ('cryptopia_api_uri', 'https://www.cryptopia.co.nz/api', 'URL of the Cryptopia API');
INSERT INTO t_config (cfg_key, cfg_value, comment) VALUES ('cryptopia_api_access_active', 'false', 'May be "true" or "false". Only while "true" rates will be collected from this URI/API');

INSERT INTO t_config (cfg_key, cfg_value, comment) VALUES ('binance_tradepair', 'ETHBTC', 'https://api.binance.com/api/v1/exchangeInfo');
INSERT INTO t_config (cfg_key, cfg_value, comment) VALUES ('binance_tradepair', 'LTCBTC', 'https://api.binance.com/api/v1/exchangeInfo');
INSERT INTO t_config (cfg_key, cfg_value, comment) VALUES ('binance_tradepair', 'XRPBTC', 'https://api.binance.com/api/v1/exchangeInfo');

INSERT INTO t_config (cfg_key, cfg_value, comment) VALUES ('bitcoinde_tradepair', 'btceur', '');
INSERT INTO t_config (cfg_key, cfg_value, comment) VALUES ('bitcoinde_tradepair', 'etheur', '');
INSERT INTO t_config (cfg_key, cfg_value, comment) VALUES ('bitcoinde_tradepair', 'bcheur', '');

INSERT INTO t_config (cfg_key, cfg_value, comment) VALUES ('bitstamp_tradepair', 'btceur', 'https://www.bitstamp.net/api/');
INSERT INTO t_config (cfg_key, cfg_value, comment) VALUES ('bitstamp_tradepair', 'btcusd', 'https://www.bitstamp.net/api/');
INSERT INTO t_config (cfg_key, cfg_value, comment) VALUES ('bitstamp_tradepair', 'eurusd', 'https://www.bitstamp.net/api/');

INSERT INTO t_config (cfg_key, cfg_value, comment) VALUES ('cryptopia_tradepair', 'ETH_BTC', 'https://www.cryptopia.co.nz/api/GetTradePairs');
INSERT INTO t_config (cfg_key, cfg_value, comment) VALUES ('cryptopia_tradepair', 'TRC_BTC', 'https://www.cryptopia.co.nz/api/GetTradePairs');
INSERT INTO t_config (cfg_key, cfg_value, comment) VALUES ('cryptopia_tradepair', 'PPC_BTC', 'https://www.cryptopia.co.nz/api/GetTradePairs');
INSERT INTO t_config (cfg_key, cfg_value, comment) VALUES ('cryptopia_tradepair', 'ADC_BTC', 'https://www.cryptopia.co.nz/api/GetTradePairs');
INSERT INTO t_config (cfg_key, cfg_value, comment) VALUES ('cryptopia_tradepair', 'ARC_BTC', 'https://www.cryptopia.co.nz/api/GetTradePairs');

SET search_path = crypto_rates_collector,public
;
COMMIT
;
-- Set the search path to the schema which we want to deploy all functionality in (don't include "public"
-- or we may end up there by accident):
SET search_path = crypto_rates_collector
;
DROP TABLE IF EXISTS t_log
;
CREATE TABLE IF NOT EXISTS t_log (
  id                  serial PRIMARY KEY,
  timestamp_when      timestamp NOT NULL,
  loglevel            text NOT NULL,
  message             text NOT NULL,
  CONSTRAINT t_log_valid_loglevels CHECK ( loglevel IN ('DEBUG', 'INFO', 'WARN', 'ERROR') )
);
CREATE INDEX t_log__index_loglevel ON t_log (loglevel)
;
CREATE INDEX t_log__index_timestamp ON t_log USING btree(timestamp_when)
;
SET search_path = crypto_rates_collector,public
;
COMMIT
;
-- Set the search path to the schema which we want to deploy all functionality in (don't include "public"
-- or we may end up there by accident):
SET search_path = crypto_rates_collector
;
DROP TABLE IF EXISTS t_binance_rates
;
CREATE TABLE IF NOT EXISTS t_binance_rates (
  timestamp_when      timestamp NOT NULL,
  trade_pair          text NOT NULL,
  http_response       jsonb NOT NULL,
  price               numeric,
  UNIQUE (timestamp_when, trade_pair)
);
CREATE INDEX t_binance_rates__index__valuepair ON t_binance_rates (trade_pair)
;

COMMENT ON TABLE t_binance_rates                  IS 'Stores all queried rates for a value pair from binance.com';
COMMENT ON COLUMN t_binance_rates.timestamp_when  IS 'Point in time for recording the value-pair rates';
COMMENT ON COLUMN t_binance_rates.trade_pair      IS 'The value pair, for which the row stores the rate (e.g. ETHBTC)';

-- Remove function and depending trigger via CASCADE:
DROP FUNCTION IF EXISTS tr_binance_extract_rates_from_json() CASCADE
;

CREATE OR REPLACE FUNCTION tr_binance_extract_rates_from_json()
  RETURNS trigger AS
$BODY$
BEGIN
  new.price       := new.http_response ->> 'price';
  RETURN NEW;
END;
$BODY$ LANGUAGE plpgsql
;

CREATE TRIGGER t_binance_rates__trigger__extract_json
  BEFORE INSERT OR UPDATE OF http_response
  ON t_binance_rates
  FOR EACH ROW
  EXECUTE PROCEDURE crypto_rates_collector.tr_binance_extract_rates_from_json()
;

SET search_path = crypto_rates_collector,public
;
COMMIT
;
-- Set the search path to the schema which we want to deploy all functionality in (don't include "public"
-- or we may end up there by accident):
SET search_path = crypto_rates_collector
;
DROP TABLE IF EXISTS t_bitcoinde_rates
;
CREATE TABLE IF NOT EXISTS t_bitcoinde_rates (
  timestamp_when      timestamp NOT NULL,
  trade_pair          text NOT NULL,
  http_response       jsonb NOT NULL,
  rate_weighted       numeric,
  rate_weighted_3h    numeric,
  rate_weighted_12h   numeric,
  UNIQUE (timestamp_when, trade_pair)
);
CREATE INDEX t_bitcoinde_rates__index__valuepair ON t_bitcoinde_rates (trade_pair)
;

COMMENT ON TABLE t_bitcoinde_rates                  IS 'Stores all queried rates for a value pair from bitcoin.de';
COMMENT ON COLUMN t_bitcoinde_rates.timestamp_when  IS 'Point in time for recording the value-pair rates';
COMMENT ON COLUMN t_bitcoinde_rates.trade_pair      IS 'The value pair, for which the row stores the rate (e.g. BTCEUR)';

-- Remove function and depending trigger via CASCADE:
DROP FUNCTION IF EXISTS tr_bitcoinde_extract_rates_from_json() CASCADE
;

CREATE OR REPLACE FUNCTION tr_bitcoinde_extract_rates_from_json()
  RETURNS trigger AS
$BODY$
BEGIN
  new.rate_weighted       := new.http_response -> 'rates' ->> 'rate_weighted';
  new.rate_weighted_3h    := new.http_response -> 'rates' ->> 'rate_weighted_3h';
  new.rate_weighted_12h   := new.http_response -> 'rates' ->> 'rate_weighted_12h';
  RETURN NEW;
END;
$BODY$ LANGUAGE plpgsql
;

CREATE TRIGGER t_bitcoinde_rates__trigger__extract_json
  BEFORE INSERT OR UPDATE OF http_response
  ON t_bitcoinde_rates
  FOR EACH ROW
  EXECUTE PROCEDURE crypto_rates_collector.tr_bitcoinde_extract_rates_from_json()
;

SET search_path = crypto_rates_collector,public
;
COMMIT
;
-- Set the search path to the schema which we want to deploy all functionality in (don't include "public"
-- or we may end up there by accident):
SET search_path = crypto_rates_collector
;
DROP TABLE IF EXISTS t_bitstamp_rates
;
CREATE TABLE IF NOT EXISTS t_bitstamp_rates (
  timestamp_when      timestamp NOT NULL,
  trade_pair          text NOT NULL,
  http_response       jsonb NOT NULL,
  last_price          numeric,
  UNIQUE (timestamp_when, trade_pair)
);
CREATE INDEX t_bitstamp_rates__index__valuepair ON t_bitstamp_rates (trade_pair)
;

COMMENT ON TABLE t_bitstamp_rates                  IS 'Stores all queried rates for a value pair from bitstamp.net';
COMMENT ON COLUMN t_bitstamp_rates.timestamp_when  IS 'Point in time for recording the value-pair rates';
COMMENT ON COLUMN t_bitstamp_rates.trade_pair      IS 'The value pair, for which the row stores the rate (e.g. "btceur")';

-- Remove function and depending trigger via CASCADE:
DROP FUNCTION IF EXISTS tr_bitstamp_extract_rates_from_json() CASCADE
;

CREATE OR REPLACE FUNCTION tr_bitstamp_extract_rates_from_json()
  RETURNS trigger AS
$BODY$
BEGIN
  new.last_price := new.http_response ->> 'last';
  RETURN NEW;
END;
$BODY$ LANGUAGE plpgsql
;

CREATE TRIGGER t_bitstamp_rates__trigger__extract_json
  BEFORE INSERT OR UPDATE OF http_response
  ON t_bitstamp_rates
  FOR EACH ROW
  EXECUTE PROCEDURE crypto_rates_collector.tr_bitstamp_extract_rates_from_json()
;

SET search_path = crypto_rates_collector,public
;
COMMIT
;
-- Set the search path to the schema which we want to deploy all functionality in (don't include "public"
-- or we may end up there by accident):
SET search_path = crypto_rates_collector
;
DROP TABLE IF EXISTS t_cryptopia_rates
;
CREATE TABLE IF NOT EXISTS t_cryptopia_rates (
  timestamp_when      timestamp NOT NULL,
  trade_pair          text NOT NULL,
  http_response       jsonb NOT NULL,
  lastprice           numeric,
  UNIQUE (timestamp_when, trade_pair)
);
CREATE INDEX t_cryptopia_rates__index__valuepair ON t_cryptopia_rates (trade_pair)
;

COMMENT ON TABLE t_cryptopia_rates                  IS 'Stores all queried rates for a value pair from cryptopia.co.nz';
COMMENT ON COLUMN t_cryptopia_rates.timestamp_when  IS 'Point in time for recording the value-pair rates';
COMMENT ON COLUMN t_cryptopia_rates.trade_pair      IS 'The value pair, for which the row stores the rate (e.g. ETH_BTC)';

-- Remove function and depending trigger via CASCADE:
DROP FUNCTION IF EXISTS tr_cryptopia_extract_rates_from_json() CASCADE
;

CREATE OR REPLACE FUNCTION tr_cryptopia_extract_rates_from_json()
  RETURNS trigger AS
$BODY$
BEGIN
  new.lastprice := new.http_response -> 'Data' ->> 'LastPrice';
  RETURN NEW;
END;
$BODY$ LANGUAGE plpgsql
;

CREATE TRIGGER t_cryptopia_rates__trigger__extract_json
  BEFORE INSERT OR UPDATE OF http_response
  ON t_cryptopia_rates
  FOR EACH ROW
  EXECUTE PROCEDURE crypto_rates_collector.tr_cryptopia_extract_rates_from_json()
;

SET search_path = crypto_rates_collector,public
;
COMMIT
;
-- Set the search path to the schema which we want to deploy all functionality in (don't include "public"
-- or we may end up there by accident):
SET search_path = crypto_rates_collector
;
CREATE OR REPLACE FUNCTION insert_log_msg(
  p_loglevel  text,   -- ('DEBUG', 'INFO', 'WARN', 'ERROR')
  p_message   text
)
RETURNS VOID
AS $$
BEGIN
  INSERT INTO crypto_rates_collector.t_log ( timestamp_when, loglevel, message ) VALUES ( now(), p_loglevel, p_message );
END;
$$ LANGUAGE plpgsql;

SET search_path = crypto_rates_collector,public
;
COMMIT
;
-- Set the search path to the schema which we want to deploy all functionality in (don't include "public"
-- or we may end up there by accident):
SET search_path = crypto_rates_collector
;
CREATE OR REPLACE FUNCTION binance_api___ticker_price(
  p_tradepair          text
)
RETURNS jsonb
AS $$
DECLARE
  v_base_uri            text;
  v_full_uri            text;
  v_http_response       jsonb;
  v_api_access_active   boolean;
  v_message_text        text;
  v_exception_detail    text;
  v_exception_hint      text;
BEGIN
  -- Prepare all needed parameters for the API calls:
  SELECT cfg_value          INTO v_base_uri           FROM crypto_rates_collector.t_config WHERE cfg_key = 'binance_api_uri';
  SELECT cfg_value::boolean INTO v_api_access_active  FROM crypto_rates_collector.t_config WHERE cfg_key = 'binance_api_access_active';
  -- Prepare the endpoint URI for getting current rates:
  v_full_uri := v_base_uri || '/ticker/price?symbol=' || p_tradepair;

  -- Set CURL connection and request timeout to 20s each:
  PERFORM http_set_curlopt('CURLOPT_CONNECTTIMEOUT', '20L');
  PERFORM http_set_curlopt('CURLOPT_TIMEOUT', '20L');
  PERFORM http_set_curlopt('CURLOPT_TCP_KEEPALIVE', '1L');
  PERFORM http_set_curlopt('CURLOPT_TCP_KEEPIDLE', '3L');

  IF v_api_access_active IS TRUE THEN
    -- Prepare the HTTP request, encode/encrpyt the request payload and query the api now:
    SELECT content INTO v_http_response FROM http_get(v_full_uri);
  ELSE
    PERFORM crypto_rates_collector.insert_log_msg('INFO', '[binance_api___ticker_price("' || p_tradepair || '")] - API access to Binance is deactivated in T_CONFIG ("binance_api_access_active").');
  END IF;

  RETURN v_http_response;
EXCEPTION
  WHEN OTHERS THEN
  GET STACKED DIAGNOSTICS
    v_message_text     := MESSAGE_TEXT,
    v_exception_detail := PG_EXCEPTION_DETAIL,
    v_exception_hint   := PG_EXCEPTION_HINT;
    PERFORM crypto_rates_collector.insert_log_msg('ERROR',
                                                  '[binance_api___ticker_price()] - Exception! ' ||
                                                  'Message: "'|| v_message_text ||
                                                  '", Detail: "' || v_exception_detail ||
                                                  '", Hint: "' || v_exception_hint || '".'
                                                 );
    RETURN null;
END;
$$ LANGUAGE plpgsql;

SET search_path = crypto_rates_collector,public
;
COMMIT
;
-- Set the search path to the schema which we want to deploy all functionality in (don't include "public"
-- or we may end up there by accident):
SET search_path = crypto_rates_collector
;
CREATE OR REPLACE FUNCTION binance_usr___query_and_store_prices()
RETURNS VOID
AS $$
DECLARE
  v_timestamp               timestamptz;
  v_api_access_active       boolean;
  v_api_access_delay        numeric;
  v_api_access_max_retries  integer;
  v_retries                 integer := 0;
  v_tradepair               text;
  v_http_response           jsonb;
  v_message_text            text;
  v_exception_detail        text;
  v_exception_hint          text;
BEGIN
  -- Get current timestamp for inserting all results into table:
  v_timestamp := now();
  -- Get the delay (seconds) between accessing the API & if the API access is active:
  SELECT cfg_value::numeric INTO v_api_access_delay       FROM crypto_rates_collector.t_config WHERE cfg_key = 'api_access_delay';
  SELECT cfg_value::integer INTO v_api_access_max_retries FROM crypto_rates_collector.t_config WHERE cfg_key = 'api_access_max_retries';
  SELECT cfg_value::boolean INTO v_api_access_active      FROM crypto_rates_collector.t_config WHERE cfg_key = 'binance_api_access_active';

  FOR v_tradepair in ( SELECT cfg_value FROM crypto_rates_collector.t_config WHERE cfg_key = 'binance_tradepair' AND cfg_value != '' ORDER BY cfg_value ASC ) LOOP
    -- reset number of retries and http response for each tradepair:
    v_retries       := 0;
    v_http_response := NULL;

    -- try to get a response from the API until max_retries has been reached:
    WHILE ( (v_http_response IS NULL) AND (v_api_access_active IS TRUE) AND (v_retries <= v_api_access_max_retries) ) LOOP
      v_retries       := v_retries + 1;
      IF (v_retries > 1) THEN
        PERFORM crypto_rates_collector.insert_log_msg('WARN', '[binance_usr___query_and_store_prices(), "' || v_tradepair || '"] - API returned NULL, retry #' || v_retries || '.');
      END IF;

      v_http_response := crypto_rates_collector.binance_api___ticker_price(v_tradepair);

      -- sleep for x seconds in order to prevent API hammering. If we need to retry more than once, increase the delay with each retry:
      PERFORM pg_sleep(v_api_access_delay * v_retries);
    END LOOP;

    IF v_http_response IS NOT NULL THEN
      IF (v_retries > 1) THEN
        PERFORM crypto_rates_collector.insert_log_msg('INFO', '[binance_usr___query_and_store_prices(), "' || v_tradepair || '"] - API returned a result after ' || v_retries || ' retries.');
      END IF;
      INSERT INTO crypto_rates_collector.t_binance_rates (
        timestamp_when,
        trade_pair,
        http_response
      )
      VALUES (
        v_timestamp,
        v_tradepair,
        v_http_response
      );
    ELSIF ( (v_http_response IS NULL) AND (v_api_access_active IS TRUE) ) THEN
      PERFORM crypto_rates_collector.insert_log_msg('ERROR', '[binance_usr___query_and_store_prices(), "' || v_tradepair || '"] - HTTP response from "bitcoinde_api___rates()" was still NULL after ' || v_retries || ' retries. Quitting for now.');
    ELSE
      PERFORM crypto_rates_collector.insert_log_msg('WARN', '[binance_usr___query_and_store_prices(), "' || v_tradepair || '"] - HTTP response from "bitcoinde_api___rates()" is NULL (ok, since API access is deactivated).');
    END IF;

  END LOOP;
EXCEPTION
  WHEN OTHERS THEN
  GET STACKED DIAGNOSTICS
    v_message_text     := MESSAGE_TEXT,
    v_exception_detail := PG_EXCEPTION_DETAIL,
    v_exception_hint   := PG_EXCEPTION_HINT;
    PERFORM crypto_rates_collector.insert_log_msg('ERROR',
                                                  '[binance_usr___query_and_store_prices()] - Exception! ' ||
                                                  'Message: "'|| v_message_text ||
                                                  '", Detail: "' || v_exception_detail ||
                                                  '", Hint: "' || v_exception_hint || '".'
                                                 );
END;
$$ LANGUAGE plpgsql;

SET search_path = crypto_rates_collector,public
;
COMMIT
;
-- Set the search path to the schema which we want to deploy all functionality in (don't include "public"
-- or we may end up there by accident):
SET search_path = crypto_rates_collector
;
CREATE OR REPLACE FUNCTION bitcoinde_api___rates(
  p_nonce text,
  p_tradepair text
)
RETURNS jsonb
AS $$
DECLARE
  v_base_uri            text;
  v_api_key             text;
  v_api_secret          text;
  v_full_uri            text;
  v_http_response       jsonb;
  v_api_access_active   boolean;
  v_message_text        text;
  v_exception_detail    text;
  v_exception_hint      text;
BEGIN
  -- Prepare all needed parameters for the bitcoin.de API calls:
  SELECT cfg_value          INTO v_base_uri           FROM crypto_rates_collector.t_config WHERE cfg_key = 'bitcoinde_api_uri';
  SELECT cfg_value          INTO v_api_key            FROM crypto_rates_collector.t_config WHERE cfg_key = 'bitcoinde_api_key';
  SELECT cfg_value          INTO v_api_secret         FROM crypto_rates_collector.t_config WHERE cfg_key = 'bitcoinde_api_secret';
  SELECT cfg_value::boolean INTO v_api_access_active  FROM crypto_rates_collector.t_config WHERE cfg_key = 'bitcoinde_api_access_active';
  -- Prepare the endpoint URI for getting current rates:
  v_full_uri := v_base_uri || '/rates?trading_pair=' || p_tradepair;

  -- Set CURL connection and request timeout to 20s each:
  PERFORM http_set_curlopt('CURLOPT_CONNECTTIMEOUT', '20L');
  PERFORM http_set_curlopt('CURLOPT_TIMEOUT', '20L');
  PERFORM http_set_curlopt('CURLOPT_TCP_KEEPALIVE', '1L');
  PERFORM http_set_curlopt('CURLOPT_TCP_KEEPIDLE', '3L');

  IF v_api_access_active IS TRUE THEN
    -- Prepare the HTTP request, encode/encrpyt the request payload and query the api now:
    SELECT
      content
    INTO
      v_http_response
    FROM
      http(
        (
          'GET', v_full_uri,
          ARRAY[
            http_header('X-API-KEY', v_api_key),                                        -- must be the bitcoin.de API-KEY (*not* the secret! ;-)
            http_header('X-API-NONCE', p_nonce),                                        -- nonce (here: unix timestamp)
            http_header('X-API-SIGNATURE',
              ENCODE(
                HMAC(
                  concat_ws('#', 'GET', v_full_uri, v_api_key, p_nonce, md5('') ),      -- "payload"
                  v_api_secret,                                                         -- API-SECRET
                  'sha256'                                                              -- Hashing method
                ),
                'hex'                                                                   -- resulting HMAC representation (here: hexdecimal, all lower-case)
              )
            )
          ],
          NULL,
          NULL
        )::http_request
      );
  ELSE
    PERFORM crypto_rates_collector.insert_log_msg('INFO', '[bitcoinde_api___rates("' || p_nonce || '", "' || p_tradepair || '")] - API access to Bitcoin.de is deactivated in T_CONFIG ("bitcoinde_api_access_active").');
  END IF;

  RETURN v_http_response;
EXCEPTION
  WHEN OTHERS THEN
  GET STACKED DIAGNOSTICS
    v_message_text     := MESSAGE_TEXT,
    v_exception_detail := PG_EXCEPTION_DETAIL,
    v_exception_hint   := PG_EXCEPTION_HINT;
    PERFORM crypto_rates_collector.insert_log_msg('ERROR',
                                                  '[bitcoinde_api___rates()] - Exception! ' ||
                                                  'Message: "'|| v_message_text ||
                                                  '", Detail: "' || v_exception_detail ||
                                                  '", Hint: "' || v_exception_hint || '".'
                                                 );
    RETURN null;
END;
$$ LANGUAGE plpgsql;

SET search_path = crypto_rates_collector,public
;
COMMIT
;
-- Set the search path to the schema which we want to deploy all functionality in (don't include "public"
-- or we may end up there by accident):
SET search_path = crypto_rates_collector
;
CREATE OR REPLACE FUNCTION bitcoinde_usr___query_and_store_rates()
RETURNS VOID
AS $$
DECLARE
  v_timestamp               timestamptz;
  v_api_access_active       boolean;
  v_api_access_delay        numeric;
  v_api_access_max_retries  integer;
  v_retries                 integer := 0;
  v_tradepair               text;
  v_nonce                   text;
  v_http_response           jsonb;
  v_message_text            text;
  v_exception_detail        text;
  v_exception_hint          text;
BEGIN
  -- Get current timestamp for inserting all results into table and create a "nonce" for uniquely accessing the API:
  v_timestamp := now();
  v_nonce     := extract(epoch from statement_timestamp() )::bigint::text;
  -- Get the delay (seconds) between accessing the API & if the API access is active:
  SELECT cfg_value::numeric INTO v_api_access_delay       FROM crypto_rates_collector.t_config WHERE cfg_key = 'api_access_delay';
  SELECT cfg_value::integer INTO v_api_access_max_retries FROM crypto_rates_collector.t_config WHERE cfg_key = 'api_access_max_retries';
  SELECT cfg_value::boolean INTO v_api_access_active      FROM crypto_rates_collector.t_config WHERE cfg_key = 'bitcoinde_api_access_active';

  FOR v_tradepair in ( SELECT cfg_value FROM crypto_rates_collector.t_config WHERE cfg_key = 'bitcoinde_tradepair' AND cfg_value != '' ORDER BY cfg_value ASC ) LOOP
    -- reset number of retries and http response for each tradepair:
    v_retries       := 0;
    v_http_response := NULL;

    -- try to get a response from the API until max_retries has been reached:
    WHILE ( (v_http_response IS NULL) AND (v_api_access_active IS TRUE) AND (v_retries <= v_api_access_max_retries) ) LOOP
      v_retries       := v_retries + 1;
      IF (v_retries > 1) THEN
        PERFORM crypto_rates_collector.insert_log_msg('WARN', '[bitcoinde_usr___query_and_store_rates(), "' || v_tradepair || '"] - API returned NULL, retry #' || v_retries || '.');
      END IF;

      v_http_response := crypto_rates_collector.bitcoinde_api___rates(v_nonce, v_tradepair);

      -- increase the nonce by 1 in order to create new nonce for the next loop iteration (which needs to be higher than
      -- the nonce used for the previous request (https://www.bitcoin.de/de/api/tapi/v2/docu#scrollNav-1-3):
      v_nonce         := (v_nonce::bigint + 1)::text;

      -- sleep for x seconds in order to prevent API hammering. If we need to retry more than once, increase the delay with each retry:
      PERFORM pg_sleep(v_api_access_delay * v_retries);
    END LOOP;

    IF v_http_response IS NOT NULL THEN
      IF (v_retries > 1) THEN
        PERFORM crypto_rates_collector.insert_log_msg('INFO', '[bitcoinde_usr___query_and_store_rates(), "' || v_tradepair || '"] - API returned a result after ' || v_retries || ' retries.');
      END IF;
      INSERT INTO crypto_rates_collector.t_bitcoinde_rates (
        timestamp_when,
        trade_pair,
        http_response
      )
      VALUES (
        v_timestamp,
        v_tradepair,
        v_http_response
      );
    ELSIF ( (v_http_response IS NULL) AND (v_api_access_active IS TRUE) ) THEN
      PERFORM crypto_rates_collector.insert_log_msg('ERROR', '[bitcoinde_usr___query_and_store_rates(), "' || v_tradepair || '"] - HTTP response from "bitcoinde_api___rates()" was still NULL after ' || v_retries || ' retries. Quitting for now.');
    ELSE
      PERFORM crypto_rates_collector.insert_log_msg('WARN', '[bitcoinde_usr___query_and_store_rates(), "' || v_tradepair || '"] - HTTP response from "bitcoinde_api___rates()" is NULL (ok, since API access is deactivated).');
    END IF;

  END LOOP;
EXCEPTION
  WHEN OTHERS THEN
  GET STACKED DIAGNOSTICS
    v_message_text     := MESSAGE_TEXT,
    v_exception_detail := PG_EXCEPTION_DETAIL,
    v_exception_hint   := PG_EXCEPTION_HINT;
    PERFORM crypto_rates_collector.insert_log_msg('ERROR',
                                                  '[bitcoinde_usr___query_and_store_rates()] - Exception! ' ||
                                                  'Message: "'|| v_message_text ||
                                                  '", Detail: "' || v_exception_detail ||
                                                  '", Hint: "' || v_exception_hint || '".'
                                                 );
END;
$$ LANGUAGE plpgsql;

SET search_path = crypto_rates_collector,public
;
COMMIT
;
-- Set the search path to the schema which we want to deploy all functionality in (don't include "public"
-- or we may end up there by accident):
SET search_path = crypto_rates_collector
;
CREATE OR REPLACE FUNCTION bitstamp_api___ticker_hour(
  p_tradepair          text
)
RETURNS jsonb
AS $$
DECLARE
  v_base_uri            text;
  v_full_uri            text;
  v_http_response       jsonb;
  v_api_access_active   boolean;
  v_message_text        text;
  v_exception_detail    text;
  v_exception_hint      text;
BEGIN
  -- Prepare all needed parameters for the API calls:
  SELECT cfg_value          INTO v_base_uri           FROM crypto_rates_collector.t_config WHERE cfg_key = 'bitstamp_api_uri';
  SELECT cfg_value::boolean INTO v_api_access_active  FROM crypto_rates_collector.t_config WHERE cfg_key = 'bitstamp_api_access_active';
  -- Prepare the endpoint URI for getting current rates:
  v_full_uri := v_base_uri || '/ticker_hour/' || p_tradepair;

  -- Set CURL connection and request timeout to 20s each:
  PERFORM http_set_curlopt('CURLOPT_CONNECTTIMEOUT', '20L');
  PERFORM http_set_curlopt('CURLOPT_TIMEOUT', '20L');
  PERFORM http_set_curlopt('CURLOPT_TCP_KEEPALIVE', '1L');
  PERFORM http_set_curlopt('CURLOPT_TCP_KEEPIDLE', '3L');

  IF v_api_access_active IS TRUE THEN
    -- Prepare the HTTP request, encode/encrpyt the request payload and query the api now:
    SELECT content INTO v_http_response FROM http_get(v_full_uri);
  ELSE
    PERFORM crypto_rates_collector.insert_log_msg('INFO', '[bitstamp_api___ticker_hour("' || p_tradepair || '")] - API access to Bitstamp is deactivated in T_CONFIG ("bitstamp_api_access_active").');
  END IF;

  RETURN v_http_response;
EXCEPTION
  WHEN OTHERS THEN
  GET STACKED DIAGNOSTICS
    v_message_text     := MESSAGE_TEXT,
    v_exception_detail := PG_EXCEPTION_DETAIL,
    v_exception_hint   := PG_EXCEPTION_HINT;
    PERFORM crypto_rates_collector.insert_log_msg('ERROR',
                                                  '[bitstamp_api___ticker_hour()] - Exception! ' ||
                                                  'Message: "'|| v_message_text ||
                                                  '", Detail: "' || v_exception_detail ||
                                                  '", Hint: "' || v_exception_hint || '".'
                                                 );
    RETURN null;
END;
$$ LANGUAGE plpgsql;

SET search_path = crypto_rates_collector,public
;
COMMIT
;
-- Set the search path to the schema which we want to deploy all functionality in (don't include "public"
-- or we may end up there by accident):
SET search_path = crypto_rates_collector
;
CREATE OR REPLACE FUNCTION bitstamp_usr___query_and_store_prices()
RETURNS VOID
AS $$
DECLARE
  v_timestamp               timestamptz;
  v_api_access_active       boolean;
  v_api_access_delay        numeric;
  v_api_access_max_retries  integer;
  v_retries                 integer := 0;
  v_tradepair               text;
  v_http_response           jsonb;
  v_message_text            text;
  v_exception_detail        text;
  v_exception_hint          text;
BEGIN
  -- Get current timestamp for inserting all results into table:
  v_timestamp := now();
  -- Get the delay (seconds) between accessing the API & if the API access is active:
  SELECT cfg_value::numeric INTO v_api_access_delay       FROM crypto_rates_collector.t_config WHERE cfg_key = 'api_access_delay';
  SELECT cfg_value::integer INTO v_api_access_max_retries FROM crypto_rates_collector.t_config WHERE cfg_key = 'api_access_max_retries';
  SELECT cfg_value::boolean INTO v_api_access_active      FROM crypto_rates_collector.t_config WHERE cfg_key = 'bitstamp_api_access_active';

  FOR v_tradepair in ( SELECT cfg_value FROM crypto_rates_collector.t_config WHERE cfg_key = 'bitstamp_tradepair' AND cfg_value != '' ORDER BY cfg_value ASC ) LOOP
    -- reset number of retries and http response for each tradepair:
    v_retries       := 0;
    v_http_response := NULL;

    -- try to get a response from the API until max_retries has been reached:
    WHILE ( (v_http_response IS NULL) AND (v_api_access_active IS TRUE) AND (v_retries <= v_api_access_max_retries) ) LOOP
      v_retries       := v_retries + 1;
      IF (v_retries > 1) THEN
        PERFORM crypto_rates_collector.insert_log_msg('WARN', '[bitstamp_usr___query_and_store_prices(), "' || v_tradepair || '"] - API returned NULL, retry #' || v_retries || '.');
      END IF;

      v_http_response := crypto_rates_collector.bitstamp_api___ticker_hour(v_tradepair);

      -- sleep for x seconds in order to prevent API hammering. If we need to retry more than once, increase the delay with each retry:
      PERFORM pg_sleep(v_api_access_delay * v_retries);
    END LOOP;

    IF v_http_response IS NOT NULL THEN
      IF (v_retries > 1) THEN
        PERFORM crypto_rates_collector.insert_log_msg('INFO', '[bitstamp_usr___query_and_store_prices(), "' || v_tradepair || '"] - API returned a result after ' || v_retries || ' retries.');
      END IF;
      INSERT INTO crypto_rates_collector.t_bitstamp_rates (
        timestamp_when,
        trade_pair,
        http_response
      )
      VALUES (
        v_timestamp,
        v_tradepair,
        v_http_response
      );
    ELSIF ( (v_http_response IS NULL) AND (v_api_access_active IS TRUE) ) THEN
      PERFORM crypto_rates_collector.insert_log_msg('ERROR', '[bitstamp_usr___query_and_store_prices(), "' || v_tradepair || '"] - HTTP response from "bitcoinde_api___rates()" was still NULL after ' || v_retries || ' retries. Quitting for now.');
    ELSE
      PERFORM crypto_rates_collector.insert_log_msg('WARN', '[bitstamp_usr___query_and_store_prices(), "' || v_tradepair || '"] - HTTP response from "bitcoinde_api___rates()" is NULL (ok, since API access is deactivated).');
    END IF;

  END LOOP;
EXCEPTION
  WHEN OTHERS THEN
  GET STACKED DIAGNOSTICS
    v_message_text     := MESSAGE_TEXT,
    v_exception_detail := PG_EXCEPTION_DETAIL,
    v_exception_hint   := PG_EXCEPTION_HINT;
    PERFORM crypto_rates_collector.insert_log_msg('ERROR',
                                                  '[bitstamp_usr___query_and_store_prices()] - Exception! ' ||
                                                  'Message: "'|| v_message_text ||
                                                  '", Detail: "' || v_exception_detail ||
                                                  '", Hint: "' || v_exception_hint || '".'
                                                 );
END;
$$ LANGUAGE plpgsql;

SET search_path = crypto_rates_collector,public
;
COMMIT
;
-- Set the search path to the schema which we want to deploy all functionality in (don't include "public"
-- or we may end up there by accident):
SET search_path = crypto_rates_collector
;
CREATE OR REPLACE FUNCTION cryptopia_api___getmarket(
  p_tradepair          text
)
RETURNS jsonb
AS $$
DECLARE
  v_base_uri            text;
  v_full_uri            text;
  v_http_response       jsonb;
  v_api_access_active   boolean;
  v_message_text        text;
  v_exception_detail    text;
  v_exception_hint      text;
BEGIN
  -- Prepare all needed parameters for the API calls:
  SELECT cfg_value          INTO v_base_uri           FROM crypto_rates_collector.t_config WHERE cfg_key = 'cryptopia_api_uri';
  SELECT cfg_value::boolean INTO v_api_access_active  FROM crypto_rates_collector.t_config WHERE cfg_key = 'cryptopia_api_access_active';
  -- Prepare the endpoint URI for getting current rates ('.../1' => "get Market rate from last hour only"):
  v_full_uri := v_base_uri || '/GetMarket/' || p_tradepair || '/1';

  -- Set CURL connection and request timeout to 20s each:
  PERFORM http_set_curlopt('CURLOPT_CONNECTTIMEOUT', '20L');
  PERFORM http_set_curlopt('CURLOPT_TIMEOUT', '20L');
  PERFORM http_set_curlopt('CURLOPT_TCP_KEEPALIVE', '1L');
  PERFORM http_set_curlopt('CURLOPT_TCP_KEEPIDLE', '3L');

  IF v_api_access_active IS TRUE THEN
    -- Prepare the HTTP request, encode/encrpyt the request payload and query the api now:
    SELECT content INTO v_http_response FROM http_get(v_full_uri);
  ELSE
    PERFORM crypto_rates_collector.insert_log_msg('INFO', '[cryptopia_api___getmarket("' || p_tradepair || '")] - API access to Binance is deactivated in T_CONFIG ("binance_api_access_active").');
  END IF;

  RETURN v_http_response;
EXCEPTION
  WHEN OTHERS THEN
  GET STACKED DIAGNOSTICS
    v_message_text     := MESSAGE_TEXT,
    v_exception_detail := PG_EXCEPTION_DETAIL,
    v_exception_hint   := PG_EXCEPTION_HINT;
    PERFORM crypto_rates_collector.insert_log_msg('ERROR',
                                                  '[cryptopia_api___getmarket()] - Exception! ' ||
                                                  'Message: "'|| v_message_text ||
                                                  '", Detail: "' || v_exception_detail ||
                                                  '", Hint: "' || v_exception_hint || '".'
                                                 );
    RETURN null;
END;
$$ LANGUAGE plpgsql;

SET search_path = crypto_rates_collector,public
;
COMMIT
;
-- Set the search path to the schema which we want to deploy all functionality in (don't include "public"
-- or we may end up there by accident):
SET search_path = crypto_rates_collector
;
CREATE OR REPLACE FUNCTION cryptopia_usr___query_and_store_market()
RETURNS VOID
AS $$
DECLARE
  v_timestamp               timestamptz;
  v_api_access_active       boolean;
  v_api_access_delay        numeric;
  v_api_access_max_retries  integer;
  v_retries                 integer := 0;
  v_tradepair               text;
  v_http_response           jsonb;
  v_message_text            text;
  v_exception_detail        text;
  v_exception_hint          text;
BEGIN
  -- Get current timestamp for inserting all results into table:
  v_timestamp := now();
  -- Get the delay (seconds) between accessing the API & if the API access is active:
  SELECT cfg_value::numeric INTO v_api_access_delay       FROM crypto_rates_collector.t_config WHERE cfg_key = 'api_access_delay';
  SELECT cfg_value::integer INTO v_api_access_max_retries FROM crypto_rates_collector.t_config WHERE cfg_key = 'api_access_max_retries';
  SELECT cfg_value::boolean INTO v_api_access_active      FROM crypto_rates_collector.t_config WHERE cfg_key = 'cryptopia_api_access_active';

  FOR v_tradepair in ( SELECT cfg_value FROM crypto_rates_collector.t_config WHERE cfg_key = 'cryptopia_tradepair' AND cfg_value != '' ORDER BY cfg_value ASC ) LOOP
    -- reset number of retries and http response for each tradepair:
    v_retries       := 0;
    v_http_response := NULL;

    -- try to get a response from the API until max_retries has been reached:
    WHILE ( (v_http_response IS NULL) AND (v_api_access_active IS TRUE) AND (v_retries <= v_api_access_max_retries) ) LOOP
      v_retries       := v_retries + 1;
      IF (v_retries > 1) THEN
        PERFORM crypto_rates_collector.insert_log_msg('WARN', '[cryptopia_usr___query_and_store_market(), "' || v_tradepair || '"] - API returned NULL, retry #' || v_retries || '.');
      END IF;

      v_http_response := crypto_rates_collector.cryptopia_api___getmarket(v_tradepair);

      -- sleep for x seconds in order to prevent API hammering. If we need to retry more than once, increase the delay with each retry:
      PERFORM pg_sleep(v_api_access_delay * v_retries);
    END LOOP;

    IF v_http_response IS NOT NULL THEN
      IF (v_retries > 1) THEN
        PERFORM crypto_rates_collector.insert_log_msg('INFO', '[cryptopia_usr___query_and_store_market(), "' || v_tradepair || '"] - API returned a result after ' || v_retries || ' retries.');
      END IF;
      INSERT INTO crypto_rates_collector.t_cryptopia_rates (
        timestamp_when,
        trade_pair,
        http_response
      )
      VALUES (
        v_timestamp,
        v_tradepair,
        v_http_response
      );
    ELSIF ( (v_http_response IS NULL) AND (v_api_access_active IS TRUE) ) THEN
      PERFORM crypto_rates_collector.insert_log_msg('ERROR', '[cryptopia_usr___query_and_store_market(), "' || v_tradepair || '"] - HTTP response from "bitcoinde_api___rates()" was still NULL after ' || v_retries || ' retries. Quitting for now.');
    ELSE
      PERFORM crypto_rates_collector.insert_log_msg('WARN', '[cryptopia_usr___query_and_store_market(), "' || v_tradepair || '"] - HTTP response from "bitcoinde_api___rates()" is NULL (ok, since API access is deactivated).');
    END IF;

  END LOOP;
EXCEPTION
  WHEN OTHERS THEN
  GET STACKED DIAGNOSTICS
    v_message_text     := MESSAGE_TEXT,
    v_exception_detail := PG_EXCEPTION_DETAIL,
    v_exception_hint   := PG_EXCEPTION_HINT;
    PERFORM crypto_rates_collector.insert_log_msg('ERROR',
                                                  '[cryptopia_usr___query_and_store_market()] - Exception! ' ||
                                                  'Message: "'|| v_message_text ||
                                                  '", Detail: "' || v_exception_detail ||
                                                  '", Hint: "' || v_exception_hint || '".'
                                                 );
END;
$$ LANGUAGE plpgsql;

SET search_path = crypto_rates_collector,public
;
COMMIT
;
-- Set the search path to the schema which we want to deploy all functionality in (don't include "public"
-- or we may end up there by accident):
SET search_path = crypto_rates_collector
;
DROP VIEW IF EXISTS v_combined_rates
;
CREATE OR REPLACE VIEW v_combined_rates
AS
WITH combined_exchanges AS (
  SELECT
    'bitcoinde' AS exchange,
    btcde.timestamp_when,
    btcde.trade_pair,
    btcde.rate_weighted AS price
  FROM
    crypto_rates_collector.t_bitcoinde_rates btcde

  UNION ALL

  SELECT
    'binance' AS exchange,
    binc.timestamp_when,
    binc.trade_pair,
    binc.price AS price
  FROM
    crypto_rates_collector.t_binance_rates binc

  UNION ALL

  SELECT
    'cryptopia' AS exchange,
    crpt.timestamp_when,
    crpt.trade_pair,
    crpt.lastprice AS price
  FROM
    crypto_rates_collector.t_cryptopia_rates crpt

  UNION ALL

  SELECT
    'bitstamp' AS exchange,
    bitst.timestamp_when,
    bitst.trade_pair,
    bitst.last_price AS price
  FROM
    crypto_rates_collector.t_bitstamp_rates bitst
)
SELECT
  ce.exchange,
  ce.timestamp_when,
  -- round the original "fuzzy and fully detailed" timestamp to the nearest 15 minutes:
  date_trunc('hour', ce.timestamp_when) + INTERVAL '15 min' * ROUND(date_part('minute', ce.timestamp_when) / 15.0) as timestamp_when_normalized,
  ce.trade_pair,
  ce.price
FROM
  combined_exchanges ce
;

COMMENT ON VIEW crypto_rates_collector.v_combined_rates IS 'This view pulls together rates / tradepair from all exchange-specific tables and normalized / rounds the timestamp to the nearest 15 minutes.'


SET search_path = crypto_rates_collector,public
;
COMMIT
;
-- Set the search path to the schema which we want to deploy all functionality in (don't include "public"
-- or we may end up there by accident):
SET search_path = crypto_rates_collector
;
DROP VIEW IF EXISTS v_samples_per_exchange_and_time
;
CREATE OR REPLACE VIEW v_samples_per_exchange_and_time
AS
select
  timestamp_when_normalized,
  exchange,
  count(*) as num_trade_pairs
from
  crypto_rates_collector.v_combined_rates
group by
  timestamp_when_normalized,
  exchange
;

COMMENT ON VIEW crypto_rates_collector.v_samples_per_exchange_and_time IS 'This view aggregates "statistics" on how many rows/trade-pairs per exchange and timestamp were collected.'


SET search_path = crypto_rates_collector,public
;
COMMIT
;
--select * from cron.job;
--select jobid from cron.job where command = 'DO $$ BEGIN PERFORM crypto_rates_collector.binance_usr___query_and_store_prices(); END $$;' and schedule = '*/15 * * * *';
--SELECT cron.unschedule( (select jobid from cron.job where command = 'DO $$ BEGIN PERFORM crypto_rates_collector.binance_usr___query_and_store_prices(); END $$;' and schedule = '*/15 * * * *') );

SELECT cron.schedule('*/15 * * * *', 'DO $$ BEGIN PERFORM crypto_rates_collector.binance_usr___query_and_store_prices(); END $$;')
;
COMMIT
;
--select * from cron.job;
--select jobid from cron.job where command = 'DO $$ BEGIN PERFORM crypto_rates_collector.bitcoinde_usr___query_and_store_rates(); END $$;' and schedule = '*/15 * * * *';
--SELECT cron.unschedule( ( select jobid from cron.job where command = 'DO $$ BEGIN PERFORM crypto_rates_collector.bitcoinde_usr___query_and_store_rates(); END $$;' and schedule = '*/15 * * * *' ) );

SELECT cron.schedule('*/15 * * * *', 'DO $$ BEGIN PERFORM crypto_rates_collector.bitcoinde_usr___query_and_store_rates(); END $$;')
;
COMMIT
;
--select * from cron.job;
--select jobid from cron.job where command = 'DO $$ BEGIN PERFORM crypto_rates_collector.cryptopia_usr___query_and_store_market(); END $$;' and schedule = '*/15 * * * *';
--SELECT cron.unschedule( (select jobid from cron.job where command = 'DO $$ BEGIN PERFORM crypto_rates_collector.cryptopia_usr___query_and_store_market(); END $$;' and schedule = '*/15 * * * *') );

SELECT cron.schedule('*/15 * * * *', 'DO $$ BEGIN PERFORM crypto_rates_collector.cryptopia_usr___query_and_store_market(); END $$;')
;
COMMIT
;
--select * from cron.job;
--select jobid from cron.job where command = 'DO $$ BEGIN PERFORM crypto_rates_collector.bitstamp_usr___query_and_store_prices(); END $$;' and schedule = '*/15 * * * *';
--SELECT cron.unschedule( (select jobid from cron.job where command = 'DO $$ BEGIN PERFORM crypto_rates_collector.bitstamp_usr___query_and_store_prices(); END $$;' and schedule = '*/15 * * * *') );

SELECT cron.schedule('*/15 * * * *', 'DO $$ BEGIN PERFORM crypto_rates_collector.bitstamp_usr___query_and_store_prices(); END $$;')
;
COMMIT
;
