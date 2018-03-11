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
