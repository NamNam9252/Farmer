import bcrypt from 'bcryptjs';
import { AuthRepository } from './auth.repository.js';
import { SignupInput, LoginInput } from '../../schema/auth.schema.js';
import { generateToken } from '../../core/utils/jwt.util.js';
import { BadRequestError, UnauthorizedError } from '../../core/errors/custom.error.js';

export class AuthService {
    private repository: AuthRepository;

    constructor() {
        this.repository = new AuthRepository();
    }

    async signup(data: SignupInput) {
        // Check if user exists by phone
        const existingPhone = await this.repository.findByPhone(data.phone);
        if (existingPhone) {
            throw new BadRequestError('User with this phone number already exists.');
        }

        // Check if user exists by email (if provided)
        if (data.email) {
            const existingEmail = await this.repository.findByEmail(data.email);
            if (existingEmail) {
                throw new BadRequestError('User with this email already exists.');
            }
        }

        // Hash password
        const salt = await bcrypt.genSalt(10);
        const passwordHash = await bcrypt.hash(data.password, salt);

        // Create user
        const user = await this.repository.createUser(data, passwordHash);

        // Generate token
        const token = generateToken({ id: user.id, role: user.role });

        return {
            user: {
                id: user.id,
                name: user.name,
                phone: user.phone,
                email: user.email,
                role: user.role,
            },
            token,
        };
    }

    async login(data: LoginInput) {
        // Find user
        const user = await this.repository.findByPhone(data.phone);
        if (!user) {
            throw new UnauthorizedError('Invalid credentials');
        }

        // Check password
        const isPasswordMatch = await bcrypt.compare(data.password, user.passwordHash);
        if (!isPasswordMatch) {
            throw new UnauthorizedError('Invalid credentials');
        }

        // Generate token
        const token = generateToken({ id: user.id, role: user.role });

        return {
            user: {
                id: user.id,
                name: user.name,
                phone: user.phone,
                email: user.email,
                role: user.role,
            },
            token,
        };
    }
}
