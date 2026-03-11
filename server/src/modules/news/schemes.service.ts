import { SchemesRepository } from "./schemes.repository.js";

export class SchemesService {
    async getAllSchemes() {
        return SchemesRepository.getAll();
    }

    async getSchemeById(id: string) {
        return SchemesRepository.getById(id);
    }
}
