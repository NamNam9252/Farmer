import nodemailer from 'nodemailer';

// Create a transporter object using standard SMTP transport
const transporter = nodemailer.createTransport({
    service: 'gmail', // Typically gmail for app passwords, but can be configured otherwise if needed
    auth: {
        user: process.env.EMAIL_USER,
        pass: process.env.EMAIL_PASS,
    },
});

/**
 * Sends an OTP verification email.
 * @param to recipient email
 * @param name recipient name
 * @param otp the 6-digit OTP
 */
export const sendVerificationEmail = async (to: string, name: string, otp: string) => {
    // Elegant HTML template for the email
    const htmlTemplate = `
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="utf-8">
        <style>
            body {
                font-family: 'Inter', 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
                background-color: #f4f7f6;
                margin: 0;
                padding: 0;
            }
            .container {
                max-width: 600px;
                margin: 40px auto;
                background: #ffffff;
                border-radius: 12px;
                overflow: hidden;
                box-shadow: 0 4px 15px rgba(0, 0, 0, 0.05);
            }
            .header {
                background: linear-gradient(135deg, #10b981 0%, #059669 100%);
                padding: 30px;
                text-align: center;
                color: white;
            }
            .header h1 {
                margin: 0;
                font-size: 24px;
                letter-spacing: 1px;
            }
            .content {
                padding: 40px 30px;
                color: #333333;
                line-height: 1.6;
            }
            .content p {
                margin-top: 0;
                font-size: 16px;
            }
            .otp-container {
                margin: 30px 0;
                text-align: center;
            }
            .otp {
                display: inline-block;
                font-size: 32px;
                font-weight: bold;
                color: #059669;
                letter-spacing: 8px;
                padding: 15px 30px;
                background: #ecfdf5;
                border-radius: 8px;
                border: 2px dashed #34d399;
            }
            .footer {
                text-align: center;
                padding: 20px;
                font-size: 13px;
                color: #9ca3af;
                background: #f9fafb;
                border-top: 1px solid #f3f4f6;
            }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <h1>AgriAI</h1>
            </div>
            <div class="content">
                <p>Hello <strong>${name}</strong>,</p>
                <p>Thank you for joining Farmer. To complete your registration and verify your email address, please use the One-Time Password (OTP) below.</p>
                
                <div class="otp-container">
                    <span class="otp">${otp}</span>
                </div>
                
                <p>This code is valid for <strong>10 minutes</strong>. Please do not share this code with anyone.</p>
                <p>If you did not request this verification, you can safely ignore this email.</p>
                
                <br>
                <p>Best Regards,<br>The AgriAI Team</p>
            </div>
            <div class="footer">
                <p>&copy; ${new Date().getFullYear()} AgriAI. All rights reserved.</p>
            </div>
        </div>
    </body>
    </html>
    `;

    const mailOptions = {
        from: process.env.EMAIL_FROM || '"AgriAI Support" <noreply@agriai.com>',
        to,
        subject: 'Verify Your Email - AgriAI',
        html: htmlTemplate,
    };

    try {
        const info = await transporter.sendMail(mailOptions);
        console.log(`[Email] Verification OTP sent to ${to}. MessageId: ${info.messageId}`);
        return true;
    } catch (error) {
        console.error('[Email] Failed to send verification email:', error);
    }
};

/**
 * Sends a welcome email upon successful signup.
 * @param to recipient email
 * @param name recipient name
 */
