import { Router } from "express";
import { LaborController } from "./labor.controller.js";

const router = Router();
const controller = new LaborController();

router.post("/profile", controller.createProfile);
router.get("/available", controller.listAvailable);
router.post("/:laborId/hire", controller.hireLabor);
router.post("/employment/:id/terminate", controller.terminateEmployment);
router.get("/farmer/labor", controller.farmerLabor);

export default router;
