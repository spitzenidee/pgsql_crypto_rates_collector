# How to deploy
Execute the script "deploy_all.sql" either via commandline with `pgsql` or via your favorite DB admin / development tool, e.g. SQL Workbench (http://www.sql-workbench.net/), DataGrip (https://www.jetbrains.com/datagrip/), etc, while being connected as a superuser (e.g. "postgres" by default).

For deployment you may use one of the following docker containers, including the necessary extensions:
* https://hub.docker.com/r/spitzenidee/postgresql_base/
* Optional, since TimescaleDB is not necessary yet: https://hub.docker.com/r/spitzenidee/postgresql_timescaledb/

Deployment will create a new schema named `CRYPTO_RATES_COLLECTOR` in the database of your choice and create all necessary assets automatically. Collection of cryptocurrency rates will only start once you manually set the corresponding config variables in the table `CRYPTO_RATES_COLLECTOR.T_CONFIG` to `TRUE` (see next section):

![crypto_rates_collector schema overview](docs/images/schema_overview.png)