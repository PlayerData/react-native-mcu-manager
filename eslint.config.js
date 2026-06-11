const js = require('@eslint/js');
const tsPlugin = require('@typescript-eslint/eslint-plugin');
const globals = require('globals');

module.exports = [
  js.configs.recommended,
  ...tsPlugin.configs['flat/recommended'],
  {
    files: ['**/*.config.js', '**/*.config.cjs', '**/.*.js'],
    languageOptions: {
      globals: globals.node,
    },
  },
  {
    ignores: ['react-native-mcu-manager/build/**'],
  },
];
