const { onRequest } = require('firebase-functions/v2/https');
const app = require('./server');

// Export Express app as 2nd Gen Firebase Function (runs on Google Cloud Run)
exports.api = onRequest(
  {
    region: 'us-central1',
    cors: true,
    invoker: 'public',
  },
  app
);
