import { readFile, writeFile } from 'node:fs/promises';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const projectRoot = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const envPath = resolve(projectRoot, '.env');
let envContents;

try {
  envContents = await readFile(envPath, 'utf8');
} catch (error) {
  if (error.code === 'ENOENT') {
    throw new Error('Falta el archivo .env. Cópialo desde .env.example.');
  }
  throw error;
}

const variables = Object.fromEntries(
  envContents
    .split(/\r?\n/)
    .map((line) => line.trim())
    .filter((line) => line && !line.startsWith('#'))
    .map((line) => {
      const separator = line.indexOf('=');
      if (separator < 1) {
        throw new Error(`Línea inválida en .env: ${line}`);
      }

      const name = line.slice(0, separator).trim();
      let value = line.slice(separator + 1).trim();
      if (
        (value.startsWith('"') && value.endsWith('"')) ||
        (value.startsWith("'") && value.endsWith("'"))
      ) {
        value = value.slice(1, -1);
      }
      return [name, value];
    }),
);

const apiUrl = variables.API_URL;
const stripePublicKey = variables.STRIPE_PUBLIC_KEY;

if (!apiUrl) {
  throw new Error('Define API_URL en .env.');
}
if (!/^pk_(test|live)_/.test(stripePublicKey ?? '')) {
  throw new Error('Define una clave publicable de Stripe en .env.');
}

const runtimeConfig = {
  apiUrl,
  stripePublicKey,
};

await writeFile(
  resolve(projectRoot, 'src/assets/runtime-config.js'),
  `window.__orgEventosConfig = ${JSON.stringify(runtimeConfig)};\n`,
  'utf8',
);
