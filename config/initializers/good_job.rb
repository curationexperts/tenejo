GoodJob.cleanup_preserved_jobs # Will keep 1 day of job records by default.
GoodJob.cleanup_preserved_jobs(older_than: 7.days) # It also takes custom arguments.

