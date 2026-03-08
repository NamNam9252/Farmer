import { PrismaClient, CommunityType, NotificationChannel } from '@prisma/client';
import * as NotificationService from '../notifications/notification.service.js';

const prisma = new PrismaClient();

// Haversine formula distance calculation for MongoDB
export const getNearbyCommunities = async (lat: number, lng: number, radiusKm: number) => {
    // In a real production scenario, use MongoDB $geoNear.
    // Here we filter by type ROUND or RADIUS_BASED, but for general communities:
    const communities = await prisma.community.findMany({
        where: {
            isActive: true,
            isDeleted: false,
        },
        include: {
            _count: {
                select: { members: true }
            }
        }
    });

    // Filtering memory-side for simplification if $geoNear is not directly available via Prisma
    return communities.filter(c => {
        if (!c.centerLatitude || !c.centerLongitude) return true; // Global communities
        const R = 6371; // Radius of the earth in km
        const dLat = (c.centerLatitude - lat) * (Math.PI / 180);
        const dLon = (c.centerLongitude - lng) * (Math.PI / 180);
        const a =
            Math.sin(dLat / 2) * Math.sin(dLat / 2) +
            Math.cos(lat * (Math.PI / 180)) * Math.cos(c.centerLatitude * (Math.PI / 180)) *
            Math.sin(dLon / 2) * Math.sin(dLon / 2);
        const c2 = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
        const d = R * c2;
        return d <= (c.radiusKm || radiusKm);
    });
};

export const createCommunity = async (userId: string, data: any) => {
    const community = await prisma.community.create({
        data: {
            name: data.name,
            description: data.description,
            type: data.type || CommunityType.GENERAL,
            createdById: userId,
            isPrivate: data.isPrivate || false,
            centerLatitude: data.latitude,
            centerLongitude: data.longitude,
            radiusKm: data.radiusKm || 50,
            members: {
                create: {
                    userId: userId,
                    role: 'ADMIN'
                }
            },
            chatRooms: {
                create: {
                    name: 'General',
                    slug: 'general',
                    description: 'General community chat',
                    isDefault: true,
                    createdById: userId
                }
            }
        },
        include: {
            chatRooms: true
        }
    });

    return community;
};

