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
