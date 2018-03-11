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
