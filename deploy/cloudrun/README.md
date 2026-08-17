# Nyaysahayak Cloud Run (API)

Service: `nyaysahayak` · Region: `europe-west1`

## Scale-to-zero + scheduled clustering

The API uses `min-instances=0` (cheap). Background jobs do **not** use an always-on worker.

- **Manual runs** (scam-trends scrape, classifier “Run now”): admin UI opens `POST …/process` so Cloud Run allocates CPU for that request only.
- **Scheduled clustering**: Cloud Scheduler wakes the sleeping service **every hour** via  
  `POST /api/cron/scam-classifier/tick` with header `X-Cron-Secret`.  
  The admin **Interval (hours)** setting decides whether a run is actually due
  (`last_run_at` + interval). Cheap no-op ticks when not due.

Required env on the service:

- `RUN_BACKGROUND_WORKER=0` (default; do not enable unless you pay for min-instances)
- `CRON_SECRET=<random>` (shared with the Scheduler job header)

Recommended flags:

- `--timeout=3600` (scrapes / clustering can exceed 5 minutes)
- `--memory=1Gi`
- `--min-instances=0` (keep)
- Do **not** require `--no-cpu-throttling` for this design
