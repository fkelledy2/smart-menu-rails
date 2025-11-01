import { defineConfig } from 'vitest/config';
import path from 'path';

export default defineConfig({
  test: {
    globals: true,
    environment: 'jsdom',
    setupFiles: ['./test/javascript/setup.js'],
    coverage: {
      provider: 'v8',
      reporter: ['text', 'json', 'html'],
      exclude: [
        'node_modules/',
        'test/',
        '**/*.config.js',
        '**/bundles/*.js',
        'esbuild.config.mjs'
      ],
      thresholds: {
        lines: 80,
        functions: 80,
        branches: 80,
        statements: 80
      }
    },
    // Increase timeout for slower tests
    testTimeout: 10000
  },
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './app/javascript'),
      '@components': path.resolve(__dirname, './app/javascript/components'),
      '@modules': path.resolve(__dirname, './app/javascript/modules'),
      '@utils': path.resolve(__dirname, './app/javascript/utils'),
      '@config': path.resolve(__dirname, './app/javascript/config'),
      '@channels': path.resolve(__dirname, './app/javascript/channels'),
      '@controllers': path.resolve(__dirname, './app/javascript/controllers')
    }
  }
});
