import { Response } from 'express';

export interface ApiResponse<T = any> {
  success: boolean;
  message?: string;
  data?: T;
  error?: string;
  count?: number;
}

export function sendSuccess<T>(res: Response, data: T, message?: string, statusCode = 200, count?: number): Response {
  const payload: ApiResponse<T> = {
    success: true,
    ...(message && { message }),
    ...(count !== undefined && { count }),
    data,
  };
  return res.status(statusCode).json(payload);
}

export function sendError(res: Response, error: string, statusCode = 400, message?: string): Response {
  const payload: ApiResponse = {
    success: false,
    error,
    ...(message && { message }),
  };
  return res.status(statusCode).json(payload);
}
