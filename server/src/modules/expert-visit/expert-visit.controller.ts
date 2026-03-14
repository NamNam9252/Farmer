import { Request, Response } from 'express';
import { ExpertVisitService } from './expert-visit.service.js';
import { createVisitRequestSchema, updateVisitStatusSchema } from '../../schema/expert-visit.schema.js';

const expertVisitService = new ExpertVisitService();

// ==========================================
// FARMER ENDPOINTS
// ==========================================

export const requestVisit = async (req: Request, res: Response): Promise<void> => {
  try {
    const userId = (req as any).user?.id;
    if (!userId) {
      res.status(401).json({ success: false, message: 'Unauthorized / अनाधिकृत' });
      return;
    }

    const validation = createVisitRequestSchema.safeParse(req.body);
    if (!validation.success) {
      res.status(400).json({ 
        success: false, 
        message: validation.error.issues[0].message 
      });
      return;
    }

    const visitRequest = await expertVisitService.requestVisit(userId, validation.data);

    res.status(201).json({
      success: true,
      message: 'Expert visit requested successfully / विशेषज्ञ के दौरे का अनुरोध सफलतापूर्वक किया गया',
      data: visitRequest
    });
  } catch (error: any) {
    console.error('Error requesting expert visit:', error);
    res.status(error.message.includes('not found') ? 404 : 500).json({ 
      success: false, 
      message: error.message || 'Internal server error' 
    });
  }
};

export const getMyRequests = async (req: Request, res: Response): Promise<void> => {
  try {
    const userId = (req as any).user?.id;
    if (!userId) {
      res.status(401).json({ success: false, message: 'Unauthorized / अनाधिकृत' });
      return;
    }

    const requests = await expertVisitService.getFarmerRequests(userId);
    res.status(200).json({ success: true, data: requests });
  } catch (error: any) {
    console.error('Error fetching farmer requests:', error);
    res.status(error.message.includes('not found') ? 404 : 500).json({ 
      success: false, 
      message: error.message || 'Internal server error' 
    });
  }
};

// ==========================================
// EXPERT ENDPOINTS
// ==========================================

export const getAvailableRequests = async (req: Request, res: Response): Promise<void> => {
  try {
    const requests = await expertVisitService.getAvailableRequests();
    res.status(200).json({ success: true, data: requests });
  } catch (error: any) {
    console.error('Error fetching available requests:', error);
    res.status(500).json({ success: false, message: 'Internal server error' });
  }
};

export const acceptRequest = async (req: Request, res: Response): Promise<void> => {
  try {
    const userId = (req as any).user?.id;
    if (!userId) {
      res.status(401).json({ success: false, message: 'Unauthorized' });
      return;
    }

    const visitId = req.params.id as string;
    const acceptedVisit = await expertVisitService.acceptVisit(userId, visitId);

    res.status(200).json({ success: true, data: acceptedVisit });
  } catch (error: any) {
    console.error('Error accepting visit request:', error);
    res.status(error.message.includes('not found') ? 404 : (error.message.includes('available') ? 400 : 500)).json({ 
      success: false, 
      message: error.message || 'Internal server error' 
    });
  }
};

export const updateVisitStatus = async (req: Request, res: Response): Promise<void> => {
  try {
    const userId = (req as any).user?.id;
    if (!userId) {
      res.status(401).json({ success: false, message: 'Unauthorized' });
      return;
    }

    const visitId = req.params.id as string;
    const validation = updateVisitStatusSchema.safeParse(req.body);
    if (!validation.success) {
      res.status(400).json({ 
        success: false, 
        message: validation.error.issues[0].message 
      });
      return;
    }

    const updatedVisit = await expertVisitService.updateVisit(userId, visitId, validation.data);

    res.status(200).json({ success: true, data: updatedVisit });
  } catch (error: any) {
    console.error('Error updating visit status:', error);
    let status = 500;
    if (error.message.includes('not found')) status = 404;
    else if (error.message.includes('authorized')) status = 403;

    res.status(status).json({ 
      success: false, 
      message: error.message || 'Internal server error' 
    });
  }
};
