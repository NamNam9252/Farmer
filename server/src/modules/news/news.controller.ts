import { NewsService } from "./news.service";

export class NewsController
{
    private newsService: NewsService;
    
    constructor () {
        this.newsService = new NewsService();
    }
}