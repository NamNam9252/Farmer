import axios from "axios";
import * as cheerio from "cheerio";

import { CrawledArticle } from "../../../../core/types";

export class KrishiJagaranSource {
  public static readonly url = "https://krishijagran.com/feeds";

  public static async get_articles(): Promise<CrawledArticle[]> {
    const response = await axios.get(this.url);
    const $ = cheerio.load(response.data);

    const metadata: Omit<CrawledArticle, "content">[] = [];

    $(".n-f-item").each((_, el) => {
      const title = $(el).find("h2 a").text().trim();
      const relative_url = $(el).find("h2 a").attr("href");

      const src_url = relative_url
        ? `https://krishijagran.com${relative_url}`
        : null;

      const image_url = $(el).find("img").attr("data-src");

      const date_text = $(el)
        .find("small")
        .text()
        .replace("Updated:", "")
        .trim();

      const published_at = date_text ? new Date(date_text) : null;

      if (!title || !src_url || !published_at) return;

      metadata.push({
        title,
        summary: undefined,
        source: "Krishi Jagran",
        source_url: src_url,
        image_url,
        published_at,
      });
    });

    const articles: CrawledArticle[] = await Promise.all(
      metadata.map(async (article) => ({
        ...article,
        content: await this.get_article_content(article.source_url),
      })),
    );

    return articles;
  }

  private static async get_article_content(url: string): Promise<string> {
    const response = await axios.get(url, {
      headers: { "User-Agent": "Mozilla/5.0" },
    });

    const $ = cheerio.load(response.data);

    const paragraphs = $("article p")
      .map((_, el) => $(el).text().trim())
      .get()
      .filter(Boolean);

    return paragraphs.join("\n\n");
  }
}
