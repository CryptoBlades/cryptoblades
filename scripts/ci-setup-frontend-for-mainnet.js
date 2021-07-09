const shell = require('shelljs');
const path = require('path');

shell.pushd(path.join(__dirname, '../frontend'));

if(shell.test('-f', '.env.production.local') && shell.cat('.env.production.local').toString() !== shell.cat('.env.mainnet').toString()) {
    console.log('ERROR: .env.production.local already exists and is not equal to .env.mainnet.');
    console.log('Delete .env.production.local and try again.');
    shell.exit(1);
}

shell.cp('.env.mainnet', '.env.production.local');

shell.popd();
