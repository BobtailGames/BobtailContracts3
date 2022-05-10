// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.

const hre = require('hardhat');
const fs = require('fs-extra');

const { execSync } = require('child_process');

const abiRouter = JSON.parse(fs.readFileSync('./abiTest/Router.json', { encoding: 'utf-8' }));

async function main() {
  await hre.run('compile');
  const accounts = await hre.ethers.getSigners();
  const joeRouter = '0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9';
  // const joeRouter = '0x60aE616a2155Ee3d9A68541Ba4544862310933d4';
  const BBone = await hre.ethers.getContractFactory('BBone');
  const Bobtail = await hre.ethers.getContractFactory('Bobtail');
  const Matchs = await hre.ethers.getContractFactory('MatchManager');
  const Staking = await hre.ethers.getContractFactory('StakingManager');
  const FlappyAVAX = await hre.ethers.getContractFactory('FlappyAVAX');

  const bbone = await BBone.deploy(joeRouter);
  await bbone.deployed();

  const bobtail = await Bobtail.deploy(joeRouter, bbone.address);
  await bobtail.deployed();

  const flappyAVAX = await FlappyAVAX.deploy(
    bbone.address,
  );
  await flappyAVAX.deployed();

  const matchs = await Matchs.deploy(
    accounts[9].address,
    bbone.address,
    flappyAVAX.address,
  );
  await matchs.deployed();

  const staking = await Staking.deploy(
    bbone.address,
    flappyAVAX.address,
  );
  await staking.deployed();

  await flappyAVAX.setStakingManager(staking.address);
  await matchs.setStakingManager(staking.address);
  await bbone.setStakingManager(staking.address);

  await staking.setMatchManager(matchs.address);
  await bbone.setMatchManager(matchs.address);

  await bbone.setBobtailContract(flappyAVAX.address, true);
  await bbone.setBobtailContract(bobtail.address, true);

  /*
  only dev
  */
  const liqToken = hre.ethers.utils.parseEther('1');
  await bbone.approve(joeRouter, liqToken);
  const router = new hre.ethers.Contract(joeRouter, abiRouter, accounts[0]);
  const res = await router.addLiquidityAVAX(
    bbone.address,
    liqToken,
    '0',
    '0',
    accounts[0].address,
    Math.floor(Date.now() / 1000) * 10,
    {
      value: hre.ethers.utils.parseEther('0.005'),
    },
  );
  await res.wait();
  await fs.writeJSON('deployAddress.json', {
    FlappyAVAX: flappyAVAX.address,
    Bobtail: bobtail.address,
    BBone: bbone.address,
    Staking: staking.address,
    Matchs: matchs.address,
  }, {
    spaces: '\t',
  });

  if (!fs.existsSync('./abi/')) {
    await fs.mkdir('./abi/');
  }
  await fs.emptyDir('./abi');
  await fs.emptyDir('../bobtailmarket3/src/abi/');
  await fs.emptyDir('../GameServerNew/src/abi/');
  await fs.copyFile('./artifacts/contracts/BBone.sol/BBone.json', './abi/BBone.json');
  await fs.copyFile('./artifacts/contracts/Bobtail.sol/Bobtail.json', './abi/Bobtail.json');
  await fs.copyFile('./artifacts/contracts/FlappyAVAX.sol/FlappyAVAX.json', './abi/FlappyAVAX.json');
  await fs.copyFile('./artifacts/contracts/StakingManager.sol/StakingManager.json', './abi/StakingManager.json');
  await fs.copyFile('./artifacts/contracts/MatchManager.sol/MatchManager.json', './abi/MatchManager.json');
  execSync('typechain --target ethers-v5 --out-dir abi/types "./abi/**/*.json" --show-stack-traces', {
    cwd: './',
  });
  await fs.copy(
    './abi/types/',
    '../bobtailmarket3/src/abi/',
    { overwrite: true },
  );
  await fs.copy(
    './abi/types/',
    '../GameServerNew/src/abi/',
    { overwrite: true },
  );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
