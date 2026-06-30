import pluginVue from 'eslint-plugin-vue'
import tseslint from 'typescript-eslint'
import eslintConfigPrettier from 'eslint-config-prettier'

export default tseslint.config(
  { ignores: ['dist/', 'node_modules/', '../html/'] },

  // TypeScript rules (parser applied globally — overridden for .vue below)
  ...tseslint.configs.recommended,

  // Vue parser for .vue files (files-scoped, wins over global TS parser above)
  ...pluginVue.configs['flat/recommended'],

  // Register TS parser as inner parser inside vue-eslint-parser
  {
    files: ['**/*.vue'],
    languageOptions: {
      parserOptions: {
        parser: tseslint.parser,
        sourceType: 'module',
      },
    },
  },

  // Disable ESLint rules that conflict with Prettier formatting
  eslintConfigPrettier,

  {
    rules: {
      'vue/multi-word-component-names': 'off',
      '@typescript-eslint/no-explicit-any': 'warn',
      '@typescript-eslint/no-unused-vars': [
        'error',
        { argsIgnorePattern: '^_', varsIgnorePattern: '^_' },
      ],
    },
  },

  // Vite/Vue framework declaration files use `{}` intentionally in type shims
  {
    files: ['**/*.d.ts'],
    rules: {
      '@typescript-eslint/no-empty-object-type': 'off',
    },
  },
)
