import { Router } from 'express';
import { AuthController } from './auth.controller.js';
import { validate } from '../../middleware/validate.middleware.js';
import { signupSchema, loginSchema, requestOtpSchema, verifyEmailSchema } from '../../schema/auth.schema.js';

const router = Router();
const authController = new AuthController();

router.post('/signup', validate(signupSchema), authController.signup);
router.post('/request-otp', validate(requestOtpSchema), authController.requestOtp);
router.post('/verify-otp', validate(verifyEmailSchema), authController.verifyOtp);
router.post('/login', validate(loginSchema), authController.login);

export default router;
