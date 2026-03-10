import { run_crawler_once } from "./core/jobs/news-crawler.job.js";

async function main() {
  await run_crawler_once();
}

main();
