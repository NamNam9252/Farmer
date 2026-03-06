import { Request, Response, NextFunction } from 'express';
import { AuthService } from './auth.service.js';
import { successResponse } from '../../core/utils/response.util.js';

export class AuthController {
    private authService: AuthService;

    constructor() {
        this.authService = new AuthService();
    }

    // Bind methods using arrow functions so `this` context is preserved
    public signup = async (req: Request, res: Response, next: NextFunction) => {
        try {
            const result = await this.authService.signup(req.body);
            res.status(201).json(successResponse('User registered successfully, please verify your email', result));
        } catch (error) {
            next(error); // Pass error to global error handler
        }
    };

    public requestOtp = async (req: Request, res: Response, next: NextFunction) => {
        try {
            const result = await this.authService.requestOtp(req.body);
            res.status(200).json(successResponse('OTP sent successfully', result));
        } catch (error) {
            next(error);
        }
    };

    public verifyOtp = async (req: Request, res: Response, next: NextFunction) => {
        try {
            const result = await this.authService.verifyOtp(req.body);
            res.status(200).json(successResponse('Email verified successfully', result));
        } catch (error) {
            next(error);
        }
    };

    public login = async (req: Request, res: Response, next: NextFunction) => {
        try {
            const result = await this.authService.login(req.body);
            res.status(200).json(successResponse('Login successful', result));
        } catch (error) {
            next(error);
        }
    };
}
