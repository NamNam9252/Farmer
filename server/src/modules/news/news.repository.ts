import { PrismaClient } from "@prisma/client";
import { CrawledArticle } from "../../core/types";
const prisma = new PrismaClient();

export class NewsRepository {
  constructor() {}

  static async get_recent_articles() {
    return prisma.newsArticle.findMany({
      where: {
        isDeleted: false,
      },
      orderBy: {
        createdAt: 'desc',
      },
      select: {
        id: true,
        title: true,
        content: true,
        source: true,
        sourceUrl: true,
        imageUrl: true,
        publishedAt: true,
        createdAt: true,
        isNational: true,
      },
    });
  }

  static async insert_many(articles: CrawledArticle[]) {
    if (articles.length === 0) return;

    return prisma.newsArticle.createMany({
      data: articles.map((a) => ({
        title: a.title,
        summary: a.summary,
        content: a.content,
        source: a.source,
        sourceUrl: a.source_url,
        imageUrl: a.image_url,
        publishedAt: a.published_at,
      })),
    });
  }
}
