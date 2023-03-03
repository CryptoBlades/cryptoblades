module.exports = {
  chainWebpack: config => {
    config.plugin('fork-ts-checker').tap(args => {
      args[0].memoryLimit = 1024;
      return args;
    });
  }
};