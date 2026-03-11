import axios from "axios";
import * as cheerio from "cheerio";

import { CrawledArticle } from "../../../../core/types";

export class VikaspediaSource {
  public static readonly baseurl =
    "https://data.vikaspedia.in/api/public/content/page-content";

  public static async get_articles(): Promise<CrawledArticle[]> {
    const response = await axios.get(this.baseurl, {
      params: {
        ctx: "/schemesall/schemes-for-farmers",
        lgn: "en",
      },
    });

    const articles: CrawledArticle[] = [];
    const list = response.data.contentList;

    for (const item of list) {
      const scheme = await axios.get(this.baseurl, {
        params: {
          ctx: item.context_path,
          lgn: "en",
        },
      });
      const page = scheme.data;
      const content = this.html_to_text(page.content ?? "");
      articles.push({
        title: item.title.trim(),
        summary:
          item.summery ?? undefined /* yes this is a typo by the api devs */,
        content: content,
        source: "Vikaspedia",
        source_url: `https://schemes.vikaspedia.in/viewcontent${item.context_path}?lgn=en`,
        published_at: new Date(item.updated_at ?? item.create_at),
      });
    }

    return articles;
  }

  private static html_to_text(html: string): string {
    const $ = cheerio.load(html);
    const paragraphs = $("p, li")
      .map((_, el) => $(el).text().trim())
      .get()
      .filter(Boolean);
    return paragraphs.join("\n\n");
  }
}
