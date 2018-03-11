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
