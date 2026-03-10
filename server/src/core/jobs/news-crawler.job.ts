import cron from "node-cron";
import { NewsService } from "../../modules/news/news.service";

let running = true;

export async function start_crawler() {
  if (!running) return;

  const newsService = new NewsService();
  console.log("Kisan crawler started:", new Date().toISOString());

  cron.schedule("0 */12 * * *", async () => {
    try {
      const inserted = await newsService.crawl_news();
      console.log("Crawling finished yaaay. Articles inserted:", inserted);
    } catch (err) {
      console.error("Crawler failed fuck:", err);
    }
  });
}

export async function run_crawler_once() {
  console.log("Crawler started...");
  const newsService = new NewsService();
  const inserted = await newsService.crawl_news();
  console.log("Inserted:", inserted);
}
