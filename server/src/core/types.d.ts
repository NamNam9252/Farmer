export interface CrawledArticle {
  title: string;
  summary?: string;
  content: string;
  source: string;
  source_url: string;
  image_url?: string;
  published_at: Date;
}
