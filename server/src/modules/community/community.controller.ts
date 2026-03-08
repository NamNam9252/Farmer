import { Request, Response, NextFunction } from 'express';
import * as CommunityService from './community.service.js';

export const createCommunity = async (req: Request, res: Response, next: NextFunction) => {
    try {
        const userId = (req as any).user.id; // from requireAuth middleware
        const community = await CommunityService.createCommunity(userId, req.body);
        res.status(201).json({ success: true, data: community });
    } catch (error) {
        next(error);
    }
};

export const getNearbyCommunities = async (req: Request, res: Response, next: NextFunction) => {
    try {
        const lat = parseFloat(req.query.lat as string);
        const lng = parseFloat(req.query.lng as string);
        const radius = parseFloat(req.query.radius as string) || 50;

        if (isNaN(lat) || isNaN(lng)) {
            return res.status(400).json({ success: false, message: 'Latitude and longitude are required.' });
        }

        const communities = await CommunityService.getNearbyCommunities(lat, lng, radius);
        res.status(200).json({ success: true, data: communities });
    } catch (error) {
        next(error);
    }
};

export const getCommunityDetails = async (req: Request, res: Response, next: NextFunction) => {
    try {
        const userId = (req as any).user?.id;
        const community = await CommunityService.getCommunityDetails(req.params.id as string, userId);
        if (!community) {
            return res.status(404).json({ success: false, message: 'Community not found.' });
        }
        res.status(200).json({ success: true, data: community });
    } catch (error) {
        next(error);
    }
};

export const joinCommunity = async (req: Request, res: Response, next: NextFunction) => {
    try {
        const userId = (req as any).user.id;
        const result = await CommunityService.joinCommunity(userId, req.params.id as string);
        res.status(200).json({ success: true, data: result });
    } catch (error: any) {
        if (error.message.includes('already a member')) {
            return res.status(400).json({ success: false, message: error.message });
        }
        next(error);
    }
};

export const leaveCommunity = async (req: Request, res: Response, next: NextFunction) => {
    try {
        const userId = (req as any).user.id;
        await CommunityService.leaveCommunity(userId, req.params.id as string);
        res.status(200).json({ success: true, message: 'Left community successfully.' });
    } catch (error) {
        next(error);
    }
};

export const listMembers = async (req: Request, res: Response, next: NextFunction) => {
    try {
        const members = await CommunityService.listMembers(req.params.id as string);
        res.status(200).json({ success: true, data: members });
    } catch (error) {
        next(error);
    }
};

export const listJoinRequests = async (req: Request, res: Response, next: NextFunction) => {
    try {
        const userId = (req as any).user.id;
        const requests = await CommunityService.listJoinRequests(userId, req.params.id as string);
        res.status(200).json({ success: true, data: requests });
    } catch (error) {
        next(error);
    }
};

export const approveJoinRequest = async (req: Request, res: Response, next: NextFunction) => {
    try {
        const userId = (req as any).user.id;
        const result = await CommunityService.approveJoinRequest(userId, req.params.id as string, req.params.requestId as string);
        res.status(200).json({ success: true, data: result });
    } catch (error) {
        next(error);
    }
};

export const rejectJoinRequest = async (req: Request, res: Response, next: NextFunction) => {
    try {
        const userId = (req as any).user.id;
        const result = await CommunityService.rejectJoinRequest(userId, req.params.id as string, req.params.requestId as string);
        res.status(200).json({ success: true, data: result });
    } catch (error) {
        next(error);
    }
};

export const deleteCommunity = async (req: Request, res: Response, next: NextFunction) => {
    try {
        const userId = (req as any).user.id;
        const result = await CommunityService.deleteCommunity(userId, req.params.id as string);
        res.status(200).json({ success: true, data: result });
    } catch (error) {
        next(error);
    }
};

export const updateMemberRole = async (req: Request, res: Response, next: NextFunction) => {
    try {
        const userId = (req as any).user.id;
        const { role } = req.body;
        if (!['ADMIN', 'MODERATOR', 'MEMBER'].includes(role)) {
            return res.status(400).json({ success: false, message: 'Invalid role provided.' });
        }
        const result = await CommunityService.updateMemberRole(userId, req.params.id as string, req.params.memberId as string, role);
        res.status(200).json({ success: true, data: result });
    } catch (error) {
        next(error);
    }
};

export const createLoanRequest = async (req: Request, res: Response, next: NextFunction) => {
    try {
        const userId = (req as any).user.id;
        const loan = await CommunityService.createLoanRequest(userId, req.params.id as string, req.body);
        res.status(201).json({ success: true, data: loan });
    } catch (error) {
        next(error);
    }
};

export const voteForLoan = async (req: Request, res: Response, next: NextFunction) => {
    try {
        const userId = (req as any).user.id;
        const result = await CommunityService.voteForLoan(userId, req.params.loanId as string);
        res.status(200).json({ success: true, data: result });
    } catch (error: any) {
        if (error.message.includes('already voted')) {
            return res.status(400).json({ success: false, message: error.message });
        }
        next(error);
    }
};

export const fundLoan = async (req: Request, res: Response, next: NextFunction) => {
    try {
        const userId = (req as any).user.id;
        const amount = parseFloat(req.body.amount);
        if (isNaN(amount) || amount <= 0) {
            return res.status(400).json({ success: false, message: 'Valid amount is required.' });
        }

        const result = await CommunityService.fundLoan(userId, req.params.loanId as string, amount, req.body.message, req.body.isAnonymous);
        res.status(200).json({ success: true, data: result });
    } catch (error) {
        next(error);
    }
};

export const getChatRooms = async (req: Request, res: Response, next: NextFunction) => {
    try {
        const rooms = await CommunityService.getChatRooms(req.params.id as string);
        res.status(200).json({ success: true, data: rooms });
    } catch (error) {
        next(error);
    }
};

export const createChatRoom = async (req: Request, res: Response, next: NextFunction) => {
    try {
        const userId = (req as any).user.id;
        const room = await CommunityService.createChatRoom(userId, req.params.id as string, req.body);
        res.status(201).json({ success: true, data: room });
    } catch (error) {
        next(error);
    }
};

export const getChatroomMessages = async (req: Request, res: Response, next: NextFunction) => {
    try {
        const limit = parseInt(req.query.limit as string) || 50;
        const cursor = req.query.cursor as string;

        const messages = await CommunityService.getChatroomMessages(req.params.roomId as string, limit, cursor);
        res.status(200).json({ success: true, data: messages });
    } catch (error) {
        next(error);
    }
};
