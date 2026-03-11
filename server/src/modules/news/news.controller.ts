import { Request, Response, NextFunction } from "express";
import { NewsService } from "./news.service.js";

const newsService = new NewsService();

export const getAllNews = async (req: Request, res: Response, next: NextFunction) => {
    try {
        const news = await newsService.getAllNews();
        res.status(200).json({
            success: true,
            message: "News fetched successfully",
            data: news,
        });
    } catch (error) {
        next(error);
    }
};

export class NewsController {
    private newsService: NewsService;

    constructor() {
        this.newsService = new NewsService();
    }
}