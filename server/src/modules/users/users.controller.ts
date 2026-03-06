import { Request, Response, NextFunction } from 'express';
import { UsersService } from './users.service.js';
import { successResponse } from '../../core/utils/response.util.js';

export class UsersController {
    private usersService: UsersService;

    constructor() {
        this.usersService = new UsersService();
    }

    public createLocation = async (req: Request, res: Response, next: NextFunction) => {
        try {
            const userId = (req as any).user.id;
            const result = await this.usersService.createLocation(userId, req.body);
            res.status(201).json(successResponse('Location created successfully', result));
        } catch (error) {
            next(error);
        }
    };

    public createFarmerProfile = async (req: Request, res: Response, next: NextFunction) => {
        try {
            const userId = (req as any).user.id;
            const result = await this.usersService.createFarmerProfile(userId, req.body);
            res.status(201).json(successResponse('Farmer profile created successfully', result));
        } catch (error) {
            next(error);
        }
    };

    public createLaborProfile = async (req: Request, res: Response, next: NextFunction) => {
        try {
            const userId = (req as any).user.id;
            const result = await this.usersService.createLaborProfile(userId, req.body);
            res.status(201).json(successResponse('Labor profile created successfully', result));
        } catch (error) {
            next(error);
        }
    };

    public createExpertProfile = async (req: Request, res: Response, next: NextFunction) => {
        try {
            const userId = (req as any).user.id;
            const result = await this.usersService.createExpertProfile(userId, req.body);
            res.status(201).json(successResponse('Expert profile created successfully', result));
        } catch (error) {
            next(error);
        }
    };
}
