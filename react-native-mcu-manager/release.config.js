module.exports = {
  branches: [{ name: 'main' }],
  plugins: [
    '@semantic-release/commit-analyzer',
    '@semantic-release/npm',
    '@semantic-release/release-notes-generator',
    '@semantic-release/github',
  ],
};
