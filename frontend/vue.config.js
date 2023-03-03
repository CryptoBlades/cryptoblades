module.exports = {
  lintOnSave: false,
  chainWebpack: config => {
    config.plugin('fork-ts-checker').tap(args => {
      args[0].memoryLimit = 2000;
      return args;
    });
  }
};