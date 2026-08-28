import { Router } from 'express';
import { query } from '../database/database';
import { hasDatabaseConfig } from '../config/env';

export const healthRouter = Router();

healthRouter.get('/', (_request, response) => {
    response.json({
        success: true,
        status: 'ok',
    });
});

healthRouter.get('/database', async (_request, response) => {
    if (!hasDatabaseConfig()) {
        response.status(503).json({
            success: false,
            database: 'not_configured',
            message: 'Database credentials are not configured on the API server',
        });
        return;
    }

    try {
        const result = await query<{ now: string }>('SELECT NOW() AS now');
        response.json({
            success: true,
            database: 'connected',
            time: result.rows[0].now,
        });
    } catch (error) {
        console.error('Database health check failed', error);
        response.status(503).json({
            success: false,
            database: 'unavailable',
            message: 'Database connection failed',
        });
    }
});