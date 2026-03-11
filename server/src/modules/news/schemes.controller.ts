import { Request, Response, NextFunction } from "express";
import { SchemesService } from "./schemes.service.js";

const schemesService = new SchemesService();

export const getAllSchemes = async (req: Request, res: Response, next: NextFunction) => {
    try {
        const schemes = await schemesService.getAllSchemes();
        res.status(200).json({
            success: true,
            message: "Schemes fetched successfully",
            data: schemes,
        });
    } catch (error) {
        next(error);
    }
};

export const getSchemeById = async (req: Request, res: Response, next: NextFunction) => {
    try {
        const scheme = await schemesService.getSchemeById(req.params.id as string);
        if (!scheme) {
            return res.status(404).json({
                success: false,
                message: "Scheme not found",
            });
        }
        res.status(200).json({
            success: true,
            message: "Scheme fetched successfully",
            data: scheme,
        });
    } catch (error) {
        next(error);
    }
};
