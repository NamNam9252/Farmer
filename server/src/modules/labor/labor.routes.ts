import { Router } from "express";
import { LaborController } from "./labor.controller.js";
import { requireAuth } from "../../middleware/auth.middleware.js";

const router = Router();
const controller = new LaborController();

router.use(requireAuth);

router.get("/profile", controller.getProfile);
router.post("/profile", controller.createProfile);
router.put("/profile", controller.updateProfile);
router.get("/available", controller.listAvailable);
router.post("/:laborId/hire", controller.hireLabor);
router.post("/employment/:id/terminate", controller.terminateEmployment);
router.get("/farmer/labor", controller.farmerLabor);

export default router;
