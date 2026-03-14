import { PrismaClient } from "@prisma/client";
import * as fs from 'fs';
const prisma = new PrismaClient();

async function main() {
  const profiles = await prisma.laborProfile.findMany();
  fs.writeFileSync('test_db_out_new.json', JSON.stringify(profiles, null, 2), 'utf-8');
}

main().finally(() => prisma.$disconnect());
