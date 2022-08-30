module.exports = {
  chainWebpack: config => {
    config.plugin('fork-ts-checker').tap(args => {
      args[0].typescript.memoryLimit = 4096;
      return args;
    });
  },
};