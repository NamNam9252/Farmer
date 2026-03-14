import { Router } from "express";
import authRoutes from "./modules/auth/auth.routes.js";
import diseaseRoutes from "./modules/disease/disease.routes.js";
import marketRoutes from "./modules/market/market.routes.js";
import usersRoutes from "./modules/users/users.routes.js";
import advisoryRoutes from "./modules/advisory/advisory.routes.js";
import weatherRoutes from "./modules/weather/weather.routes.js";
import cropRecommendationRoutes from "./modules/crop-recommendation/crop-recommendation.routes.js";
import communityRoutes from "./modules/community/community.routes.js";
import notificationRoutes from "./modules/notifications/notification.routes.js";
import marketplaceNewRoutes from "./modules/marketplace-new/marketplace-new.routes.js";
import newsRoutes from "./modules/news/news.route.js";
import schemesRoutes from "./modules/news/schemes.route.js";
import agentRoutes from "./modules/agent/agent.routes.js";
import rentalRoutes from "./modules/rental/rental.route.js";
import laborRoutes from "./modules/labor/labor.routes.js";
import expertVisitRoutes from "./modules/expert-visit/expert-visit.routes.js";

const router = Router();

// Mount all feature routes here
router.use("/auth", authRoutes);
router.use("/users", usersRoutes); // Changed from userRoutes to usersRoutes to match import
router.use("/disease", diseaseRoutes);
router.use("/market", marketRoutes);
router.use("/advisory", advisoryRoutes);
router.use("/weather", weatherRoutes);
router.use("/crop-recommendation", cropRecommendationRoutes);
router.use("/community", communityRoutes);
router.use("/notifications", notificationRoutes);
router.use("/marketplace", marketplaceNewRoutes);
router.use("/news", newsRoutes);
router.use("/schemes", schemesRoutes);
router.use("/agent", agentRoutes);
router.use("/rental", rentalRoutes);
router.use("/labor", laborRoutes);
router.use("/expert-visit", expertVisitRoutes);

export default router;
