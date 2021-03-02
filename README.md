# kryptoknights

to get dependencies:
npm install
npm install -g truffle-export-abi

contracts need to be included in "migrations"
deploy.bat to get the contracts compiled and deployed to ganache
truffle-config.js holds parameters for the compile/deploy process
extract_abi.bat will grab the ABI part of the build
the ABI needs to be passed as a string arg to the contract init
