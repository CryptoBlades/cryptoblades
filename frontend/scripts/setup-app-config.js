const fs = require('fs-extra');
const fetch = require('node-fetch');
const APP_CONFIG_URL = 'https://config.cryptoblades.io';
const APP_CONFIG = 'app-config';

const setupAppConfigTask = async () => {
  fs.ensureDirSync('./');
  let appConfig;

  try {
    appConfig = await fetch(`${APP_CONFIG_URL}/${APP_CONFIG}.json`);
    appConfig = await appConfig.text();
  } catch(error) {
    console.error(error);
  }


  await fs.writeFile('./app-config.json', appConfig);
};

setupAppConfigTask();
