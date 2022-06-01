const fs = require('fs-extra');
const fetch = require('node-fetch');
const APP_CONFIG_URL = 'https://config.cryptoblades.io';
const APP_CONFIG = 'app-config';

const setupAppConfigTask = async () => {
  fs.ensureDirSync('./');

  const appConfig = await fetch(`${APP_CONFIG_URL}/${APP_CONFIG}.json`).then((res) => res.text());

  await fs.writeFile('./app-config.json', appConfig);
};

setupAppConfigTask();
