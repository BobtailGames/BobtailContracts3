const Bobtail = artifacts.require('Bobtail');
const BBone = artifacts.require('BBone');
const GameChef = artifacts.require('GameChef');
const FlappyAVAXGame = artifacts.require('FlappyAVAXGame');
const FlappyAVAX = artifacts.require('FlappyAVAX');
const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));
const fs = require('fs-extra');

const abiRouter = fs.readJsonSync('./abi/Router.json');
const abiPair = fs.readJsonSync('./abi/Pair.json');
const abiFactory = fs.readJsonSync('./abi/Factory.json');

const address = fs.readJsonSync(
  './../pancakeganache/pancake-swap-periphery/address.json',
);

const router = new web3.eth.Contract(abiRouter, address.PancakeRouter);

const advanceTime = async (numOfSeconds) => new Promise((resolve, reject) => {
  web3.currentProvider.send(
    {
      method: 'evm_increaseTime',
      params: [numOfSeconds],
      id: new Date().getTime(),
    },
    (error, result) => {
      if (error) {
        return reject(error);
      }
      return resolve(result);
    },
  );
});
const advanceBlock = () => new Promise((resolve, reject) => {
  web3.currentProvider.send(
    {
      jsonrpc: '2.0',
      method: 'evm_mine',
      id: new Date().getTime(),
    },
    (err, result) => {
      if (err) {
        return reject(err);
      }
      const newBlockHash = web3.eth.getBlock('latest').hash;
      return resolve(newBlockHash);
    },
  );
});

const expectError = async (promise, expected) => {
  try {
    await promise;
    throw null;
  } catch (e) {
    assert(
      e !== null && e !== undefined,
      'Expected an error but did not get one',
    );
    assert(
      e.toString().includes(expected),
      `Error expected: ${expected} || ${e}`,
    );
  }
};
const advanceTimeAndBlock = async (seconds) => {
  await advanceTime(seconds);
  await advanceBlock();
};

const addLiquidity = async (accounts, contract, liqEth, liqToken) => {
  await contract.approve.sendTransaction(address.PancakeRouter, liqToken, {
    from: accounts[0],
  });
  const req = await router.methods.addLiquidityAVAX(
    contract.address,
    liqToken,
    '0',
    '0',
    accounts[0],
    Math.floor(Date.now() / 1000) * 10,
  );
  await req.send({
    from: accounts[0],
    gas: await req.estimateGas({
      from: accounts[0],
      value: liqEth,
    }),
    value: liqEth,
  });
};

