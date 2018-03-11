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