export const getCommunityDetails = async (communityId: string, userId?: string) => {
    const community = await prisma.community.findUnique({
        where: { id: communityId },
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

    if (!community) return null;

    let isPending = false;
    if (userId) {
        const pendingReq = await prisma.communityJoinRequest.findFirst({
            where: { communityId, userId, status: 'PENDING' }
        });
        isPending = !!pendingReq;
    }

    return { ...community, isPending };
};

export const joinCommunity = async (userId: string, communityId: string) => {
    const community = await prisma.community.findUnique({
        where: { id: communityId }
    });

    if (!community) {
        throw new Error('Community not found');
    }

    const existingMember = await prisma.communityMember.findUnique({
        where: {
            communityId_userId: { communityId, userId }
        }
    });

    if (existingMember) {
        throw new Error('User is already a member of this community.');
    }

    if (community.isPrivate) {
        // Check if a pending request already exists
        const existingReq = await prisma.communityJoinRequest.findFirst({
            where: { communityId, userId, status: 'PENDING' }
        });

        if (existingReq) {
            throw new Error('Join request already pending.');
        }

        const request = await prisma.communityJoinRequest.create({
            data: {
                communityId,
                userId
            }
        });

        // Notify Admin
        await NotificationService.createNotification({
            userId: community.createdById,
            title: 'New Community Join Request',
            body: `A user has requested to join "${community.name}".`,
            actionType: 'COMMUNITY_JOIN_REQUEST',
            actionId: communityId
        });

        return { message: 'Join request sent and pending approval', request };
    }

    // Public community - join directly
    const member = await prisma.communityMember.create({
        data: {
            communityId,
            userId,
            role: 'MEMBER'
        }
    });

    // Increment member count
    await prisma.community.update({
        where: { id: communityId },
        data: { memberCount: { increment: 1 } }
    });

    return member;
};

export const leaveCommunity = async (userId: string, communityId: string) => {
    await prisma.communityMember.delete({
        where: {
            communityId_userId: { communityId, userId }
        }
    });

    // Decrement member count
    await prisma.community.update({
        where: { id: communityId },
        data: { memberCount: { decrement: 1 } }
    });
};

export const listMembers = async (communityId: string) => {
    return prisma.communityMember.findMany({
        where: { communityId },
        include: {
            user: {
                select: { id: true, name: true, profileImageUrl: true }
            }
        },
        orderBy: { role: 'asc' } // ADMINs first
    });
};

export const listJoinRequests = async (userId: string, communityId: string) => {
    // Verify requester is admin or moderator
    const member = await prisma.communityMember.findUnique({
        where: { communityId_userId: { communityId, userId } }
    });

    if (!member || (member.role !== 'ADMIN' && member.role !== 'MODERATOR')) {
        throw new Error('Unauthorized: Only community admins or moderators can view join requests.');
    }

    return prisma.communityJoinRequest.findMany({
        where: { communityId, status: 'PENDING' },
        include: {
            user: { select: { id: true, name: true, profileImageUrl: true } }
        },
        orderBy: { createdAt: 'asc' }
    });
};

export const approveJoinRequest = async (adminId: string, communityId: string, requestId: string) => {
    const adminMember = await prisma.communityMember.findUnique({
        where: { communityId_userId: { communityId, userId: adminId } }
    });

    if (!adminMember || (adminMember.role !== 'ADMIN' && adminMember.role !== 'MODERATOR')) {
        throw new Error('Unauthorized: Only admins can approve requests.');
    }

    const request = await prisma.communityJoinRequest.findUnique({ where: { id: requestId } });
    if (!request || request.status !== 'PENDING') {
        throw new Error('Valid pending request not found.');
    }

    // Approve request
    await prisma.communityJoinRequest.update({
        where: { id: requestId },
        data: { status: 'APPROVED' }
    });

    // Add member
    const member = await prisma.communityMember.create({
        data: {
            communityId,
            userId: request.userId,
            role: 'MEMBER'
        }
    });

    // Update count
    await prisma.community.update({
        where: { id: communityId },
        data: { memberCount: { increment: 1 } }
    });

    // Notify User
    await NotificationService.createNotification({
        userId: request.userId,
        title: 'Join Request Approved',
        body: `Your request to join "${adminMember.communityId}" has been approved!`, // Minor: community name would be better
        actionType: 'COMMUNITY_APPROVED',
        actionId: communityId
    });

    return member;
};

export const rejectJoinRequest = async (adminId: string, communityId: string, requestId: string) => {
    const adminMember = await prisma.communityMember.findUnique({
        where: { communityId_userId: { communityId, userId: adminId } }
    });

    if (!adminMember || (adminMember.role !== 'ADMIN' && adminMember.role !== 'MODERATOR')) {
        throw new Error('Unauthorized: Only admins can reject requests.');
    }

    return prisma.communityJoinRequest.update({
        where: { id: requestId },
        data: { status: 'REJECTED' }
    });
};

export const updateMemberRole = async (adminId: string, communityId: string, targetMemberId: string, newRole: any) => {
    const adminMember = await prisma.communityMember.findUnique({
        where: { communityId_userId: { communityId, userId: adminId } }
    });

    if (!adminMember || adminMember.role !== 'ADMIN') {
        throw new Error('Unauthorized: Only ADMIN can change member roles.');
    }

    return prisma.communityMember.update({
        where: { communityId_userId: { communityId, userId: targetMemberId } },
        data: { role: newRole }
    });
};

export const createLoanRequest = async (userId: string, communityId: string, data: any) => {
    // The user creating a loan must have a FarmerProfile linked
    const farmerProfile = await prisma.farmerProfile.findUnique({
        where: { userId }
    });

    if (!farmerProfile) {
        throw new Error('Only registered farmers can create loan requests.');
    }

    const loan = await prisma.loanRequest.create({
        data: {
            farmerId: farmerProfile.id,
            communityId,
            title: data.title,
            amount: parseFloat(data.amount),
            reason: data.reason,
            description: data.description,
            deadline: data.deadline ? new Date(data.deadline) : null
        }
    });

    // Create a wallet entry for the loan
    await prisma.loanFundWallet.create({
        data: { loanId: loan.id }
    });

    return loan;
};

export const voteForLoan = async (userId: string, loanId: string) => {
    const existing = await prisma.loanVote.findUnique({
        where: { loanId_voterId: { loanId, voterId: userId } }
    });

    if (existing) {
        throw new Error('You have already voted for this loan.');
    }

    const vote = await prisma.loanVote.create({
        data: {
            loanId,
            voterId: userId
        }
    });

    await prisma.loanRequest.update({
        where: { id: loanId },
        data: { supporterCount: { increment: 1 } }
    });

    return vote;
};

export const fundLoan = async (userId: string, loanId: string, amount: number, message?: string, isAnonymous: boolean = false) => {
    const pledge = await prisma.loanPledge.create({
        data: {
            loanId,
            pledgerId: userId,
            amount,
            message,
            isAnonymous
        }
    });

    await prisma.loanRequest.update({
        where: { id: loanId },
        data: {
            pledgedAmount: { increment: amount },
            pledgerCount: { increment: 1 }
        }
    });

    await prisma.loanFundWallet.update({
        where: { loanId },
        data: { totalPledged: { increment: amount } }
    });

    return pledge;
};

export const getChatRooms = async (communityId: string) => {
    return prisma.communityChatRoom.findMany({
        where: { communityId, isDeleted: false },
        orderBy: { lastMessageAt: 'desc' }
    });
};

export const createChatRoom = async (userId: string, communityId: string, data: any) => {
    return prisma.communityChatRoom.create({
        data: {
            communityId,
            name: data.name,
            slug: data.name.toLowerCase().replace(/\s+/g, '-'),
            description: data.description,
            createdById: userId
        }
    });
};

export const getChatroomMessages = async (roomId: string, limit: number, cursor?: string) => {
    const args: any = {
        where: { roomId, isDeleted: false },
        take: limit,
        orderBy: { createdAt: 'desc' },
        include: {
            sender: { select: { id: true, name: true, profileImageUrl: true } }
        }
    };

    if (cursor) {
        args.cursor = { id: cursor };
        args.skip = 1;
    }

    const messages = await prisma.communityChatMessage.findMany(args);
    return messages.reverse();
};

export const deleteCommunity = async (userId: string, communityId: string) => {
    const community = await prisma.community.findUnique({
        where: { id: communityId },
        include: { members: { select: { userId: true } } }
    });

    if (!community) {
        throw new Error('Community not found');
    }

    if (community.createdById !== userId) {
        throw new Error('You do not have permission to delete this community');
    }

    // Soft delete
    await prisma.community.update({
        where: { id: communityId },
        data: {
            isActive: false,
            isDeleted: true
        }
    });

    // Notify all members except the admin
    const memberIds = community.members
        .map(m => m.userId)
        .filter(id => id !== userId);
    if (memberIds.length > 0) {
        await NotificationService.createBulkNotifications({
            userIds: memberIds,
            title: 'Community Deleted',
            body: `The community "${community.name}" has been deleted by the admin.`,
            actionType: 'COMMUNITY_DELETED',
            actionId: communityId
        });
    }

    return { success: true };
};
