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
      PERFORM crypto_rates_collector.insert_log_msg('ERROR', '[cryptopia_usr___query_and_store_market(), "' || v_tradepair || '"] - HTTP response from "cryptopia_api___getmarket()" was still NULL after ' || v_retries || ' retries. Quitting for now.');
    ELSE
      PERFORM crypto_rates_collector.insert_log_msg('WARN', '[cryptopia_usr___query_and_store_market(), "' || v_tradepair || '"] - HTTP response from "cryptopia_api___getmarket()" is NULL (ok, since API access is deactivated).');
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
