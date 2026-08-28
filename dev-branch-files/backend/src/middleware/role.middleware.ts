import { Response, NextFunction } from 'express';
import { AuthRequest } from './auth.middleware';
import { sendError } from '../utils/response';
import { UserRole } from '../constants/roles';

export function requireRole(...allowedRoles: (UserRole | string)[]) {
  return (req: AuthRequest, res: Response, next: NextFunction) => {
    if (!req.user) {
      return sendError(res, 'Authentication required', 401);
    }

    const userRole = req.user.role?.toUpperCase();
    const isAllowed = allowedRoles.some((role) => role.toUpperCase() === userRole || userRole === UserRole.SUPER_ADMIN);

    if (!isAllowed) {
      return sendError(res, `Forbidden: Role ${req.user.role} does not have access`, 403);
    }

    return next();
  };
}
