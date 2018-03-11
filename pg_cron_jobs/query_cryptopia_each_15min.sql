--select * from cron.job;
--select jobid from cron.job where command = 'DO $$ BEGIN PERFORM crypto_rates_collector.cryptopia_usr___query_and_store_market(); END $$;' and schedule = '*/15 * * * *';
--SELECT cron.unschedule( (select jobid from cron.job where command = 'DO $$ BEGIN PERFORM crypto_rates_collector.cryptopia_usr___query_and_store_market(); END $$;' and schedule = '*/15 * * * *') );

SELECT cron.schedule('*/15 * * * *', 'DO $$ BEGIN PERFORM crypto_rates_collector.cryptopia_usr___query_and_store_market(); END $$;')
;
COMMIT
;
