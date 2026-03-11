import cron from "node-cron";

import { NewsService } from "../../modules/news/news.service";
import { SchemeService } from "../../modules/schemes/scheme.service";

let running = true;

export async function start_crawler() {
  if (!running) return;

  const newsService = new NewsService();
  const schemeService = new SchemeService();

  console.log("Crawler schedule started:", new Date().toISOString());

  cron.schedule("0 */12 * * *", async () => {
    console.log("Crawler execution:", new Date().toISOString());
    try {
      const newsInserted = await newsService.crawl_news();
      const schemeInserted = await schemeService.crawl_schemes();

      console.log("News inserted:", newsInserted);
      console.log("Schemes inserted:", schemeInserted);
    } catch (err) {
      console.error("Crawler failed fuck:", err);
    }
  });
}

export async function run_crawler_once() {
  const newsService = new NewsService();
  const schemeService = new SchemeService();

  const newsInserted = await newsService.crawl_news();
  const schemeInserted = await schemeService.crawl_schemes();

  console.log("News inserted:", newsInserted);
  console.log("Schemes inserted:", schemeInserted);
}
