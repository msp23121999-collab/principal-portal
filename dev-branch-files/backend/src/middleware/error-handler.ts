import { ErrorRequestHandler, RequestHandler } from 'express';

export class HttpError extends Error {
    constructor(
        public readonly statusCode: number,
        message: string,
    ) {
        super(message);
    }
}

export const notFoundHandler: RequestHandler = (_request, response) => {
    response.status(404).json({
        success: false,
        message: 'Route not found',
    });
};

export const errorHandler: ErrorRequestHandler = (
    error,
    _request,
    response,
    _next,
) => {
    console.error(error);
    const statusCode = error instanceof HttpError ? error.statusCode : 500;
    const message = error instanceof HttpError ? error.message : 'Internal server error';
    response.status(statusCode).json({ success: false, message });
};