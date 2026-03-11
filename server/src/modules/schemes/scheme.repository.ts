import { Prisma, PrismaClient, SchemeCategory } from "@prisma/client";
import { CrawledArticle } from "../../core/types";

const prisma = new PrismaClient();

export class SchemeRepository {
  static async get_recent_schemes() {
    return prisma.governmentScheme.findMany({
      where: {
        isDeleted: false,
      },
      select: {
        title: true,
        officialLink: true,
      },
    });
  }

  static async insert_many(schemes: CrawledArticle[]) {
    if (schemes.length === 0) return 0;

    const result = await prisma.governmentScheme.createMany({
      data: schemes.map((s) => ({
        title: s.title,
        description: s.content,
        officialLink: s.source_url,
        isNational: true /* Obviously poo poo logic but fuck it */,
        schemeCategory: SchemeCategory.OTHER,
        createdAt: new Date(),
        updatedAt: new Date(),
      })),
    });
    return result.count;
  }
}
