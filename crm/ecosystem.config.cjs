// PM2 Ecosystem Configuration for Snake Dragon CRM
// Usage: pm2 start ecosystem.config.cjs
// Docs: https://pm2.keymetrics.io/docs/usage/application-declaration/

module.exports = {
    apps: [
        {
            name: 'snake-dragon-api',
            script: 'server/index.ts',
            interpreter: 'node',
            interpreter_args: '--import tsx/esm',
            cwd: '/var/www/snake-dragon',
            instances: 1,
            autorestart: true,
            watch: false,
            max_memory_restart: '512M',
            env: {
                NODE_ENV: 'production',
                API_PORT: 5000,
            },
            env_file: '.env',
            error_file: 'logs/api-error.log',
            out_file: 'logs/api-out.log',
            log_date_format: 'YYYY-MM-DD HH:mm:ss',
        },
    ],
};
