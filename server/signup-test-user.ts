import axios from 'axios';

async function main() {
    try {
        const payload = {
            name: "Test Farmer",
            phone: "1234567890",
            password: "password123",
            role: "FARMER",
            email: "test@farmer.com"
        };

        const response = await axios.post('http://localhost:3000/api/v1/auth/signup', payload);
        console.log('SUCCESS:', response.data.message);
    } catch (error: any) {
        if (error.response && error.response.status === 400) {
            console.log('NOTICE: User might already exist or invalid input.', error.response.data.message);
        } else {
            console.error('FAILED:', error.message);
        }
    }
}

main();
