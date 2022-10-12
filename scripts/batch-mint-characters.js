const fs = require("fs");
const path = require('path');
const {parse} = require("csv-parse");
const retry = require('async-retry');
const Characters = artifacts.require("Characters");
const dataPath = path.join(__dirname, '/data/batch-mint-characters.csv');

// constant inputs
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
    const characters = await Characters.deployed();
    console.log("Characters address:", characters.address);
    for (let i = 0; i < data.length; i++) {
        const mintData = data[i];
        try {
            const seed = Math.floor(Math.random() * Number.MAX_SAFE_INTEGER);
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