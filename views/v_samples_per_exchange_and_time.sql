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
