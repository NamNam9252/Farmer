import bcrypt from 'bcryptjs';
import { AuthRepository } from './auth.repository.js';
import { SignupInput, LoginInput, VerifyEmailInput } from '../../schema/auth.schema.js';
import { generateToken } from '../../core/utils/jwt.util.js';
import { sendVerificationEmail, sendWelcomeEmail } from '../../core/utils/email.util.js';
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

        // Send Welcome Email
        if (user.email) {
            await sendWelcomeEmail(user.email, user.name);
        }

        // Generate token
        const tokenPayload = { 
            id: user.id, 
            role: user.role,
            name: user.name,
            phone: user.phone,
            email: user.email,
            status: user.status,
            isEmailVerified: user.isEmailVerified
        };
        const token = generateToken(tokenPayload);

        return {
            user: {
                id: user.id,
                name: user.name,
                phone: user.phone,
                email: user.email,
                role: user.role,
                status: user.status,
                isEmailVerified: user.isEmailVerified,
                preferredLanguage: user.preferredLanguage,
                isPhoneVerified: user.isPhoneVerified,
                profileImageUrl: user.profileImageUrl,
                createdAt: user.createdAt,
            },
            token,
            message: "User registered successfully",
        };
    }

    async requestOtp(data: { email: string }) {
        const user = await this.repository.findByEmail(data.email);
        if (!user) {
            throw new BadRequestError('User not found');
        }

        // Generate OTP
        const otp = Math.floor(100000 + Math.random() * 900000).toString();
        const otpHash = await bcrypt.hash(otp, 10);
        await this.repository.createVerification(user.id, otpHash);

        // Send OTP via Email
        await sendVerificationEmail(user.email!, user.name, otp);

        return {
            message: "OTP sent to email.",
        };
    }

    async verifyOtp(data: VerifyEmailInput) {
        const user = await this.repository.findByEmail(data.email);
        if (!user) {
            throw new BadRequestError('User not found');
        }

        const verification = await this.repository.findVerificationOrReject(user.id);
        if (!verification) {
            throw new BadRequestError('Invalid or expired OTP');
        }

        const isOtpMatch = await bcrypt.compare(data.otp, verification.otpHash);
        if (!isOtpMatch) {
            throw new BadRequestError('Invalid OTP');
        }

        const activatedUser = await this.repository.markVerificationUsedAndActivateUser(verification.id, user.id);

        const tokenPayload = { 
            id: activatedUser.id, 
            role: activatedUser.role,
            name: activatedUser.name,
            phone: activatedUser.phone,
            email: activatedUser.email,
            status: activatedUser.status,
            isEmailVerified: activatedUser.isEmailVerified 
        };
        const token = generateToken(tokenPayload);

        return {
            user: {
                id: activatedUser.id,
                name: activatedUser.name,
                phone: activatedUser.phone,
                email: activatedUser.email,
                role: activatedUser.role,
                status: activatedUser.status,
                isEmailVerified: activatedUser.isEmailVerified,
                preferredLanguage: activatedUser.preferredLanguage,
                isPhoneVerified: activatedUser.isPhoneVerified,
                profileImageUrl: activatedUser.profileImageUrl,
                createdAt: activatedUser.createdAt,
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
        const tokenPayload = { 
            id: user.id, 
            role: user.role,
            name: user.name,
            phone: user.phone,
            email: user.email,
            status: user.status,
            isEmailVerified: user.isEmailVerified 
        };
        const token = generateToken(tokenPayload);

        return {
            user: {
                id: user.id,
                name: user.name,
                phone: user.phone,
                email: user.email,
                role: user.role,
                status: user.status,
                isEmailVerified: user.isEmailVerified,
                preferredLanguage: user.preferredLanguage,
                isPhoneVerified: user.isPhoneVerified,
                profileImageUrl: user.profileImageUrl,
                createdAt: user.createdAt,
            },
            token,
        };
    }
}
