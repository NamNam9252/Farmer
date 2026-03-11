import { Router } from "express";
import { getAllSchemes, getSchemeById } from "./schemes.controller.js";

const router = Router();

router.get("/", getAllSchemes);
router.get("/:id", getSchemeById);

export default router;
