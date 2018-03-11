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
