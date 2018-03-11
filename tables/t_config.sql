-- Set the search path to the schema which we want to deploy all functionality in (don't include "public"
-- or we may end up there by accident):
SET search_path = crypto_rates_collector
;
DROP TABLE IF EXISTS t_config
;
CREATE TABLE IF NOT EXISTS t_config (
  cfg_key   text NOT NULL,
  cfg_value text NULL,
  comment   text NULL,
  UNIQUE (cfg_key, cfg_value)
);

COMMENT ON TABLE t_config             IS 'Holds all necessary config parameters for driving exchange API access via stored procedures';
COMMENT ON COLUMN t_config.cfg_key    IS 'The name/key of a configuration parameter';
COMMENT ON COLUMN t_config.cfg_value  IS 'The content/value of a configuration parameter';

-- Insert (default) data, with empty "cfg_value" where advised (API key and secret for example):
INSERT INTO t_config (cfg_key, cfg_value, comment) VALUES ('schema_version', '1', 'Indicates the version of schema "crypto_rates_collector" in case we need to update in the future (there is no strategy yet)');
INSERT INTO t_config (cfg_key, cfg_value, comment) VALUES ('api_access_delay', '3', 'Delay in seconds (e.g. "1", "2", "3.8") between accessing the same API in order to prevent API hammering and, consequently, IP blocking');
INSERT INTO t_config (cfg_key, cfg_value, comment) VALUES ('api_access_max_retries', '6', 'Maximum retries to get a tradepair from an exchange before giving up');

INSERT INTO t_config (cfg_key, cfg_value, comment) VALUES ('binance_api_uri', 'https://api.binance.com/api/v3', 'URL of the Binance API');
INSERT INTO t_config (cfg_key, cfg_value, comment) VALUES ('binance_api_access_active', 'false', 'May be "true" or "false". Only while "true" rates will be collected from this URI/API');

INSERT INTO t_config (cfg_key, cfg_value, comment) VALUES ('bitcoinde_api_key', '', 'API key for accessing the bitcoin.de API ("showRates" is sufficient at the moment)');
INSERT INTO t_config (cfg_key, cfg_value, comment) VALUES ('bitcoinde_api_secret', '', 'API secret for accessing the bitcoin.de API');
INSERT INTO t_config (cfg_key, cfg_value, comment) VALUES ('bitcoinde_api_uri', 'https://api.bitcoin.de/v2', 'URL of the bitcoin.de API');
INSERT INTO t_config (cfg_key, cfg_value, comment) VALUES ('bitcoinde_api_access_active', 'false', 'May be "true" or "false". Only while "true" rates will be collected from this URI/API');

INSERT INTO t_config (cfg_key, cfg_value, comment) VALUES ('bitstamp_api_uri', 'https://www.bitstamp.net/api/v2', 'URL of the Bitstamp API');
INSERT INTO t_config (cfg_key, cfg_value, comment) VALUES ('bitstamp_api_access_active', 'false', 'May be "true" or "false". Only while "true" rates will be collected from this URI/API');

INSERT INTO t_config (cfg_key, cfg_value, comment) VALUES ('cryptopia_api_uri', 'https://www.cryptopia.co.nz/api', 'URL of the Cryptopia API');
INSERT INTO t_config (cfg_key, cfg_value, comment) VALUES ('cryptopia_api_access_active', 'false', 'May be "true" or "false". Only while "true" rates will be collected from this URI/API');

INSERT INTO t_config (cfg_key, cfg_value, comment) VALUES ('binance_tradepair', 'ETHBTC', 'https://api.binance.com/api/v1/exchangeInfo');
INSERT INTO t_config (cfg_key, cfg_value, comment) VALUES ('binance_tradepair', 'LTCBTC', 'https://api.binance.com/api/v1/exchangeInfo');
INSERT INTO t_config (cfg_key, cfg_value, comment) VALUES ('binance_tradepair', 'XRPBTC', 'https://api.binance.com/api/v1/exchangeInfo');

INSERT INTO t_config (cfg_key, cfg_value, comment) VALUES ('bitcoinde_tradepair', 'btceur', '');
INSERT INTO t_config (cfg_key, cfg_value, comment) VALUES ('bitcoinde_tradepair', 'etheur', '');
INSERT INTO t_config (cfg_key, cfg_value, comment) VALUES ('bitcoinde_tradepair', 'bcheur', '');

INSERT INTO t_config (cfg_key, cfg_value, comment) VALUES ('bitstamp_tradepair', 'btceur', 'https://www.bitstamp.net/api/');
INSERT INTO t_config (cfg_key, cfg_value, comment) VALUES ('bitstamp_tradepair', 'btcusd', 'https://www.bitstamp.net/api/');
INSERT INTO t_config (cfg_key, cfg_value, comment) VALUES ('bitstamp_tradepair', 'eurusd', 'https://www.bitstamp.net/api/');

INSERT INTO t_config (cfg_key, cfg_value, comment) VALUES ('cryptopia_tradepair', 'ETH_BTC', 'https://www.cryptopia.co.nz/api/GetTradePairs');
INSERT INTO t_config (cfg_key, cfg_value, comment) VALUES ('cryptopia_tradepair', 'TRC_BTC', 'https://www.cryptopia.co.nz/api/GetTradePairs');
INSERT INTO t_config (cfg_key, cfg_value, comment) VALUES ('cryptopia_tradepair', 'PPC_BTC', 'https://www.cryptopia.co.nz/api/GetTradePairs');
INSERT INTO t_config (cfg_key, cfg_value, comment) VALUES ('cryptopia_tradepair', 'ADC_BTC', 'https://www.cryptopia.co.nz/api/GetTradePairs');
INSERT INTO t_config (cfg_key, cfg_value, comment) VALUES ('cryptopia_tradepair', 'ARC_BTC', 'https://www.cryptopia.co.nz/api/GetTradePairs');

SET search_path = crypto_rates_collector,public
;
COMMIT
;
