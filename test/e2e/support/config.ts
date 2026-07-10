export const config = {
  appUrl: process.env.APP_URL || (process.env.KUBERNETES_SERVICE_HOST ? 'http://onthewing-svc' : 'http://localhost:8080'),
};
