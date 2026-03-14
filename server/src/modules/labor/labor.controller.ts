import { Request, Response, NextFunction } from "express";
import { LaborService } from "./labor.service.js";

export class LaborController {
  private service = new LaborService();

  createProfile = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const result = await this.service.createProfile(req.user.id, req.body);
      res.json(result);
    } catch (err) {
      next(err);
    }
  };

  getProfile = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const result = await this.service.getProfile(req.user.id);
      res.json({ success: true, data: result });
    } catch (err) {
      next(err);
    }
  };

  updateProfile = async (req: Request, res: Response, next: NextFunction) => {
    try {
      console.log('--- [UPDATE PROFILE] ---');
      console.log('User ID:', req.user.id);
      console.log('Body:', req.body);
      const result = await this.service.updateProfile(req.user.id, req.body);
      console.log('Result:', result);
      res.json({ success: true, message: 'Profile updated successfully', data: result });
    } catch (err) {
      console.error('--- [UPDATE PROFILE ERROR] ---', err);
      next(err);
    }
  };

  listAvailable = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const result = await this.service.listAvailable(
        req.query.districtId as string,
      );

      res.json(result);
    } catch (err) {
      next(err);
    }
  };

  hireLabor = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const result = await this.service.hireLabor(
        req.user.id,
        req.params.laborId as any,
        req.body,
      );

      res.json(result);
    } catch (err) {
      next(err);
    }
  };

  terminateEmployment = async (
    req: Request,
    res: Response,
    next: NextFunction,
  ) => {
    try {
      const result = await this.service.terminateEmployment(
        req.params.id as any,
      );
      res.json(result);
    } catch (err) {
      next(err);
    }
  };

  farmerLabor = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const result = await this.service.farmerLabor(req.user.id);

      res.json(result);
    } catch (err) {
      next(err);
    }
  };
}
