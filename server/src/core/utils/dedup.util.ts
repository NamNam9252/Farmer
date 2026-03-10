import { stringSimilarity } from "string-similarity-js";
import { CrawledArticle } from "../types";

export function normalize_title(title: string): string {
  return title
    .toLowerCase()
    .replace(/[^\w\s]/g, "")
    .replace(/\s+/g, " ")
    .trim();
}

export function dedup_article(
  incoming: CrawledArticle[],
  existing: { title: string; sourceUrl: string | null }[],
): CrawledArticle[] {
  return incoming.filter((article) => {
    const normalizedIncoming = normalize_title(article.title);
    for (const dbArticle of existing) {
      if (dbArticle.sourceUrl && article.source_url === dbArticle.sourceUrl)
        return false;
      const normalizedDb = normalize_title(dbArticle.title);
      const score = stringSimilarity(normalizedIncoming, normalizedDb);
      if (score > 0.65) return false;
    }
    return true;
  });
}