export const sendWelcomeEmail = async (to: string, name: string) => {
    const htmlTemplate = `
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="utf-8">
        <style>
            body {
                font-family: 'Inter', 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
                background-color: #f4f7f6;
                margin: 0;
                padding: 0;
            }
            .container {
                max-width: 600px;
                margin: 40px auto;
                background: #ffffff;
                border-radius: 12px;
                overflow: hidden;
                box-shadow: 0 4px 15px rgba(0, 0, 0, 0.05);
            }
            .header {
                background: linear-gradient(135deg, #10b981 0%, #059669 100%);
                padding: 30px;
                text-align: center;
                color: white;
            }
            .header h1 {
                margin: 0;
                font-size: 24px;
                letter-spacing: 1px;
            }
            .content {
                padding: 40px 30px;
                color: #333333;
                line-height: 1.6;
            }
            .content p {
                margin-top: 0;
                font-size: 16px;
                margin-bottom: 16px;
            }
            .features {
                margin: 30px 0;
                padding-left: 0;
                list-style-type: none;
            }
            .features li {
                margin-bottom: 20px;
            }
            .features strong {
                color: #059669;
                display: block;
                font-size: 17px;
                margin-bottom: 4px;
            }
            .footer {
                text-align: center;
                padding: 20px;
                font-size: 13px;
                color: #9ca3af;
                background: #f9fafb;
                border-top: 1px solid #f3f4f6;
            }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <h1>Farmer One Stop Solution</h1>
            </div>
            <div class="content">
                <p>Dear Farmer Friend, <strong>${name}</strong>,</p>
                <p>🌾 Welcome to <strong>Farmer One Stop Solution</strong> &mdash; we are truly excited to have you with us!</p>
                <p>You are now part of a growing digital farming community built to support, empower, and uplift farmers like you with the right tools, right information, and the right opportunities &mdash; all in one place.</p>
                
                <p>Here’s what you can now access in our MVP:</p>

                <ul class="features">
                    <li>
                        <strong>🌦 Smart Weather Updates</strong>
                        Get location-based weather insights to help you plan irrigation, sowing, and harvesting better.
                    </li>
                    <li>
                        <strong>🌱 Crop & Land Management</strong>
                        Manage your lands, track crops, and maintain detailed records for better productivity.
                    </li>
                    <li>
                        <strong>🦠 AI Disease Detection</strong>
                        Upload crop images and receive instant AI-based disease analysis with treatment suggestions.
                    </li>
                    <li>
                        <strong>📢 Location-Based Alerts</strong>
                        Receive real-time alerts about weather risks, disease outbreaks, and important agricultural updates in your area.
                    </li>
                    <li>
                        <strong>🛒 Marketplace Access</strong>
                        List your crops, connect directly with buyers, and manage your sales securely.
                    </li>
                    <li>
                        <strong>🤝 Crowdfunding Support</strong>
                        Raise funds for your farming needs with transparent and milestone-based support.
                    </li>
                    <li>
                        <strong>👩‍🌾 Community & Knowledge Sharing</strong>
                        Connect with farmers in your district, join discussions, and learn from shared experiences.
                    </li>
                    <li>
                        <strong>📰 Government Schemes & News</strong>
                        Stay updated with relevant agricultural schemes and local farming news.
                    </li>
                    <li>
                        <strong>💬 AI Chat Assistance</strong>
                        Get farming guidance anytime through our built-in AI assistant.
                    </li>
                </ul>

                <p>We built this platform with one mission:<br/>
                <em>To make farming smarter, safer, and more profitable.</em></p>

                <p>We understand that technology should feel simple and helpful &mdash; not complicated. That’s why our app is designed to be easy to use, secure, and fully focused on real farmer needs.</p>

                <p>We encourage you to explore all features, join your local community, and start using the tools designed specifically for you.</p>

                <p>Your journey toward smarter farming starts today &mdash; and we’re proud to support you at every step.</p>

                <p>If you ever need help, our support team is always here for you.</p>

                <p>Welcome once again,<br/>
                Team Farmer One Stop Solution 🌾</p>

                <p style="font-style: italic; color: #059669; text-align: center; margin-top: 30px;">“Not just an app &mdash; your complete farming partner.”</p>
            </div>
            <div class="footer">
                <p>&copy; ${new Date().getFullYear()} Farmer One Stop Solution. All rights reserved.</p>
            </div>
        </div>
    </body>
    </html>
    `;

    const mailOptions = {
        from: process.env.EMAIL_FROM || '"AgriAI Support" <noreply@agriai.com>',
        to,
        subject: 'Welcome to Farmer One Stop Solution 🌾',
        html: htmlTemplate,
    };

    try {
        const info = await transporter.sendMail(mailOptions);
        console.log(`[Email] Welcome email sent to ${to}. MessageId: ${info.messageId}`);
        return true;
    } catch (error) {
        console.error('[Email] Failed to send welcome email:', error);
        throw new Error('Failed to send welcome email.');
    }
};
