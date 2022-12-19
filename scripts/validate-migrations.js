
const allFiles = require('fs').readdirSync('migrations');

const fileMigrationPrefixes = allFiles.map(str => str.split('_')[0]);

fileMigrationPrefixes.sort((a, b) => {
  return (+a) - (+b);
});

let currentMigration = 1;

fileMigrationPrefixes.forEach((file) => {

  if(!file.includes(`${currentMigration}`)) {
    console.error(`Migration ${currentMigration} is missing`);
    process.exit(1);
  }

  if(file.includes('TBD')) {
    console.error(`Migration ${currentMigration} is TBD`);
    process.exit(1);
  }

  currentMigration++;
});

console.log('All migrations are correct and present.');