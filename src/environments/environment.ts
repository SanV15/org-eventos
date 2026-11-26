declare global {
  interface Window {
    __orgEventosConfig?: {
      apiUrl: string;
      stripePublicKey: string;
    };
  }
}

function getRuntimeConfig() {
  const config = window.__orgEventosConfig;
  if (!config) {
    throw new Error(
      'No se encontró la configuración. Ejecuta npm start o npm run build.',
    );
  }
  return config;
}

export const environment = {
  production: false,
  get apiUrl() {
    return getRuntimeConfig().apiUrl;
  },
  get stripePublicKey() {
    return getRuntimeConfig().stripePublicKey;
  },
};