import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function test() {
  console.log('Fetching communities...');
  const comms = await prisma.community.findMany({ take: 1 });
  
  if (comms.length === 0) {
      console.log('No communities found');
      return;
  }
  
  const id = comms[0].id;
  console.log('Fetching details for:', id);
  
  const details = await prisma.community.findUnique({
        where: { id },
        include: {
            createdBy: { select: { id: true, name: true } },
            chatRooms: true,
            loanRequests: {
                where: { isDeleted: false },
                include: { _count: { select: { votes: true, pledges: true } } }
            },
            _count: {
                select: { members: true, posts: true }
            }
        }
  });
  
  console.log('Details:', JSON.stringify(details));
  
  console.log('Fetching members...');
  const members = await prisma.communityMember.findMany({
        where: { communityId: id },
        include: {
            user: {
                select: { id: true, name: true, profileImageUrl: true }
            }
        }
    });
    
  console.log('Members:', JSON.stringify(members));
}

test().catch(console.error).finally(() => prisma.$disconnect());
