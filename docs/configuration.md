# Configuration table and parameters
The configuration, and thus also the "activation" of accessing a specific exchange API, is done in a single table name `CRYPTO_RATES_COLLECTOR.T_CONFIG`. This table holds information on each exchange known to the schema, including such parameters as the API's base URI, trade pairs to collect and, in the case of Bitcoin.de, the API key and secret needed to adress this non-public API.

The trade pairs (and the number of trade pairs per exchange) are freely configurable. If you want to collect data for a trade pair not yet present in `CRYPTO_RATES_COLLECTOR.T_CONFIG` you simply need to insert a new row following the pattern of the exchange you want to collect it from.

**Note:** if you have configured a huge number of trade pairs and/or retries per exchange, expect a certain amount of "drift" between the first and the last trade pair queried from an exchange. Though exchanges are indeed queried in parallel by individual regular "jobs", multiple trade pairs for an exchange are queried in a sequential manner (one after the other, with a configurable delay between each trade pair). For all those with high frequency stuff in their mind: This is the wrong place for that.

![configuration table](/docs/images/t_config.png)

The are the following config item classes ("%" is used as a wildcard in the following and denotes one of the known / implemented exchanges):
* **schema_version** (no need to change / adapt)
  * This parameter documents the currently deployed schema version - it's meant to help when upgrading in the future, but there are no plans on this yet, whatsoever.
* **api_access_delay** (marked in blue color in the above screenshot)
  * Delay in seconds between retries and trade pairs in accessing the API of an individual exchange.
* **api_access_max_retries** (marked in blue color in the above screenshot)
  * Maximum number of retries to get a valid answer (= "http response is not null") from an exchange API.
* **%_api_access_active** (marked in red color in the above screenshot)
  * Can be "true" or "false". Only if "true" the API of an exchange will be accessed.
* **%_api_uri** (no need to change / adapt)
  * The base URI of an exchange's API.
* **%_tradepair** (marked in green color in the above screenshot, can / should be changed, extended, adapted based on your needs)
  * The identificator of an exchange's trade pair. This always is exchange-specific, so the pair "Ethereum vs. Bitcoin" may be "ethbtc" or "ETH_BTC", depending on the exchange.

The wildcard "%" would be exchanged in the table `CRYPTO_RATES_COLLECTOR.T_CONFIG` with the corresponding exchange prefix, of which currently those four are valid:
* **binance**
* **bitcoinde**
* **bitstamp**
* **cryptopia**


## How to configure the bitcoin.de API access (API key & API secret)
Only use a dedicated API key with read-only access to the "rates" endpoint exclusively. You should **never** use a key / secret which also allows to make trades and move BTC around. For potential automated trading always use a separate API key, possibly even multiple ones per use case.

You need to have a bitcoin.de account and create an API key, following this exchange's documentation. Then simply input the API key and secret into the table T_CONFIG into the appropriate rows.