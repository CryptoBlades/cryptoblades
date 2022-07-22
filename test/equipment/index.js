const { expectEvent, time } = require('@openzeppelin/test-helpers');

const Promos = artifacts.require('Promos');
const Characters = artifacts.require('Characters');
const Weapons = artifacts.require('Weapons');
const Shields = artifacts.require('Shields');
const EquipmentManager = artifacts.require('EquipmentManager');

const helpers = require("./helper");
const experienceTable = require('../../experience-table')

contract("EquipmentManager", (accounts) => {
    let promos, characters, weapons, shields, manager;
    let charArray = [], weapArray = [], shieldArray = [];
    let seed = 123456

    it("should initialize game", async () => {
        promos = await Promos.new();
        characters = await Characters.new();
        weapons = await Weapons.new();
        shields = await Shields.new();
        manager = await EquipmentManager.new();

        await promos.initialize();
        await characters.initialize();
        await weapons.initialize();
        await shields.initialize();
        await manager.initialize(characters.address, weapons.address, shields.address);

        await promos.grantRole(await promos.GAME_ADMIN(), characters.address);
        await characters.grantRole(await characters.GAME_ADMIN(), accounts[0]);
        await characters.grantRole(await characters.NO_OWNED_LIMIT(), accounts[1]);
        await characters.grantRole(await characters.NO_OWNED_LIMIT(), accounts[2]);
        await weapons.grantRole(await weapons.GAME_ADMIN(), accounts[0]);
        await weapons.grantRole(await weapons.GAME_ADMIN(), manager.address);
        await shields.grantRole(await shields.GAME_ADMIN(), accounts[0]);
        await shields.grantRole(await shields.GAME_ADMIN(), manager.address);
        await manager.grantRole(await manager.GAME_ADMIN(), accounts[0]);

        await weapons.migrateTo_e55d8c5();
        await weapons.migrateTo_aa9da90();
        await weapons.migrateTo_951a020();
        await weapons.migrateTo_surprise(promos.address);

        await characters.migrateTo_1ee400a(experienceTable.values);
        await characters.migrateTo_951a020();
        await characters.migrateTo_ef994e2(promos.address);
        await characters.migrateTo_b627f23();

        await shields.migrateTo_surprise(promos.address);
        
        await manager.setSlotMaxCount(weapons.address, 1);
        await manager.setSlotMaxCount(shields.address, 1);

    });

    it("should mint nfts", async () => {
        charArray.push( await helpers.createCharacter(accounts[0], seed, {
            characters,
        }));
        await helpers.levelUpTo(charArray[0], 41, { characters });

        let i = 0
        while(i < 3) {
            weapArray.push( await helpers.createWeapon(accounts[0], seed + 50, 0, {
                weapons,
            }));
            i++;
        }

        shieldArray.push( await helpers.createShield(accounts[0], seed + 100, 0, {
            shields,
        }));
    })

    it("should equip a weapon and a shield", async () => {
        await manager.setEquipment(weapons.address, charArray[0], weapArray[0]);
        console.log('Weapons:', (await manager.characterEquipmentIds(weapons.address, charArray[0])).map(i => bnToStr(i)));
        console.log('Power:', bnToStr(await manager.charPower(charArray[0])));

        await manager.setEquipment(shields.address, charArray[0], shieldArray[0]);
        console.log('Shield:', (await manager.characterEquipmentIds(shields.address, charArray[0])).map(i => bnToStr(i)));
        console.log('Power:', bnToStr(await manager.charPower(charArray[0])));

        await manager.removeEquipment(weapons.address, charArray[0], weapArray[0])
        console.log('Weapons:', (await manager.characterEquipmentIds(weapons.address, charArray[0])).map(i => bnToStr(i)));
        console.log('Power:', bnToStr(await manager.charPower(charArray[0])));
    })
})

function bnToStr(value){
    return BigInt(value).toString();
}