contract('All', (accounts) => {
  it('Bobtail: should put liquidity', async () => {
    const bobtail = await Bobtail.deployed();
    const lpToken = new web3.eth.Contract(
      abiPair,
      await bobtail.joePair.call(),
    );

    await addLiquidity(
      accounts,
      bobtail,
      web3.utils.toWei('10'),
      web3.utils.toWei('10000000'),
    );
    assert(
      web3.utils.fromWei(
        await lpToken.methods.balanceOf(accounts[0]).call(),
      ) === '9999.999999999999999',
      'Bobtail LP balance should be 9999.999999999999999',
    );
  });

  it('BBone: should put liquidity', async () => {
    return;
    const bbone = await BBone.deployed();
    const lpToken2 = new web3.eth.Contract(abiPair, await bbone.joePair.call());
    let balance = (await bbone.balanceOf(accounts[0])).toString();
    await addLiquidity(accounts, bbone, web3.utils.toWei('10'), balance);
    balance = (await bbone.balanceOf(accounts[0])).toString();
    assert(balance === '0', 'Bbone balance should be 0');
    assert(
      web3.utils.fromWei(
        await lpToken2.methods.balanceOf(accounts[0]).call(),
      ) === '18973.665961010275990993',
      'BBone LP balance should be 18973.665961010275990993',
    );
  });

  it('FlappyAVAX: should mint a NFT', async () => {
    return;
    const flappyAvax = await FlappyAVAX.deployed();
    const bbone = await BBone.deployed();

    let quantity;

    for (let i = 0; i < 3; i++) {
      switch (i) {
        case 0:
          quantity = '0'; // Should fail
          break;
        case 1:
          quantity = '51'; // Should fail
          break;
        case 2:
          quantity = '1'; // Should fail
          break;
      }
      await expectError(
        flappyAvax.mintWithAvax.sendTransaction(accounts[0], quantity, {
          from: accounts[0],
          value: web3.utils.toWei(i === 2 ? '100' : quantity),
        }),
        i === 2 ? 'Incorrect amount of AVAX sent' : 'Invalid quantity',
      );
    }
    await flappyAvax.mintWithAvax.sendTransaction(accounts[0], '15', {
      from: accounts[0],
      value: web3.utils.toWei('15'),
    });
    const lpToken2 = new web3.eth.Contract(abiPair, await bbone.joePair.call());

    console.log(
      web3.utils.fromWei(
        await lpToken2.methods.balanceOf(FlappyAVAX.address).call(),
      ),
    );
    return;
    assert(
      web3.utils.fromWei(
        await lpToken2.methods.balanceOf(FlappyAVAX.address).call(),
      ) === '8131.571126147261139425',
      'BBone LP balance of  FlappyAVAX should be 8131.571126147261139425',
    );
    assert(
      (await flappyAvax.balanceOf(accounts[0])).toString() === '15',
      'NFT Balance should be 15',
    );
  });

  it('should stake and earn', async () => {
    return;
    const bbone = await BBone.deployed();
    const flappyAvax = await FlappyAVAX.deployed();
    await expectError(
      flappyAvax.deposit(['0']),
      'owner query for nonexistent token',
    );

    await expectError(flappyAvax.deposit(['1']), 'Token should be revealed');

    advanceTimeAndBlock(90);

    await flappyAvax.transferFrom(accounts[0], accounts[1], '14');

    await expectError(
      flappyAvax.deposit(['2'], {
        from: accounts[1],
      }),
      'Sender must be owner',
    );
    await flappyAvax.deposit(['1']);
    await flappyAvax.deposit(['13']);
    await expectError(
      flappyAvax.transferFrom(accounts[0], accounts[1], '1'),
      "Can't transfer staked token",
    );

    let deposited = await flappyAvax.depositedTokensWithInfoOf(accounts[0]);

    await advanceTimeAndBlock(864);
    deposited = await flappyAvax.depositedTokensWithInfoOf(accounts[0]);

    assert(
      web3.utils.fromWei(deposited[0].pendingReward) === '14.14',
      'Wrong pendingReward should be 14.14',
    );
    await flappyAvax.withdraw(['1'], false);
    const oldBalance = await bbone.balanceOf(accounts[0]);

    assert(
      web3.utils.fromWei(oldBalance) === '14.14',
      'Wrong bbone balance should be 14.14',
    );

    await advanceTime(864 * 100 * 100);
    await advanceBlock();
    deposited = await flappyAvax.depositedTokensWithInfoOf(accounts[0]);
    await flappyAvax.withdraw(['1'], true);
    deposited = (await bbone.balanceOf(accounts[0])).sub(oldBalance);
    assert(
      web3.utils.fromWei(deposited) === '288000',
      'Wrong bbone balance should be 288000',
    );
  });

  it('should stake and play', async () => {
    return;
    const bbone = await BBone.deployed();
    const bobtail = await Bobtail.deployed();
    const flappyAvax = await FlappyAVAX.deployed();
    const flappyAvaxGame = await FlappyAVAXGame.deployed();
    const gameChef = await GameChef.deployed();
    await expectError(
      flappyAvax.matchmarking.sendTransaction('0', {
        from: accounts[0],
      }),
      'Invalid token id',
    );
    await expectError(
      flappyAvax.matchmarking.sendTransaction('2', {
        from: accounts[0],
      }),
      'Token should be staked.',
    );
    await expectError(
      flappyAvax.matchmarking.sendTransaction('1', {
        from: accounts[1],
      }),
      'Token not owned from sender',
    );

    await flappyAvax.deposit.sendTransaction(['1', '12'], {
      from: accounts[0],
    });
    await flappyAvax.matchmarking.sendTransaction('1', {
      from: accounts[0],
    });
    await expectError(
      flappyAvax.matchmarking.sendTransaction('12', {
        from: accounts[0],
      }),
      'Currently in a match you can only participate in one simultaneously',
    );
    await advanceTimeAndBlock(64);
    // Get staking reward
    await flappyAvax.withdraw(['1'], false);
    await advanceTimeAndBlock(64);
    // Unstake
    await expectError(
      flappyAvax.withdraw(['1'], true),
      "Token in match can't unstake",
    );
    // Transfer 10 tokens to other accounts and try to join a match
    for (let i = 1; i <= 10; i++) {
      await flappyAvax.transferFrom.sendTransaction(
        accounts[0],
        accounts[i],
        (i + 1).toString(),
        {
          from: accounts[0],
        },
      );
      await flappyAvax.deposit.sendTransaction([(i + 1).toString()], {
        from: accounts[i],
      });
      try {
        await flappyAvax.matchmarking.sendTransaction((i + 1).toString(), {
          from: accounts[i],
        });
        if (i === 10) {
          throw null;
        }
      } catch (e) {
        if (i === 10) {
          console.log(accounts[i], (i + 1).toString());
          assert(
            e !== null && e !== undefined,
            'Expected an error but did not get one',
          );
          assert(
            e.message.includes('No match available'),
            'Expected error: No match available',
          );
        } else {
          throw e;
        }
      }

      /*
      assert(
        (await flappyAvax.getCurrentMatchs.call()).toString() === i >= 1 &&
          i <= 5
          ? "1"
          : "1,2",
        "Match mismatch"
      );
      */
    }
    // Check matchs created by contract
    let match = await flappyAvax.getMatchForAddress.call(accounts[1], {
      from: accounts[1],
    });
    assert(
      match.inMatch && match.matchId.toString() === '1',
      'Account 1 should be on match with Id 1',
    );
    match = await flappyAvax.getMatchForAddress.call(accounts[11], {
      from: accounts[11],
    });
    assert(
      !match.inMatch && match.matchId.toString() === '0',
      'Account 11 should not be on any match',
    );

    const signingAccount = 19;
    const claimReward = async (matchId, rank, account) => {
      const hash = await web3.eth.sign(
        web3.utils.soliditySha3(matchId, rank, account),
        accounts[signingAccount],
      );
      const r = hash.slice(0, 66);
      const s = `0x${hash.slice(66, 130)}`;
      const v = web3.utils.toDecimal(`0x${hash.slice(130, 132)}`) + 27;
      const lastBalance = await bbone.balanceOf.call(account);
      await flappyAvax.claimReward.sendTransaction(matchId, rank, r, s, v, {
        from: account,
      });
      const newBalance = web3.utils.fromWei(
        (await bbone.balanceOf.call(account)).sub(lastBalance),
      );
      switch (rank) {
        case 1:
          assert(newBalance === '74.14', 'Expected balance 74.14');
          break;
        case 2:
          assert(newBalance === '43.81', 'Expected balance 43.81');
          break;
        case 3:
          assert(newBalance === '23.59', 'Expected balance 23.59');
          break;
        case 4:
          assert(newBalance === '16.85', 'Expected balance 16.85');
          break;
        case 5:
          assert(newBalance === '10.11', 'Expected balance 10.11');
          break;
        case 6:
          assert(newBalance === '8.425', 'Expected balance 8.425');
          break;
        case 11:
          assert(newBalance === '6.74', 'Expected balance 6.74');
          break;
        case 21:
          assert(newBalance === '3.37', 'Expected balance 3.37');
          break;
        case 31:
          assert(newBalance === '1.685', 'Expected balance 1.685');
          break;
        case 41:
          assert(newBalance === '0.8425', 'Expected balance 0.8425');
          break;
      }
    };
    const checkReward = async (matchId, rank, account) => {
      await claimReward(matchId, rank, account);
      await expectError(
        claimReward(matchId, rank, account, accounts[signingAccount]),
        'Reward claimed for this account and match',
      );
    };

    await expectError(claimReward('0', '1', accounts[0]), 'Match id invalid');
    await expectError(
      claimReward('3', '1', accounts[0]),
      "Match isn't started ",
    );
    await expectError(claimReward('1', '0', accounts[0]), 'Rank invalid');
    await expectError(claimReward('1', '101', accounts[0]), 'Rank invalid');
    await expectError(
      claimReward('1', '1', accounts[0]),
      'Match is not finished',
    );
    await advanceTimeAndBlock(60 * 60);
    await expectError(
      claimReward('1', '1', accounts[11]),
      'Address not in match',
    );
    for (let i = 1; i <= 5; i++) {
      await checkReward('1', i, accounts[i - 1]);
    }
    await checkReward('2', 6, accounts[5]);
    await checkReward('2', 11, accounts[6]);
    await checkReward('2', 21, accounts[7]);
    await checkReward('2', 31, accounts[8]);
    await expectError(
      checkReward('2', 31, accounts[9]),
      'Reward for the rank has been claimed',
    );
    await checkReward('2', 41, accounts[9]);

    await flappyAvax.withdraw(['1'], true);
    await flappyAvax.deposit(['1']);

    await flappyAvax.matchmarking.sendTransaction('1', {
      from: accounts[0],
    });
    assert(
      (await flappyAvax.getMatchForAddress(accounts[0])).matchId.toString()
        === '3',
      'Match id wrong',
    );
    return;

    const doTransfer = async () => {
      await bobtail.transfer.sendTransaction(
        accounts[1],
        web3.utils.toWei('1000'),
        {
          from: accounts[0],
        },
      );
      console.log(
        web3.utils.fromWei(await bobtail.balanceOf.call(accounts[1])),
        'Account 1 Balance / transfer 1000',
      );
      console.log('----');
    };
    // await doTransfer();
    // await doTransfer();
    // await doTransfer();
    // console.log(web3.utils.fromWei(await bobtail.balanceOf.call(bbone.address)), 'Contract bbone balance');

    // console.log('swap1');
    // await swap(lpToken, bobtail, "0.2");
    // console.log('************');

    // await sleep(1000);

    // console.log(web3.utils.fromWei(await bobtail.balanceOf.call(bobtail.address)), 'Contract bbone balance');
    // console.log(web3.utils.fromWei(await web3.eth.getBalance(bobtail.address)), 'Contract ETH Balance');
    // console.log(web3.utils.fromWei(await bobtail.balanceOf.call(bobtail.address)), 'BBone Contract Balance ');

    // console.log('************');
    // console.log(web3.utils.fromWei(await lpToken2.methods.balanceOf("0x0000000000000000000000000000000000000000").call()), 'LP2 balance');

    /*
    console.log('swap2');
    await swap(lpToken, bobtail, "0.2");
    await sleep(1000);

    console.log(web3.utils.fromWei(await bobtail.balanceOf.call(bobtail.address)), 'Contract bobtail balance');
    console.log('************');
    console.log('************');
    console.log('swap3');
    await swap(lpToken, bobtail, "0.2");
    await sleep(4000);

    console.log(web3.utils.fromWei(await bobtail.balanceOf.call(bobtail.address)), 'Contract bobtail balance');
    console.log('************');
    console.log('************');
    console.log('swap4');
    await swap(lpToken, bobtail, "0.2");
    console.log(web3.utils.fromWei(await bobtail.balanceOf.call(bobtail.address)), 'Contract bobtail balance');
    console.log('************');

    await doTransfer();
    await doTransfer();
    await doTransfer();
    console.log(web3.utils.fromWei(await bobtail.balanceOf.call(bobtail.address)), 'Contract BoBtail balance');
    console.log(web3.utils.fromWei(await web3.eth.getBalance(bobtail.address)), 'Contract ETH Balance');
    console.log(web3.utils.fromWei(await bbone.balanceOf.call(bobtail.address)), 'BBone Contract Balance ');

    await doTransfer();
    await doTransfer();
    await doTransfer();
    console.log(web3.utils.fromWei(await lpToken2.methods.balanceOf("0x0000000000000000000000000000000000000000").call()), 'LP2 balance');

    console.log('Finished')
    return;

    // console.log(bobtail.balance);

     */
    const swap = async (pair, token, amount) => {
      /*
     const reserves = await pair.methods.getReserves().call();
     let reserveEth;
     let reserveToken;
     if((await pair.methods.token0().call())===token.address){
       reserveToken = reserves.reserve0;
       reserveEth = reserves.reserve1;
     }else{
       reserveEth = reserves.reserve0;
       reserveToken = reserves.reserve1;
     }
     const amountSwap = web3.utils.toWei(amount);
     const amountOut = await router.methods.getAmountOut(
         amountSwap,
         reserveEth, reserveToken).call();
     await sleep(1000);
      */
      const amountSwap = web3.utils.toWei(amount);

      const swap = router.methods.swapExactAVAXForTokensSupportingFeeOnTransferTokens(
        '0',
        [address.WETH, token.address],
        accounts[0],
        Math.floor(Date.now() / 1000) + 10,
      );
      await swap.send({
        from: accounts[0],
        value: amountSwap,
        gas: await swap.estimateGas({
          from: accounts[0],
          value: amountSwap,
        }),
      });
    };
    await bobtail.approve.sendTransaction(
      address.PancakeRouter,
      web3.utils.toWei('11'),
      {
        from: accounts[0],
      },
    );
    console.log('swapTest');
    const swapTest = router.methods.swapExactTokensForAVAXSupportingFeeOnTransferTokens(
      web3.utils.toWei('1'),
      '0',
      [bobtail.address, address.WETH],
      accounts[0],
      Math.floor(Date.now() / 1000) + 10,
    );
    // console.log();
    await swapTest.send({
      from: accounts[0],
      gas: await swapTest.estimateGas({
        from: accounts[0],
      }),
    });
    // await swap();
    // console.log(web3.utils.fromWei(await lpToken2.methods.balanceOf("0x0000000000000000000000000000000000000000").call()), 'LP2 balance');
  });
});
