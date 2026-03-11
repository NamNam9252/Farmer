import { PrismaClient } from '@prisma/client';
const prisma = new PrismaClient();

async function main() {
    const schemes = [
        {
            title: 'PM-Kisan Samman Nidhi',
            description: 'Income support of ₹6,000 per year in three equal installments to all land-holding farmer families.',
            schemeCategory: 'SUBSIDY',
            isNational: true,
            isActive: true,
            officialLink: 'https://pmkisan.gov.in/',
            maxBenefitAmount: 6000,
            benefitUnit: 'per year',
        },
        {
            title: 'Pradhan Mantri Fasal Bima Yojana',
            description: 'Crop insurance scheme to provide financial support to farmers suffering from crop loss/damage.',
            schemeCategory: 'INSURANCE',
            isNational: true,
            isActive: true,
            officialLink: 'https://pmfby.gov.in/',
        },
        {
            title: 'Kisan Credit Card (KCC)',
            description: 'Provides farmers with timely access to credit for their cultivation and other needs.',
            schemeCategory: 'LOAN',
            isNational: true,
            isActive: true,
            officialLink: 'https://www.myscheme.gov.in/schemes/kcc',
        }
    ];

    console.log('Seeding schemes...');
    for (const scheme of schemes) {
        const existing = await prisma.governmentScheme.findFirst({
            where: { title: scheme.title }
        });
        if (!existing) {
            await prisma.governmentScheme.create({ data: scheme });
            console.log(`Created scheme: ${scheme.title}`);
        } else {
            console.log(`Scheme exists: ${scheme.title}`);
        }
    }
    console.log('Seeding completed.');
}

main()
    .catch((e) => {
        console.error(e);
        process.exit(1);
    })
    .finally(async () => {
        await prisma.$disconnect();
    });
