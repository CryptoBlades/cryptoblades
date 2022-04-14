const {upgradeProxy} = require('@openzeppelin/truffle-upgrades');

const Treasury = artifacts.require('Treasury');

module.exports = async function (deployer, network) {
  const treasury = await upgradeProxy(Treasury.address, Treasury, {deployer});
  //https://gateway.ipfs.io/ipfs/QmZpqpqBooKp1cFNi2LcbdcE1FBtE44mr8wTQpwP2LWVuC/seedify.png
  if (network === 'bscmainnet' || network === 'bscmainnet-fork') {
    await treasury.setProjectLogo(0, 'https://gateway.ipfs.io/ipfs/QmZpqpqBooKp1cFNi2LcbdcE1FBtE44mr8wTQpwP2LWVuC/oasis.png');
    await treasury.setProjectDetails(0, 'The OASIS Metaverse welcomes all nature-loving blockchain gamers to create, own, play, earn and interact with like-minded natives in its virtual world of lush greeneries and natural beauty.');
    await treasury.setProjectWebsite(0, 'https://projectoasis.io/');

    await treasury.setProjectLogo(1, 'https://gateway.ipfs.io/ipfs/QmZpqpqBooKp1cFNi2LcbdcE1FBtE44mr8wTQpwP2LWVuC/oasis.png');
    await treasury.setProjectDetails(1, 'The OASIS Metaverse welcomes all nature-loving blockchain gamers to create, own, play, earn and interact with like-minded natives in its virtual world of lush greeneries and natural beauty.');
    await treasury.setProjectWebsite(1, 'https://projectoasis.io/');

    await treasury.setProjectLogo(2, 'https://gateway.ipfs.io/ipfs/QmZpqpqBooKp1cFNi2LcbdcE1FBtE44mr8wTQpwP2LWVuC/seedify.png');
    await treasury.setProjectDetails(2, 'At Seedify, we provide curated Initial Game Offerings (IGOs) through our platform, supporting quality blockchain games reach crowdsourced funding, as well as helping them with community building and marketing; while providing an avenue for our community to get the tokens of upcoming blockchain games before they get listed on exchanges. We expect that blockchain gaming will bring millions of new users to blockchain, while creating many new jobs, financial benefits, as well as increasing the adoption rate of blockchain drastically. If you want to take part in Initial Game Offerings (IGOs) through Seedify, and get tokens of the games you like before they get listed on exchanges, here you can find out more on how to participate in IGOs and join the revolution!');
    await treasury.setProjectWebsite(2, 'https://launchpad.seedify.fund/');

    await treasury.setProjectLogo(3, 'https://gateway.ipfs.io/ipfs/QmZpqpqBooKp1cFNi2LcbdcE1FBtE44mr8wTQpwP2LWVuC/SKILL.png');
    await treasury.setProjectDetails(3, 'SKILL is the native token of the CryptoBlades ecosystem, used for crafting character and weapon NFTs, trading on our NFT marketplace, utilizing our Bridge, or even purchasing merchandise. As CryptoBlades continues to grow in product offerings, SKILL token will grow with it!');
    await treasury.setProjectWebsite(3, 'https://www.cryptoblades.io/');

    await treasury.setProjectLogo(4, 'https://gateway.ipfs.io/ipfs/QmZpqpqBooKp1cFNi2LcbdcE1FBtE44mr8wTQpwP2LWVuC/KING.png');
    await treasury.setProjectDetails(4, 'KING is the native token for CryptoBlades Kingdoms, our community focused kingdom management game. Additionally, KING is the backing token for Omnus, our interactive 3D metaverse that resides within a world made up of our Land NFTs.');
    await treasury.setProjectWebsite(4, 'https://cryptobladeskingdoms.io/');
    await treasury.setProjectNote(4, 'This token has a 1% fee upon claiming');

    await treasury.setProjectLogo(5, 'https://gateway.ipfs.io/ipfs/QmZpqpqBooKp1cFNi2LcbdcE1FBtE44mr8wTQpwP2LWVuC/bithotel.png');
    await treasury.setProjectDetails(5, 'Bit Hotel is a Social-first Play 2 Earn NFT Gaming Metaverse, in which users will be able to earn Bit Hotel tokens and participate in governance or acquire native NFTs. The Bit Hotel  NFTs have in-game usability such as characters, hotel rooms, and accessories and have each their own perks and use-cases. These NFTs can be traded on the open market on NFTtrade and on bithotel.io. Users will be able to meet and chat with other players, compete on our various ever-changing mini-games, and collect rare NFTs. Every game has winners and losers, thus there will be a global leaderboard that keeps track. Frequent events will be hosted in which players can meet and mingle. A metaverse would not be complete without governance, Bit Hotel will have a decentralized voting model that determines future content, this will be based on staking allocations and in-game achievement.');
    await treasury.setProjectWebsite(5, 'https://bithotel.io/');

    await treasury.setProjectLogo(6, 'https://gateway.ipfs.io/ipfs/QmZpqpqBooKp1cFNi2LcbdcE1FBtE44mr8wTQpwP2LWVuC/altura.png');
    await treasury.setProjectDetails(6, 'Altura provides the tools and infrastructure for developers to create and integrate Smart NFTs in their video games and applications. With Altura, developers can program dynamic functionality in their NFTs.');
    await treasury.setProjectWebsite(6, 'https://www.alturanft.com/');

    await treasury.setProjectLogo(7, 'https://gateway.ipfs.io/ipfs/QmZpqpqBooKp1cFNi2LcbdcE1FBtE44mr8wTQpwP2LWVuC/SKILL.png');
    await treasury.setProjectDetails(7, 'SKILL is the native token of the CryptoBlades ecosystem, used for crafting character and weapon NFTs, trading on our NFT marketplace, utilizing our Bridge, or even purchasing merchandise. As CryptoBlades continues to grow in product offerings, SKILL token will grow with it!');
    await treasury.setProjectWebsite(7, 'https://www.cryptoblades.io/');

    await treasury.setProjectLogo(8, 'https://gateway.ipfs.io/ipfs/QmZpqpqBooKp1cFNi2LcbdcE1FBtE44mr8wTQpwP2LWVuC/ageoftanks.png');
    await treasury.setProjectDetails(8, 'The First Military Strategic Metaverse where gamers build & command their fleet of tanks to storm the battlefields in their quest to conquer Earth Zero!');
    await treasury.setProjectWebsite(8, 'https://linktr.ee/AgeofTanksNFT');

    await treasury.setProjectLogo(9, 'https://gateway.ipfs.io/ipfs/QmZpqpqBooKp1cFNi2LcbdcE1FBtE44mr8wTQpwP2LWVuC/ageoftanks.png');
    await treasury.setProjectDetails(9, 'The First Military Strategic Metaverse where gamers build & command their fleet of tanks to storm the battlefields in their quest to conquer Earth Zero!');
    await treasury.setProjectWebsite(9, 'https://linktr.ee/AgeofTanksNFT');

    await treasury.setProjectLogo(10, 'https://gateway.ipfs.io/ipfs/QmZpqpqBooKp1cFNi2LcbdcE1FBtE44mr8wTQpwP2LWVuC/cakemonster.png');
    await treasury.setProjectDetails(10, 'Cake Monster is a ultra-deflationary, automated dividend yield, and meme token. It offers a multitude of unique DeFi features aimed at building a flexible and multifaceted reward system for all participants without compromising the sustainability or security of the protocol ecosystem.');
    await treasury.setProjectWebsite(10, 'https://cake.monster/');
    await treasury.setProjectNote(10, 'This token has a 5% fee (2.5% fee, 2.5% burned) upon claiming');

    await treasury.setProjectLogo(11, 'https://gateway.ipfs.io/ipfs/QmZpqpqBooKp1cFNi2LcbdcE1FBtE44mr8wTQpwP2LWVuC/SKILL.png');
    await treasury.setProjectDetails(11, 'SKILL is the native token of the CryptoBlades ecosystem, used for crafting character and weapon NFTs, trading on our NFT marketplace, utilizing our Bridge, or even purchasing merchandise. As CryptoBlades continues to grow in product offerings, SKILL token will grow with it!');
    await treasury.setProjectWebsite(11, 'https://www.cryptoblades.io/');

    await treasury.setProjectLogo(12, 'https://gateway.ipfs.io/ipfs/QmZpqpqBooKp1cFNi2LcbdcE1FBtE44mr8wTQpwP2LWVuC/spintop.png');
    await treasury.setProjectDetails(12, 'Spintop\'s vision is to create a single platform that unites the scattered blockchain gaming world. Designed as a dynamic GameFi ecosystem where the community of players, investors and game developers can discover and play games, trade their tokens, and share NFT’s, Spintop has the tools you need to experience blockchain gaming to its fullest.');
    await treasury.setProjectWebsite(12, 'https://spintop.network/');

    await treasury.setProjectLogo(13, 'https://gateway.ipfs.io/ipfs/QmZpqpqBooKp1cFNi2LcbdcE1FBtE44mr8wTQpwP2LWVuC/hololoot.png');
    await treasury.setProjectDetails(13, 'Hololoot introduces the world\'s first AR NFT Generator, Marketplace, and Metaverse designed for widespread adoption. Our goal is to bring the 3D assets of the Metaverse into reality through our proprietary AR tech stack.');
    await treasury.setProjectWebsite(13, 'https://www.hololoot.io/');
    await treasury.setProjectNote(13, 'This token has a 3% fee upon claiming');
  } else if (network === 'hecomainnet' || network === 'avaxmainnet' || network === 'avaxmainnet-fork' || network === 'okexmainnet') {
    await treasury.setProjectLogo(0, 'https://gateway.ipfs.io/ipfs/QmZpqpqBooKp1cFNi2LcbdcE1FBtE44mr8wTQpwP2LWVuC/SKILL.png');
    await treasury.setProjectDetails(0, 'SKILL is the native token of the CryptoBlades ecosystem, used for crafting character and weapon NFTs, trading on our NFT marketplace, utilizing our Bridge, or even purchasing merchandise. As CryptoBlades continues to grow in product offerings, SKILL token will grow with it!');
    await treasury.setProjectWebsite(0, 'https://www.cryptoblades.io/');

    await treasury.setProjectLogo(1, 'https://gateway.ipfs.io/ipfs/QmZpqpqBooKp1cFNi2LcbdcE1FBtE44mr8wTQpwP2LWVuC/SKILL.png');
    await treasury.setProjectDetails(1, 'SKILL is the native token of the CryptoBlades ecosystem, used for crafting character and weapon NFTs, trading on our NFT marketplace, utilizing our Bridge, or even purchasing merchandise. As CryptoBlades continues to grow in product offerings, SKILL token will grow with it!');
    await treasury.setProjectWebsite(1, 'https://www.cryptoblades.io/');

    await treasury.setProjectLogo(2, 'https://gateway.ipfs.io/ipfs/QmZpqpqBooKp1cFNi2LcbdcE1FBtE44mr8wTQpwP2LWVuC/SKILL.png');
    await treasury.setProjectDetails(2, 'SKILL is the native token of the CryptoBlades ecosystem, used for crafting character and weapon NFTs, trading on our NFT marketplace, utilizing our Bridge, or even purchasing merchandise. As CryptoBlades continues to grow in product offerings, SKILL token will grow with it!');
    await treasury.setProjectWebsite(2, 'https://www.cryptoblades.io/');
  } else if (network === 'polygonmainnet') {
    await treasury.setProjectLogo(0, 'https://gateway.ipfs.io/ipfs/QmZpqpqBooKp1cFNi2LcbdcE1FBtE44mr8wTQpwP2LWVuC/cryptomeda.png');
    await treasury.setProjectDetails(0, 'Cryptomeda is a gaming ecosystem that uniquely blends NFT collectibles, DEFI mechanics, and iconic crypto characters into an exciting fantasy world. Players of all experience levels can explore Cryptomeda and find various opportunities to earn.');
    await treasury.setProjectWebsite(0, 'https://cryptomeda.tech/');

    await treasury.setProjectLogo(1, 'https://gateway.ipfs.io/ipfs/QmZpqpqBooKp1cFNi2LcbdcE1FBtE44mr8wTQpwP2LWVuC/SKILL.png');
    await treasury.setProjectDetails(1, 'SKILL is the native token of the CryptoBlades ecosystem, used for crafting character and weapon NFTs, trading on our NFT marketplace, utilizing our Bridge, or even purchasing merchandise. As CryptoBlades continues to grow in product offerings, SKILL token will grow with it!');
    await treasury.setProjectWebsite(1, 'https://www.cryptoblades.io/');

    await treasury.setProjectLogo(2, 'https://gateway.ipfs.io/ipfs/QmZpqpqBooKp1cFNi2LcbdcE1FBtE44mr8wTQpwP2LWVuC/tryhards.png');
    await treasury.setProjectDetails(2, 'TryHards is a play-to-earn metaverse in which players can engage in thrilling top-down PvP and PvE battles using collectible NFT characters and weapons. Players can earn  crystals to upgrade their NFTs and increase their earnings.');
    await treasury.setProjectWebsite(2, 'https://tryhards.io/');

    await treasury.setProjectLogo(3, 'https://gateway.ipfs.io/ipfs/QmZpqpqBooKp1cFNi2LcbdcE1FBtE44mr8wTQpwP2LWVuC/SKILL.png');
    await treasury.setProjectDetails(3, 'SKILL is the native token of the CryptoBlades ecosystem, used for crafting character and weapon NFTs, trading on our NFT marketplace, utilizing our Bridge, or even purchasing merchandise. As CryptoBlades continues to grow in product offerings, SKILL token will grow with it!');
    await treasury.setProjectWebsite(3, 'https://www.cryptoblades.io/');

    await treasury.setProjectLogo(4, 'https://gateway.ipfs.io/ipfs/QmZpqpqBooKp1cFNi2LcbdcE1FBtE44mr8wTQpwP2LWVuC/SKILL.png');
    await treasury.setProjectDetails(4, 'SKILL is the native token of the CryptoBlades ecosystem, used for crafting character and weapon NFTs, trading on our NFT marketplace, utilizing our Bridge, or even purchasing merchandise. As CryptoBlades continues to grow in product offerings, SKILL token will grow with it!');
    await treasury.setProjectWebsite(4, 'https://www.cryptoblades.io/');

    await treasury.setProjectLogo(5, 'https://gateway.ipfs.io/ipfs/QmZpqpqBooKp1cFNi2LcbdcE1FBtE44mr8wTQpwP2LWVuC/novacreed.png');
    await treasury.setProjectDetails(5, 'Nova Creed is an immersive, play-to-earn gaming universe built on the Polygon network. Set in a distant region of space, the Nova Creed is home to six species of aliens with unique roles and attributes. With your Nova Creed aliens you can build and pilot your own spaceships, play and compete against other owners, and create or trade in a player-owned economy.');
    await treasury.setProjectWebsite(5, 'https://novacreed.com/');
  }
};
