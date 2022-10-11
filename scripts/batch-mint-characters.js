const fs = require("fs");
const path = require('path');
const {parse} = require("csv-parse");
const retry = require('async-retry');
const dataPath = path.join(__dirname, '/data/batch-mint-characters.csv');
const Characters = artifacts.require("Characters");

const charactersAddress = "0x3982F5ebF6D3691F52d92F745856B811B6E50628"; // BNB - 0xc6f252c2CdD4087e30608A35c022ce490B58179b

// constant inputs
const seed = 0; // 0, we don't need randomization
const tokenID = 0; // 0 for next id
const version = 1; // 1 for gen2
//-----------------------------------

// possible, but not needed currently
const xp = 0;
const reputation = 0;
//-----------------------------------

const data = readFile();

module.exports = async (callback) => {
    console.log("Script started");
    const characters = await Characters.at(charactersAddress);
    console.log("Characters address:", characters.address);
    for (let i = 0; i < data.length; i++) {
        const mintData = data[i];
        try {
            await retry(async () => {
                await characters.customMint(mintData.receiver, mintData.level, mintData.trait, mintData.bonusPower, seed, tokenID, version, xp, reputation);
            });
            console.log("Character minted:", mintData);
        } catch (e) {
            console.error(e);
            console.log("Minting failed:", mintData);
            console.log("Failed index:", i);
            break;
        }
    }
    console.log("Script finished");
    callback();
}

function readFile() {
    const fileData = [];
    fs.createReadStream(dataPath)
        .pipe(parse({
            delimiter: ",", columns: true, ltrim: true,
        }))
        .on("data", function (row) {
            // 👇 push the object row into the array
            fileData.push({receiver: row.receiver, level: +row.level, trait: +row.trait, bonusPower: +row.bonusPower});
        })
        .on("error", function (error) {
            console.log(error.message);
        })
        .on("end", function () {
            // 👇 log the result array
            console.log("parsed csv data:");
            console.log(fileData);
        });
    return fileData;
}