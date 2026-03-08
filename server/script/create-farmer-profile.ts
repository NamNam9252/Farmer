import { MongoClient, ObjectId } from 'mongodb';

const url = 'mongodb://localhost:27017';
const dbName = 'kisan-saathi';

async function main() {
    const client = new MongoClient(url);
    try {
        await client.connect();
        const db = client.db(dbName);
        const users = db.collection('users');
        const farmerProfiles = db.collection('farmerprofiles');

        const phone = '1234567890';
        const user = await users.findOne({ phone });

        if (!user) {
            console.error('FAILED: User not found');
            return;
        }

        const existingProfile = await farmerProfiles.findOne({ userId: user._id });
        if (existingProfile) {
            console.log('NOTICE: FarmerProfile already exists.');
        } else {
            await farmerProfiles.insertOne({
                _id: new ObjectId(),
                userId: user._id,
                totalLandArea: 5.0,
                experienceYears: 10,
                isKycVerified: true,
                trustScore: 5.0,
                createdAt: new Date(),
                updatedAt: new Date(),
                isDeleted: false
            });
            console.log('SUCCESS: FarmerProfile Created');
        }
    } catch (error: any) {
        console.error('FAILED:', error.message);
    } finally {
        await client.close();
    }
}

main();
