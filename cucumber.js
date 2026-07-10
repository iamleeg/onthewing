module.exports = {
  default: {
    formatOptions: {
      snippet: 'async-await',
    },
    paths: ['test/e2e/features/**/*.feature'],
    require: ['test/e2e/steps/**/*.ts', 'test/e2e/support/**/*.ts'],
    requireModule: ['ts-node/register'],
  },
};
