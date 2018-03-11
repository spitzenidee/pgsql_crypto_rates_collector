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
