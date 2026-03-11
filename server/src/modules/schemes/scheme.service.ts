import { dedup_article } from "../../core/utils/dedup.util";
import { VikaspediaSource } from "./crawler/sources/vikaspedia.source";
import { SchemeRepository } from "./scheme.repository";

export class SchemeService {
  public async crawl_schemes() {
    const crawled = await VikaspediaSource.get_articles();
    const existingRaw = await SchemeRepository.get_recent_schemes();
    const existing = existingRaw.map((s) => ({
      title: s.title,
      sourceUrl: s.officialLink,
    }));
    const unique = dedup_article(crawled, existing);
    await SchemeRepository.insert_many(unique);
  }
}
