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
