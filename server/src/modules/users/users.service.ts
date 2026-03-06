import { UsersRepository } from './users.repository.js';
import { LocationInput, FarmerProfileInput, LaborProfileInput, ExpertProfileInput } from '../../schema/user.schema.js';

export class UsersService {
    private repository: UsersRepository;

    constructor() {
        this.repository = new UsersRepository();
    }

    async createLocation(userId: string, data: LocationInput) {
        return this.repository.createPrimaryLocation(userId, data);
    }

    async createFarmerProfile(userId: string, data: FarmerProfileInput) {
        return this.repository.createFarmerProfile(userId, data);
    }

    async createLaborProfile(userId: string, data: LaborProfileInput) {
        return this.repository.createLaborProfile(userId, data);
    }

    async createExpertProfile(userId: string, data: ExpertProfileInput) {
        return this.repository.createExpertProfile(userId, data);
    }
}
