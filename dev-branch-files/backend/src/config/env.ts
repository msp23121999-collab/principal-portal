import 'dotenv/config';

export type AppConfig = {
    port: number;
    database: {
        host: string;
        port: number;
        name: string;
        user: string;
        password: string;
        ssl: boolean;
        poolMax: number;
    };
    jwtSecret: string;
    corsOrigins: string[];
};

const numberFromEnv = (name: string, fallback: number): number => {
    const value = process.env[name];
    if (!value) return fallback;
    const parsed = Number(value);
    if (!Number.isInteger(parsed) || parsed <= 0) {
        throw new Error(`${name} must be a positive integer`);
    }
    return parsed;
};

export const config: AppConfig = {
    port: numberFromEnv('PORT', 3000),
    database: {
        host: process.env.DATABASE_HOST ?? '',
        port: numberFromEnv('DATABASE_PORT', 5432),
        name: process.env.DATABASE_NAME ?? '',
        user: process.env.DATABASE_USER ?? '',
        password: process.env.DATABASE_PASSWORD ?? '',
        ssl: (process.env.DATABASE_SSL ?? 'false').toLowerCase() === 'true',
        poolMax: numberFromEnv('DATABASE_POOL_MAX', 20),
    },
    jwtSecret: process.env.JWT_SECRET || 'super_secret_production_jwt_key_cams_2026_ksrce_secure',
    corsOrigins: (process.env.CORS_ORIGINS ?? 'http://localhost:5000,http://127.0.0.1:5000')
        .split(',')
        .map((origin) => origin.trim())
        .filter(Boolean),
};

export const hasDatabaseConfig = (): boolean =>
    Boolean(
        config.database.host &&
        config.database.name &&
        config.database.user &&
        config.database.password,
    );