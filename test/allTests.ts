/* eslint-disable no-undef */
/* eslint-disable no-await-in-loop */
import {
  ethers, run,
} from 'hardhat';
import { expect } from 'chai';
import { Contract } from 'ethers';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';

const advanceBlockAndTime = async (time:number) => {
  await ethers.provider.send('evm_increaseTime', [time]);
  await ethers.provider.send('evm_mine', []);
};
describe('BobTestSuite', () => {
  let flappyAVAX: Contract;
  let bbone: Contract;
  let accounts:SignerWithAddress[];

  describe('Deployment', () => {
    it('Should deploy', async () => {
      await run('compile');
      accounts = await ethers.getSigners();
      const joeRouter = '0x60aE616a2155Ee3d9A68541Ba4544862310933d4';

      const BBone = await ethers.getContractFactory('BBone');
      bbone = await BBone.deploy(joeRouter);
      await bbone.deployed();

      const Bobtail = await ethers.getContractFactory('Bobtail');
      const bobtail = await Bobtail.deploy(joeRouter, bbone.address);
      await bobtail.deployed();

      const FlappyAVAX = await ethers.getContractFactory('FlappyAVAX');
      flappyAVAX = await FlappyAVAX.deploy(
        joeRouter,
        bbone.address,
        accounts[19].address,
        await bbone.joePair(),
      );
      await flappyAVAX.deployed();
    });

    it('Should allow GameChef as minter of BBone', async () => {
      await flappyAVAX.deployed();
      const allowMinter = await bbone.allowMinter(flappyAVAX.address);
      await allowMinter.wait();
    });
  });

  describe('Game: NFT', () => {
    describe('Minting', () => {
      it('Should fail to mint a NFT with invalid quantity', async () => {
        await expect(flappyAVAX.mintWithAvax(accounts[0].address, '0', {
          value: ethers.utils.parseEther('0'),
        })).to.be.revertedWith('Invalid quantity');
        await expect(flappyAVAX.mintWithAvax(accounts[0].address, '51', {
          value: ethers.utils.parseEther('51'),
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
        expect(await lpPair.balanceOf(flappyAVAX.address)).to.be.equal('159999999999999999000');
      });
    });

    describe('Transfer', () => {
      it('Transfer should fail for not revealed token', async () => {
        await expect(flappyAVAX.transferFrom(accounts[0].address, accounts[1].address, '1')).to.be.revertedWith(
          'Token should be revealed',
        );
      });
    });

    describe('Staking', () => {
      it('Should fail for inexistent tokens', async () => {
        await expect(flappyAVAX.stake(['0'])).to.be.revertedWith(
          'ERC721: owner query for nonexistent token',
        );
        await expect(flappyAVAX.stake(['100'])).to.be.revertedWith(
          'ERC721: owner query for nonexistent token',
        );
      });

      it('Should fail if balance=0', async () => {
        const flappyAVAX2 = flappyAVAX.connect(accounts[18]);
        await expect(flappyAVAX2.stake(['1'])).to.be.revertedWith(
          'Not enough balance',
        );
      });

      it('Should fail if sender is not owner of token', async () => {
        const flappyAVAX2 = flappyAVAX.connect(accounts[1]);
        await expect(flappyAVAX2.stake(['1'])).to.be.revertedWith(
          'Sender must be owner',
        );
      });
      it('Should fail for unrevealed token', async () => {
        await expect(flappyAVAX.stake(['1'])).to.be.revertedWith(
          'Token should be revealed',
        );
      });
      it('Should stake token id:1', async () => {
        await advanceBlockAndTime(90);
        await (await flappyAVAX.stake(['1'])).wait();
      });
      it('Should not allow withdraw before 63 seconds had passed', async () => {
        await expect(flappyAVAX.withdraw(['1'], false))
          .to.be.revertedWith(
            'Need 63 sec staked claim/unstake',
          );
      });
      it('Should not allow unstake before 63 seconds had passed', async () => {
        await expect(flappyAVAX.withdraw(['1'], true))
          .to.be.revertedWith(
            'Need 63 sec staked claim/unstake',
          );
      });
      it('Should verify level experience and pending reward: 864 seconds', async () => {
        let deposited = await flappyAVAX.stakedTokensWithInfoOf(accounts[0].address);
        expect(deposited[0].lvl).to.be.equal(1);
        expect(deposited[0].exp).to.be.equal(1);
        expect(deposited[0].pendingReward).to.be.equal(0);
        await advanceBlockAndTime(864);
        deposited = await flappyAVAX.stakedTokensWithInfoOf(accounts[0].address);
        expect(deposited[0].lvl).to.be.equal(1);
        expect(deposited[0].exp).to.be.equal(2);
        expect(ethers.utils.formatEther(deposited[0].pendingReward)).to.be.equal('14.14');
      });
      it('Should withdraw without unstake', async () => {
        expect(await bbone.balanceOf(accounts[0].address)).to.be.equal('0');
        await flappyAVAX.withdraw(['1'], false);
        expect(ethers.utils.formatEther(await bbone.balanceOf(accounts[0].address)))
          .to.be.equal('14.14');
        const deposited = await flappyAVAX.stakedTokensWithInfoOf(accounts[0].address);
        expect(deposited[0].pendingReward).to.be.equal('0');
      });
      it('Should fail to transfer token when staked', async () => {
        await expect(flappyAVAX.transferFrom(accounts[0].address, accounts[1].address, '1'))
          .to.be.revertedWith(
            "Can't transfer staked token",
          );
      });
      it('Should verify level experience and reward with unstake: 100 days', async () => {
        await advanceBlockAndTime(864 * 100 * 100);
        const deposited = await flappyAVAX.stakedTokensWithInfoOf(accounts[0].address);
        expect(ethers.utils.formatEther(deposited[0].pendingReward)).to.be.equal('288000.0');
        await flappyAVAX.withdraw(['1'], true);
        expect(ethers.utils.formatEther(await bbone.balanceOf(accounts[0].address)))
          .to.be.equal('288014.14');
      });
    });
  });

  describe('Game: Matchmarking', () => {
    it('Should fail for inexistent token', async () => {
      await expect(flappyAVAX.joinMatch('0', 'NA')).to.be.revertedWith(
        'Invalid token id',
      );
    });
    it('Should fail for token not owned', async () => {
      await expect(flappyAVAX.joinMatch('2', 'NA')).to.be.revertedWith(
        'Token not owned from sender',
      );
    });
    it('Should fail for token unstaked', async () => {
      await expect(flappyAVAX.joinMatch('1', 'NA')).to.be.revertedWith(
        'Token should be staked',
      );
    });
    it('Should succeed and create a match with Id: 1', async () => {
      await flappyAVAX.stake(['1']);
      await flappyAVAX.joinMatch('1', 'NA');
      const matchInfo = await flappyAVAX.matchForAddress(accounts[0].address);
      expect(matchInfo.inMatch).to.be.equal(true);
      expect(matchInfo.matchId).to.be.equal('1');
    });
    it('Should allow only one match per account', async () => {
      await flappyAVAX.stake(['16']);
      await expect(flappyAVAX.joinMatch('16', 'NA')).to.be.revertedWith(
        'Currently in a match',
      );
    });
    it('Should allow withdraw staking reward', async () => {
      await advanceBlockAndTime(64);
      await flappyAVAX.withdraw(['1'], false);
      expect(ethers.utils.formatEther(await bbone.balanceOf(accounts[0].address)))
        .to.be.equal('288016.14');
    });
    it("Should fail to unstake if match it's active ", async () => {
      await advanceBlockAndTime(64);
      await expect(flappyAVAX.withdraw(['1'], true))
        .to.be.revertedWith("Token in match can't unstake");
    });

    it('Should join match id 1 with 4 accounts', async () => {
      for (let i = 1; i <= 4; i += 1) {
        const flappyAVAX2 = flappyAVAX.connect(accounts[i]);
        const tokenId = i + 1;
        await expect(flappyAVAX2.joinMatch(tokenId, 'NA')).to.be.revertedWith(
          'Token should be staked',
        );
        await flappyAVAX2.stake([tokenId]);
        await flappyAVAX2.joinMatch(tokenId, 'NA');
        const matchInfo = await flappyAVAX.matchForAddress(accounts[i].address);
        expect(matchInfo.inMatch).to.be.equal(true);
        expect(matchInfo.matchId).to.be.equal('1');
      }
    });

    it('Should create match id 2 with 5 accounts', async () => {
      for (let i = 5; i <= 9; i += 1) {
        const flappyAVAX2 = flappyAVAX.connect(accounts[i]);
        const tokenId = i + 1;
        await flappyAVAX2.stake([tokenId]);
        await flappyAVAX2.joinMatch(tokenId, 'NA');
        const matchInfo = await flappyAVAX.matchForAddress(accounts[i].address);
        expect(matchInfo.inMatch).to.be.equal(true);
        expect(matchInfo.matchId).to.be.equal('2');
      }
    });

    it("Shouldn't allow create a new match because all slots are full", async () => {
      const flappyAVAX2 = flappyAVAX.connect(accounts[10]);
      await flappyAVAX2.stake(['11']);
      await expect(flappyAVAX2.joinMatch('11', 'NA')).to.be.revertedWith(
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
      await expect(claimReward(flappyAVAX, accounts[0], ['0'], ['1'])).to.be.revertedWith(
        'Match id invalid',
      );
    });
    it('Should exist match', async () => {
      await expect(claimReward(flappyAVAX, accounts[0], ['3'], ['1'])).to.be.revertedWith(
        "Match isn't started",
      );
    });
    it('Should have a valid rank', async () => {
      await expect(claimReward(flappyAVAX, accounts[0], ['1'], ['0'])).to.be.revertedWith(
        'Rank invalid',
      );
      await expect(claimReward(flappyAVAX, accounts[0], ['1'], ['101'])).to.be.revertedWith(
        'Rank invalid',
      );
    });
    it('Match should not be finished', async () => {
      await expect(claimReward(flappyAVAX, accounts[0], ['1'], ['1'])).to.be.revertedWith(
        'Match is not finished',
      );
    });
    it('Should allow address in match', async () => {
      await advanceBlockAndTime(60 * 60);
      await expect(claimReward(flappyAVAX.connect(accounts[18]), accounts[18], ['1'], ['1'])).to.be.revertedWith(
        'Address not in match',
      );
    });

    it('Should get reward for 5 accounts in match id 1', async () => {
      for (let i = 1; i <= 5; i += 1) {
        await claimReward(flappyAVAX.connect(accounts[i - 1]), accounts[i - 1], ['1'], [i.toString()]);
      }
    });

    it('Should get reward for accounts(4 of 5) in match id 2', async () => {
      await claimReward(flappyAVAX.connect(accounts[5]), accounts[5], ['2'], ['6']);
      await claimReward(flappyAVAX.connect(accounts[6]), accounts[6], ['2'], ['11']);
      await claimReward(flappyAVAX.connect(accounts[7]), accounts[7], ['2'], ['21']);
      await claimReward(flappyAVAX.connect(accounts[8]), accounts[8], ['2'], ['31']);
    });
    it('Should not allow to claim reward for a rank claimed', async () => {
      await expect(claimReward(flappyAVAX.connect(accounts[9]), accounts[9], ['2'], ['31']))
        .to.be.revertedWith('Rank reward has been claimed');
      await claimReward(flappyAVAX.connect(accounts[9]), accounts[9], ['2'], ['41']);
    });
    it('Should create a new match', async () => {
      await flappyAVAX.withdraw(['1'], true);
      await flappyAVAX.stake(['1']);
      await flappyAVAX.joinMatch('1', 'NA');
      let matchInfo = await flappyAVAX.matchForAddress(accounts[0].address);

      expect(matchInfo.matchId).to.be.equal('3');
      expect(matchInfo.finished).to.be.equal(false);
      expect(matchInfo.inMatch).to.be.equal(true);
      await advanceBlockAndTime(60 * 60);
      matchInfo = await flappyAVAX.matchForAddress(accounts[0].address);
      expect(matchInfo.matchId).to.be.equal('3');
      expect(matchInfo.finished).to.be.equal(true);
      expect(matchInfo.inMatch).to.be.equal(true);
      const tokensOf = await flappyAVAX.tokensOf(accounts[0].address);
      expect(tokensOf[0]).to.be.equal('1');
      expect(tokensOf[1]).to.be.equal('16');
      const stakedTokens = await flappyAVAX.stakedTokensOf(accounts[0].address);
      expect(stakedTokens[0]).to.be.equal('1');
      expect(stakedTokens[1]).to.be.equal('16');
      expect((await flappyAVAX.tokensWithInfoOf(accounts[0].address)).length).to.be.equal(2);
    });
    it('Should create server region', async () => {
      await flappyAVAX.setServerRegion('EU', true);
      expect(await flappyAVAX.serverRegions('EU')).to.be.eq(true);
    });
    it('Should fail to join for unknown or disabled server region', async () => {
      await expect(flappyAVAX.joinMatch('1', 'NA1')).to.be.revertedWith(
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
