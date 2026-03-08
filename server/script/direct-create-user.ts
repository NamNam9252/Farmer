import { MongoClient, ObjectId } from 'mongodb';
import bcrypt from 'bcryptjs';

const url = 'mongodb://localhost:27017';
const dbName = 'kisan-saathi';

async function main() {
    const client = new MongoClient(url);
    try {
        await client.connect();
        const db = client.db(dbName);
        const users = db.collection('users');

        const phone = '1234567890';
        const password = 'password123';
        const passwordHash = await bcrypt.hash(password, 10);

        const existing = await users.findOne({ phone });
        if (existing) {
            console.log('NOTICE: User already exists.');
        } else {
            const result = await users.insertOne({
                _id: new ObjectId(),
                name: 'Test Farmer',
                phone: phone,
                email: 'test@example.com',
                passwordHash: passwordHash,
                role: 'FARMER',
                status: 'ACTIVE',
                preferredLanguage: 'hi',
                isPhoneVerified: true,
                isEmailVerified: true,
                createdAt: new Date(),
                updatedAt: new Date(),
                isDeleted: false,
                isFlagged: false,
                failedLoginCount: 0
            });
            console.log('SUCCESS: User Created with ID:', result.insertedId);
        }

        console.log('\nTEST_CREDENTIALS:');
        console.log('Phone:', phone);
        console.log('Password:', password);

    } catch (error: any) {
        console.error('FAILED:', error.message);
    } finally {
        await client.close();
    }
}

main();
