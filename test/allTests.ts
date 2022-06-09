/* eslint-disable no-undef */
/* eslint-disable no-await-in-loop */
import {
  ethers, run,
} from 'hardhat';
import { expect } from 'chai';
import { BigNumber, Contract } from 'ethers';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import fs from 'fs';

const sleep = (ms:number) => new Promise((r) => setTimeout(r, ms));

const abiRouter = JSON.parse(fs.readFileSync('./abiTest/Router.json', { encoding: 'utf-8' }));
const abiPair = JSON.parse(fs.readFileSync('./abiTest/Pair.json', { encoding: 'utf-8' }));
const abiFactory = JSON.parse(fs.readFileSync('./abiTest/Factory.json', { encoding: 'utf-8' }));
const advanceBlockAndTime = async (time:number) => {
  await ethers.provider.send('evm_increaseTime', [time]);
  await ethers.provider.send('evm_mine', []);
};
describe('BobTestSuite', () => {
  let flappyAVAX: Contract;
  let staking: Contract;
  let matchs: Contract;
  let bobtail: Contract;

  let bbone: Contract;
  let accounts:SignerWithAddress[];

  const joeRouter = '0x60aE616a2155Ee3d9A68541Ba4544862310933d4';
  let router: Contract;
  const doSwap = async (path:string[], to:string) => {
    const amount = ethers.utils.parseEther('1');
    const amountOut = await router.getAmountsOut(amount, path);
    const expected = amountOut[1];
    const oldBalance = await bobtail.balanceOf(to);
    const swap = await router.swapExactAVAXForTokensSupportingFeeOnTransferTokens(
      '0',
      path,
      to,
      Math.floor(Date.now() / 1000) + 10,
      {
        value: amount,
      },
    );
    await swap.wait();

    const balance = (await bobtail.balanceOf(to)).sub(oldBalance);
    return {
      expected, balance,
    };
  };

  describe('Start', async () => {
    it('Should start', async () => {
      await run('compile');
      accounts = await ethers.getSigners();
      router = new ethers.Contract(joeRouter, abiRouter, accounts[0]);
    });
  });
  describe('Deploy', async () => {
    it('Should deploy BBone', async () => {
      const BBone = await ethers.getContractFactory('BBone');
      bbone = await BBone.deploy(joeRouter);
      await bbone.deployed();
    });
    it('Should deploy Bobtail', async () => {
      const Bobtail = await ethers.getContractFactory('Bobtail');
      bobtail = await Bobtail.deploy(joeRouter, bbone.address);
      await bobtail.deployed();
    });

    it('Should deploy FlappyAVAX', async () => {
      const FlappyAVAX = await ethers.getContractFactory('FlappyAVAX');
      flappyAVAX = await FlappyAVAX.deploy(
        bbone.address,
      );
      await flappyAVAX.deployed();
      // TODO only one time
      // await staking.initializeContract(flappyAVAX.address);
      // await matchs.initializeContract(flappyAVAX.address, staking.address);
    });
    it('Should deploy Matchs', async () => {
      const Matchs = await ethers.getContractFactory('MatchManager');
      matchs = await Matchs.deploy(
        accounts[19].address,
        bbone.address,
        flappyAVAX.address,
      );
      await matchs.deployed();
    });
    it('Should deploy Staking', async () => {
      const Staking = await ethers.getContractFactory('StakingManager');
      staking = await Staking.deploy(
        bbone.address,
        flappyAVAX.address,
      );
      await staking.deployed();
    });
    it('Should finish initial setup', async () => {
      await flappyAVAX.setStakingManager(staking.address);
      await matchs.setStakingManager(staking.address);
      await bbone.setStakingManager(staking.address);
      await staking.setMatchManager(matchs.address);
      await bbone.setMatchManager(matchs.address);
    });
  });

  describe('BBone', async () => {
    describe('Admin', async () => {
      /*
      TODO
      it("Shouldn't allow mint from account without permission", async () => {
        await expect(bbone.mint(accounts[0].address, ethers.utils.parseEther('1')))
          .to.be.revertedWith('Caller is not a minter');
      });
      it('Should allow mint with account permission', async () => {
        const bbone2 = bbone.connect(accounts[18]);
        const res = await bbone2.mint(accounts[18].address, ethers.utils.parseEther('1'));
        await res.wait();
        expect(ethers.utils.formatEther(await bbone2.balanceOf(accounts[18].address)))
          .to.be.equal('1.0');
      });
      */
      it('addLiquidity Should be only called from bobtail contract', async () => {
        await expect(bbone.addLiquidity(ethers.utils.parseEther('1'), '0'))
          .to.be.revertedWith('Caller is not bobtail contract');
      });
      it('Should add bobtailContract with admin account', async () => {
        await bbone.setBobtailContract(flappyAVAX.address, true);
        await bbone.setBobtailContract(bobtail.address, true);
      });
      it("Shouldn't add bobtailContract without admin account", async () => {
        const bbone2 = bbone.connect(accounts[2]);
        await expect(bbone2.setBobtailContract(flappyAVAX.address, true))
          .to.be.revertedWith('Ownable: caller is not the owner');
      });
    });
    it('Should add liquidity', async () => {
      const liqToken = ethers.utils.parseEther('1');
      await bbone.approve(joeRouter, liqToken);
      const res = await router.addLiquidityAVAX(
        bbone.address,
        liqToken,
        '0',
        '0',
        accounts[0].address,
        Math.floor(Date.now() / 1000) * 10,
        {
          value: ethers.utils.parseEther('0.005'),
        },
      );
      await res.wait();
    });
    /*
    /// TODO Check if deposit max allowed staked

     it("Shouldn't allow buying BBone", async () => {
      await expect(doSwap([await router.WAVAX(), bbone.address], accounts[1].address))
        .to.be.revertedWith('Joe: TRANSFER_FAILED');
    });
    it('Should allow transfer of BBone', async () => {
      await bbone.transfer(accounts[2].address, ethers.utils.parseEther('1'));
      expect(ethers.utils.formatEther(await bbone.balanceOf(accounts[2].address))).to.be.equal('1.0');
    });
    it('Should allow selling BBone', async () => {
      const oldBalance = await ethers.provider.getBalance(accounts[2].address);
      const amount = ethers.utils.parseEther('1');
      const account = 5;
      const approve = await bbone.approve(
        router.address,
        amount,
      );
      await approve.wait();
      const swap = await router.swapExactTokensForAVAXSupportingFeeOnTransferTokens(
        amount,
        '0',
        [bbone.address, await router.WAVAX()],
        accounts[2].address,
        Math.floor(Date.now() / 1000) + 10,
      );
      await swap.wait();
      expect(ethers.utils.formatEther(await bbone.balanceOf(accounts[account].address))).to.be.equal('0.0');
      expect(ethers.utils.formatEther(
        (await ethers.provider.getBalance(accounts[2].address)).sub(oldBalance),
      )).to.be.equal('0.009969006090092817');
    });
    */
  });

  describe('Bobtail', () => {
    it('Should add liquidity', async () => {
      const liqToken = ethers.utils.parseEther('10000');
      await bobtail.approve(joeRouter, liqToken);
      const res = await router.addLiquidityAVAX(
        bobtail.address,
        liqToken,
        '0',
        '0',
        accounts[0].address,
        Math.floor(Date.now() / 1000) * 10,
        {
          value: ethers.utils.parseEther('100'),
        },
      );
      await res.wait();
    });
    it('Should swap without SwapAndLiquify ', async () => {
      const resSwap = await doSwap([await router.WAVAX(), bobtail.address], accounts[1].address);
      expect(resSwap.expected).to.be.equal(resSwap.balance);
    });
    it('Should only allow fee percentage between 1% and 9%', async () => {
      await bobtail.setSwapAndLiquifyEnabled(true);
      await expect(bobtail.setFee(100)).to.be.revertedWith('Invalid fee: min 1% max 9%');
      await expect(bobtail.setFee(10)).to.be.revertedWith('Invalid fee: min 1% max 9%');
      await expect(bobtail.setFee(0)).to.be.revertedWith('Invalid fee: min 1% max 9%');
    });
    it('Should take 2% fee only on swap', async () => {
      await bobtail.setFee(2);
      expect(await bobtail.feePercentage()).to.be.equal(2);
      const resSwap = await doSwap([await router.WAVAX(), bobtail.address], accounts[1].address);
      expect(resSwap.expected.mul(100).div(resSwap.balance).sub(100)).to.be.equal(2);
      await bobtail.transfer(accounts[2].address, ethers.utils.parseEther('1'));
      expect(ethers.utils.formatEther(await bobtail.balanceOf(accounts[2].address))).to.be.equal('1.0');
    });
    it('Should have level and exp', async () => {
      const account2 = accounts[3].address;
      await bobtail.transfer(account2, ethers.utils.parseUnits('1'));
      await advanceBlockAndTime(449);
      let holdingDuration2 = await bobtail.levelExpDataFor(account2);
      expect(holdingDuration2.holdingDuration).to.be.equal('44');
      expect(holdingDuration2.experience).to.be.equal('44');
      expect(holdingDuration2.level).to.be.equal('0');

      await advanceBlockAndTime(1);
      holdingDuration2 = await bobtail.levelExpDataFor(account2);

      expect(holdingDuration2.holdingDuration).to.be.equal('45');
      expect(holdingDuration2.experience).to.be.equal('45');
      expect(holdingDuration2.level).to.be.equal('1');

      await advanceBlockAndTime(4441444);
      holdingDuration2 = await bobtail.levelExpDataFor(account2);
      expect(holdingDuration2.holdingDuration).to.be.equal('444189');
      expect(holdingDuration2.experience).to.be.equal('444189');
      expect(holdingDuration2.level).to.be.equal('99');
      await advanceBlockAndTime(3000);
      holdingDuration2 = await bobtail.levelExpDataFor(account2);
      expect(holdingDuration2.holdingDuration).to.be.equal('444489');
      expect(holdingDuration2.experience).to.be.equal('444489');
      expect(holdingDuration2.level).to.be.equal('100');
    });
  });

  describe('FlappyAVAX:NFT', () => {
    it('XXXX', async () => {
      return;
      for (let i = 0; i < 4; i += 1) {
        await (await flappyAVAX.mintWithAvax(accounts[0].address, '252', {
          value: ethers.utils.parseEther('252'),
        })).wait();
      }

      await advanceBlockAndTime(60 * 10);
      function sliceIntoChunks(arr:any[], chunkSize:number) {
        const res = [];
        for (let i = 0; i < arr.length; i += chunkSize) {
          const chunk = arr.slice(i, i + chunkSize);
          res.push(chunk);
        }
        return res;
      }

      const items = sliceIntoChunks(await flappyAVAX.tokensOf(accounts[0].address), 100);

      for (let i = 0; i < 11; i += 1) {
        console.log(i);
        await flappyAVAX.doRevealFor(items[i]);
      }
      // const items2 = sliceIntoChunks(items[3], 126);
      // await flappyAVAX.doRevealFor(items[3]);
      //  console.log('E');
      //  await flappyAVAX.doRevealFor(items2[1]);

      console.log('reveal');
      for (let i = 1; i < 5; i += 1) {
        const resTmp = await flappyAVAX.tokenInfoExtended(i.toString());
        console.log(`${resTmp.id}, ${resTmp.skin}, ${resTmp.face}, ${resTmp.rarity}`);
      }
    });
    describe('Minting', () => {
      it('Should fail to mint a NFT with invalid quantity', async () => {
        await expect(flappyAVAX.mintWithAvax(accounts[0].address, '0', {
          value: ethers.utils.parseEther('0'),
        })).to.be.revertedWith('Invalid quantity');
        await expect(flappyAVAX.mintWithAvax(accounts[0].address, '11', {
          value: ethers.utils.parseEther('11'),
        })).to.be.revertedWith('Invalid quantity');
      });

      it('Should fail to mint a NFT with quantity and value wrong', async () => {
        await expect(flappyAVAX.mintWithAvax(accounts[0].address, '2', {
          value: ethers.utils.parseEther('1'),
        })).to.be.revertedWith('Incorrect amount of AVAX sent');
      });

      it('Should mint 15 NFT and check balance of LP tokens', async () => {
        for (let i = 0; i < 15; i += 1) {
          await (await flappyAVAX.mintWithAvax(accounts[i].address, '1', {
            value: ethers.utils.parseEther('1'),
          })).wait();
          expect(await flappyAVAX.balanceOf(accounts[i].address)).to.be.equal('1');
        }
        await (await flappyAVAX.mintWithAvax(accounts[0].address, '1', {
          value: ethers.utils.parseEther('1'),
        })).wait();
        const lpPair = await ethers.getContractAt('IJoePair', await bbone.joePair());
        expect(await lpPair.balanceOf(bbone.address)).to.be.equal('101139952070833699501');
      });
      describe('Transfer', () => {
        it('Transfer should fail for not revealed token', async () => {
          await expect(flappyAVAX.transferFrom(accounts[0].address, accounts[1].address, '1')).to.be.revertedWith(
            'Token should be revealed',
          );
        });
      });

      describe('Update level and exp', () => {
        it('Should only be called by StakingManager', async () => {
          await expect(flappyAVAX.writeLevelAndExp('1')).to.be.revertedWith(
            'Sender should be stakingManager',
          );
        });
      });
    });
    describe('Staking', () => {
      it('Should fail for inexistent tokens', async () => {
        await expect(staking.stake(['0'])).to.be.revertedWith(
          'ERC721: owner query for nonexistent token',
        );
        await expect(staking.stake(['100'])).to.be.revertedWith(
          'ERC721: owner query for nonexistent token',
        );
      });

      /*

      it('Should fail if balance=0', async () => {
        const staking2 = staking.connect(accounts[18]);
        await expect(staking2.stake(['1'])).to.be.revertedWith(
          'Not enough balance',
        );
      });

      */
      it('Should fail if sender is not owner of token', async () => {
        const staking2 = staking.connect(accounts[1]);
        await expect(staking2.stake(['1'])).to.be.revertedWith(
          'Sender must be owner',
        );
      });
      it('Should fail for unrevealed token', async () => {
        await expect(staking.stake(['1'])).to.be.revertedWith(
          'Token should be revealed',
        );
      });
      it('Should reveal token id:1', async () => {
        await advanceBlockAndTime(90);
        await (await flappyAVAX.doRevealFor(['1'])).wait();
      });
      it('Should stake token id:1', async () => {
        await (await staking.stake(['1'])).wait();
      });
      it('Should not allow withdraw before 63 seconds had passed', async () => {
        await expect(staking.withdrawAndOrClaim(['1'], false))
          .to.be.revertedWith(
            'Need 63 sec staked claim/unstake',
          );
      });
      it('Should not allow unstake if sender is not owner', async () => {
        const staking2 = staking.connect(accounts[2]);
        await expect(staking2.withdrawAndOrClaim(['1'], true))
          .to.be.revertedWith(
            'Sender must be owner',
          );
      });
      it('Should verify level experience and pending reward: 864 seconds', async () => {
        let deposited = await staking.stakedTokensWithInfoOf(accounts[0].address);

        expect(deposited[0].lvl).to.be.equal(1);
        expect(deposited[0].exp).to.be.equal(1);
        expect(deposited[0].pendingReward).to.be.equal(0);
        await advanceBlockAndTime(864);
        deposited = await staking.stakedTokensWithInfoOf(accounts[0].address);
        expect(deposited[0].lvl).to.be.equal(1);
        expect(deposited[0].exp).to.be.equal(2);
        expect(ethers.utils.formatEther(deposited[0].pendingReward)).to.be.equal('14.14');
      });
      it('Should withdraw without unstake', async () => {
        const oldBalance = await bbone.balanceOf(accounts[0].address);
        await staking.withdrawAndOrClaim(['1'], false);
        expect(ethers.utils.formatEther((await bbone.balanceOf(accounts[0].address))
          .sub(oldBalance)))
          .to.be.equal('14.14');
        const deposited = await staking.stakedTokensWithInfoOf(accounts[0].address);
        expect(deposited[0].pendingReward).to.be.equal('0');
      });
      it('Should fail to transfer token when staked', async () => {
        await expect(flappyAVAX.transferFrom(accounts[0].address, accounts[1].address, '1'))
          .to.be.revertedWith(
            "Can't transfer staked token",
          );
      });
      it('Should verify level experience and reward with unstake: 100 days', async () => {
        const oldBalance = await bbone.balanceOf(accounts[0].address);
        await advanceBlockAndTime(864 * 100 * 100);
        const deposited = await staking.stakedTokensWithInfoOf(accounts[0].address);
        expect(deposited[0].lvl).to.be.equal(100);
        expect(deposited[0].exp).to.be.equal(100);
        expect(ethers.utils.formatEther(deposited[0].pendingReward)).to.be.equal('288000.0');
        await staking.withdrawAndOrClaim(['1'], true);
        expect(ethers.utils.formatEther((await bbone.balanceOf(accounts[0].address))
          .sub(oldBalance)))
          .to.be.equal('288000.0');
      });
    });

    describe('Matchmarking', () => {
      return;
      it('Should fail for inexistent token', async () => {
        await matchs.setMaxPlayersPerMatch('5');
      });

      it('Should fail for inexistent token', async () => {
        await expect(matchs.joinMatch('0', 'NA')).to.be.revertedWith(
          'Invalid token id',
        );
      });
      it('Should fail for token not owned', async () => {
        await expect(matchs.joinMatch('2', 'NA')).to.be.revertedWith(
          'Token not owned from sender',
        );
      });
      it('Should fail for token unstaked', async () => {
        await expect(matchs.joinMatch('1', 'NA')).to.be.revertedWith(
          'Token should be staked',
        );
      });
      it('Should succeed and create a match with Id: 1', async () => {
        await staking.stake(['1']);
        await matchs.joinMatch('1', 'NA');
        const matchInfo = await matchs.matchForAddress(accounts[0].address);
        expect(matchInfo.inMatch).to.be.equal(true);
        expect(matchInfo.matchId).to.be.equal('1');
      });
      it('Should allow only one match per account', async () => {
        await staking.stake(['16']);
        await expect(matchs.joinMatch('16', 'NA')).to.be.revertedWith(
          'Currently in a match',
        );
      });
      it('Should allow withdraw staking reward', async () => {
        const oldBalance = await bbone.balanceOf(accounts[0].address);

        await advanceBlockAndTime(64);
        await staking.withdrawAndOrClaim(['1'], false);
        expect(ethers.utils.formatEther((await bbone.balanceOf(accounts[0].address))
          .sub(oldBalance)))
          .to.be.equal('2.0');
      });
      it("Should fail to unstake if match it's active ", async () => {
        await advanceBlockAndTime(64);
        await expect(staking.withdrawAndOrClaim(['1'], true))
          .to.be.revertedWith("Token in match can't unstake");
      });

      it('Should join match id 1 with 4 accounts', async () => {
        for (let i = 1; i <= 4; i += 1) {
          const staking2 = staking.connect(accounts[i]);
          const matchs2 = matchs.connect(accounts[i]);
          const tokenId = i + 1;
          await expect(matchs2.joinMatch(tokenId, 'NA')).to.be.revertedWith(
            'Token should be staked',
          );
          await staking2.stake([tokenId]);
          await matchs2.joinMatch(tokenId, 'NA');
          const matchInfo = await matchs.matchForAddress(accounts[i].address);
          expect(matchInfo.inMatch).to.be.equal(true);
          expect(matchInfo.matchId).to.be.equal('1');
        }
      });

      it('Should create match id 2 with 5 accounts', async () => {
        for (let i = 5; i <= 9; i += 1) {
          const staking2 = staking.connect(accounts[i]);
          const matchs2 = matchs.connect(accounts[i]);
          const tokenId = i + 1;
          await staking2.stake([tokenId]);
          await matchs2.joinMatch(tokenId, 'NA');
          const matchInfo = await matchs.matchForAddress(accounts[i].address);
          expect(matchInfo.inMatch).to.be.equal(true);
          expect(matchInfo.matchId).to.be.equal('2');
        }
      });

      it("Shouldn't allow create a new match because all slots are full", async () => {
        const staking2 = staking.connect(accounts[10]);
        await staking2.stake(['11']);
        const matchs2 = matchs.connect(accounts[10]);
        await expect(matchs2.joinMatch('11', 'NA')).to.be.revertedWith(
          'No match available',
        );
      });
      const claimReward = async (
        contract:Contract,
        account:SignerWithAddress,
        matchIds:string[],
        ranks:string[],
      ) => {
        const payloadHash = ethers.utils.keccak256(ethers.utils.defaultAbiCoder.encode(
          ['uint256[]', 'uint256[]', 'address', 'address'],
          [matchIds, ranks, account.address, contract.address],
        ));
        const signature = await accounts[19].signMessage(ethers.utils.arrayify(payloadHash));
        const sig = ethers.utils.splitSignature(signature);
        const lastBalance = await bbone.balanceOf(account.address);
        await (await contract.claimReward(matchIds, ranks, sig.r, sig.s, sig.v)).wait();
        const newBalance = ethers.utils.formatEther(
          (await bbone.balanceOf(account.address)).sub(lastBalance),
        );
        if (ranks.length === 1) {
          switch (Number(ranks[0])) {
            case 1:
              expect(newBalance === '74.14', 'Expected balance 74.14');
              break;
            case 2:
              expect(newBalance === '43.81', 'Expected balance 43.81');
              break;
            case 3:
              expect(newBalance === '23.59', 'Expected balance 23.59');
              break;
            case 4:
              expect(newBalance === '16.85', 'Expected balance 16.85');
              break;
            case 5:
              expect(newBalance === '10.11', 'Expected balance 10.11');
              break;
            case 6:
              expect(newBalance === '8.425', 'Expected balance 8.425');
              break;
            case 11:
              expect(newBalance === '6.74', 'Expected balance 6.74');
              break;
            case 21:
              expect(newBalance === '3.37', 'Expected balance 3.37');
              break;
            case 31:
              expect(newBalance === '1.685', 'Expected balance 1.685');
              break;
            case 41:
              expect(newBalance === '0.8425', 'Expected balance 0.8425');
              break;
            default:
              throw new Error('Not implemented');
          }
        }
      };
      it('Should have invalid id', async () => {
        await expect(claimReward(matchs, accounts[0], ['0'], ['1'])).to.be.revertedWith(
          'Match id invalid',
        );
      });
      it('Should exist match', async () => {
        await expect(claimReward(matchs, accounts[0], ['3'], ['1'])).to.be.revertedWith(
          "Match isn't started",
        );
      });
      it('Should have a valid rank', async () => {
        await expect(claimReward(matchs, accounts[0], ['1'], ['0'])).to.be.revertedWith(
          'Rank invalid',
        );
        await expect(claimReward(matchs, accounts[0], ['1'], ['101'])).to.be.revertedWith(
          'Rank invalid',
        );
      });
      it('Match should not be finished', async () => {
        await expect(claimReward(matchs, accounts[0], ['1'], ['1'])).to.be.revertedWith(
          'Match is not finished',
        );
      });
      it('Should allow address in match', async () => {
        await advanceBlockAndTime(60 * 60);
        await expect(claimReward(matchs.connect(accounts[18]), accounts[18], ['1'], ['1'])).to.be.revertedWith(
          'Address not in match',
        );
      });
      it('Should get reward for 5 accounts in match id 1', async () => {
        for (let i = 1; i <= 5; i += 1) {
          await claimReward(matchs.connect(accounts[i - 1]), accounts[i - 1], ['1'], [i.toString()]);
        }
      });

      it('Should get reward for accounts(4 of 5) in match id 2', async () => {
        await claimReward(matchs.connect(accounts[5]), accounts[5], ['2'], ['6']);
        await claimReward(matchs.connect(accounts[6]), accounts[6], ['2'], ['11']);
        await claimReward(matchs.connect(accounts[7]), accounts[7], ['2'], ['21']);
        await claimReward(matchs.connect(accounts[8]), accounts[8], ['2'], ['31']);
      });
      it('Should not allow to claim reward for a rank claimed', async () => {
        await expect(claimReward(matchs.connect(accounts[9]), accounts[9], ['2'], ['31']))
          .to.be.revertedWith('Rank reward has been claimed');
        await claimReward(matchs.connect(accounts[9]), accounts[9], ['2'], ['41']);
      });

      it('Should create a new match', async () => {
        await staking.withdrawAndOrClaim(['1'], true);
        await staking.stake(['1']);
        await matchs.joinMatch('1', 'NA');
        let matchInfo = await matchs.matchForAddress(accounts[0].address);

        expect(matchInfo.matchId).to.be.equal('3');
        expect(matchInfo.finished).to.be.equal(false);
        expect(matchInfo.inMatch).to.be.equal(true);
        await advanceBlockAndTime(60 * 60);
        matchInfo = await matchs.matchForAddress(accounts[0].address);
        expect(matchInfo.matchId).to.be.equal('3');
        expect(matchInfo.finished).to.be.equal(true);
        expect(matchInfo.inMatch).to.be.equal(true);
        const tokensOf = await flappyAVAX.tokensOf(accounts[0].address);
        expect(tokensOf[0]).to.be.equal('1');
        expect(tokensOf[1]).to.be.equal('16');
        const stakedTokens = await staking.stakedTokensOf(accounts[0].address);
        expect(stakedTokens[0]).to.be.equal('1');
        expect(stakedTokens[1]).to.be.equal('16');
        expect((await flappyAVAX.tokensWithInfoOf(accounts[0].address)).length).to.be.equal(2);
      });
      it('Should create server region', async () => {
        await matchs.setServerRegion('EU', true);
        expect(await matchs.serverRegions('EU')).to.be.eq(true);
      });
      it('Should fail to join for unknown or disabled server region', async () => {
        await expect(matchs.joinMatch('1', 'NA1')).to.be.revertedWith(
          'Invalid region',
        );
      });
    /*
    it('Should create a new match', async () => {
      await flappyAVAX.joinMatch('1', 'NA');
    });
    */
    // TODO regions
    });
  });
});
