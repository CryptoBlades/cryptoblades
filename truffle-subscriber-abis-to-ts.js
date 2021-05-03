const shell = require('shelljs');

module.exports = {
  handlers: {
    "compile:succeed": [
      function() {
        shell.exec('node scripts/generate-ts-from-abis.js');
      }
    ]
  }
};
