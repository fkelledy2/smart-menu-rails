import js from '@eslint/js';
import importPlugin from 'eslint-plugin-import';
import prettierPlugin from 'eslint-plugin-prettier';
import prettierConfig from 'eslint-config-prettier';

export default [
  js.configs.recommended,
  prettierConfig,
  {
    files: ['app/javascript/**/*.js'],
    languageOptions: {
      ecmaVersion: 'latest',
      sourceType: 'module',
      globals: {
        console: 'readonly',
        window: 'readonly',
        document: 'readonly',
        navigator: 'readonly',
        localStorage: 'readonly',
        sessionStorage: 'readonly',
        fetch: 'readonly',
        FormData: 'readonly',
        URLSearchParams: 'readonly',
        URL: 'readonly',
        Event: 'readonly',
        CustomEvent: 'readonly',
        setTimeout: 'readonly',
        setInterval: 'readonly',
        clearTimeout: 'readonly',
        clearInterval: 'readonly',
        Promise: 'readonly',
        Turbo: 'readonly',
        Rails: 'readonly',
        $: 'readonly',
        jQuery: 'readonly',
        bootstrap: 'readonly',
        Tabulator: 'readonly',
        TomSelect: 'readonly',
        Trix: 'readonly',
        performance: 'readonly',
        Blob: 'readonly',
        File: 'readonly',
        FileReader: 'readonly',
        Image: 'readonly',
        process: 'readonly',
        QRCodeStyling: 'readonly',
        pako: 'readonly',
        Stripe: 'readonly',
        history: 'readonly',
        location: 'readonly',
        XMLHttpRequest: 'readonly',
        MutationObserver: 'readonly',
        PerformanceObserver: 'readonly',
        IntersectionObserver: 'readonly',
        ResizeObserver: 'readonly',
        // Browser dialog APIs
        alert: 'readonly',
        confirm: 'readonly',
        // DOM APIs
        Element: 'readonly',
        DataTransfer: 'readonly',
        CSS: 'readonly',
        // Web APIs
        Notification: 'readonly',
        requestAnimationFrame: 'readonly',
        cancelAnimationFrame: 'readonly',
        btoa: 'readonly',
        atob: 'readonly',
        MediaRecorder: 'readonly',
        // Third-party libraries
        Sortable: 'readonly',
        google: 'readonly',
        Spotify: 'readonly',
        gtag: 'readonly',
        // Stimulus framework (legacy stimulus-loading.js)
        Stimulus: 'readonly',
        Application: 'readonly',
        definitionsFromContext: 'readonly',
        require: 'readonly',
      },
    },
    plugins: {
      import: importPlugin,
      prettier: prettierPlugin,
    },
    rules: {
      'prettier/prettier': 'warn',
      'no-unused-vars': [
        'warn',
        {
          argsIgnorePattern: '^_',
          varsIgnorePattern: '^_',
        },
      ],
      'no-console': [
        'warn',
        {
          allow: ['warn', 'error'],
        },
      ],
      'no-empty': ['error', { allowEmptyCatch: true }],
      'no-var': 'error',
      'prefer-const': 'warn',
      eqeqeq: [
        'error',
        'always',
        {
          null: 'ignore',
        },
      ],
    },
  },
  {
    files: ['app/javascript/pwa/service-worker.js'],
    languageOptions: {
      globals: {
        self: 'readonly',
        caches: 'readonly',
        Response: 'readonly',
        clients: 'readonly',
        skipWaiting: 'readonly',
        importScripts: 'readonly',
      },
    },
  },
  {
    ignores: [
      'node_modules/',
      'app/assets/builds/',
      'public/',
      'vendor/',
      'coverage/',
      'tmp/',
      '**/*.min.js',
      'esbuild.config.mjs',
    ],
  },
];
