import { Router } from 'express';
import * as CommunityController from './community.controller.js';
import { requireAuth } from '../../middleware/auth.middleware.js';

const router = Router();

router.use(requireAuth);

// Community CRUD and Listing
router.post('/', CommunityController.createCommunity);
router.get('/nearby', CommunityController.getNearbyCommunities);
router.get('/:id', CommunityController.getCommunityDetails);
router.post('/:id/join', CommunityController.joinCommunity); // Handles both direct join and request
router.post('/:id/leave', CommunityController.leaveCommunity);
router.delete('/:id', CommunityController.deleteCommunity);

// Admin & Membership
router.get('/:id/members', CommunityController.listMembers);
router.get('/:id/requests', CommunityController.listJoinRequests);
router.post('/:id/requests/:requestId/approve', CommunityController.approveJoinRequest);
router.post('/:id/requests/:requestId/reject', CommunityController.rejectJoinRequest);
router.post('/:id/members/:memberId/role', CommunityController.updateMemberRole);

// Community Loan endpoints
router.post('/:id/loan', CommunityController.createLoanRequest);
router.post('/loan/:loanId/vote', CommunityController.voteForLoan);
router.post('/loan/:loanId/fund', CommunityController.fundLoan);

// Chat specific
router.get('/:id/rooms', CommunityController.getChatRooms);
router.post('/:id/rooms', CommunityController.createChatRoom);
router.get('/rooms/:roomId/messages', CommunityController.getChatroomMessages);

export default router;
