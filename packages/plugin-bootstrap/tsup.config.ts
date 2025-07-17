import { defineConfig } from 'tsup';

export default defineConfig({
  entry: ['src/index.ts'],
  outDir: 'dist',
  tsconfig: './tsconfig.build.json', // Use build-specific tsconfig
  sourcemap: true,
  clean: true,
  format: ['esm'], // ESM format
  dts: true,
  external: [
    'dotenv', // Externalize dotenv to prevent bundling
    'fs', // Externalize fs to use Node.js built-in module
    'path', // Externalize other built-ins if necessary
    '@reflink/reflink',
    'https',
    'http',
    'agentkeepalive',
    'zod',
    '@elizaos/core',
    '@elizaos/plugin-sql',
    'uuid',
    'v4',
    // Node.js built-ins
    'node:fs',
    'node:path',
    'node:crypto',
    'node:stream',
    'node:buffer',
    'node:util',
    'node:events',
    // Add other modules you want to externalize
  ],
});
