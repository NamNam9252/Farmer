import { Router } from "express";
import { getAllNews } from "./news.controller.js";

const router = Router();

router.get("/", getAllNews);

export default router;
