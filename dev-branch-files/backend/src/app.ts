import cors from 'cors';
import express from 'express';
import helmet from 'helmet';
import { config } from './config/env';
import { closeDatabase } from './database/database';
import { errorHandler, notFoundHandler } from './middleware/error-handler';
import { healthRouter } from './routes/health';

export const app = express();

app.disable('x-powered-by');
app.use(helmet());
app.use(
    cors({
        origin: config.corsOrigins,
    }),
);
app.use(express.json({ limit: '1mb' }));

app.use('/api/health', healthRouter);
app.use(notFoundHandler);
app.use(errorHandler);

if (require.main === module) {
    const server = app.listen(config.port, () => {
        console.log(`KSRCE ERP API listening on port ${config.port}`);
    });

    const shutdown = async (signal: string) => {
        console.log(`Received ${signal}; shutting down`);
        server.close(async () => {
            await closeDatabase();
            process.exit(0);
        });
    };

    process.once('SIGINT', () => void shutdown('SIGINT'));
    process.once('SIGTERM', () => void shutdown('SIGTERM'));
}