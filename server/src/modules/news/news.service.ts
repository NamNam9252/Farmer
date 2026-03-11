import { dedup_article } from "../../core/utils/dedup.util";
import { KrishiJagaranSource } from "./crawler/sources/krishijagaran.source";
import { NewsRepository } from "./news.repository.js";

export class NewsService {
  async getAllNews() {
    return NewsRepository.get_recent_articles();
  }
  constructor() { }

  public async crawl_news() {
    const crawled = await KrishiJagaranSource.get_articles();
    const existing = await NewsRepository.get_recent_articles();
    const unique = dedup_article(crawled, existing);
    await NewsRepository.insert_many(unique);

    console.log("Fetched:", crawled.length);
    console.log("Existing:", existing.length);
    console.log("Unique:", unique.length);

    return unique.length;
  }
}
