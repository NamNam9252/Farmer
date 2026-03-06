import { Router } from 'express';
import { UsersController } from './users.controller.js';
import { validate } from '../../middleware/validate.middleware.js';
import { locationSchema, farmerProfileSchema, laborProfileSchema, expertProfileSchema } from '../../schema/user.schema.js';
import { requireAuth } from '../../middleware/auth.middleware.js';

const router = Router();
const usersController = new UsersController();

// All user routes require authentication
router.use(requireAuth);

router.post('/location', validate(locationSchema), usersController.createLocation);
router.post('/profile/farmer', validate(farmerProfileSchema), usersController.createFarmerProfile);
router.post('/profile/labor', validate(laborProfileSchema), usersController.createLaborProfile);
router.post('/profile/expert', validate(expertProfileSchema), usersController.createExpertProfile);

export default router;
