const { expect, assert } = require("chai");
const { ethers, getNamedAccounts } = require("hardhat");

describe("Aave Tunnel", async () => {
  const USER_MONEY = ethers.utils.parseEther("10");
  let deployer, aave, token, user;

  const aTokensAddress = "0x030bA81f1c18d280636F32af80b9AAd02Cf0854e";
  const wEthAddress = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2";

  beforeEach(async () => {
    [deployer, user] = await ethers.getSigners();

    // deploying the library contract
    const libFactory = await ethers.getContractFactory("ValidationLogic");
    const lib = await libFactory.deploy();
    await lib.deployed();
    console.log("Deployed library contract");

    const lendingPoolAddressProvider = await ethers.getContractAt(
      "ILendingPoolAddressesProvider",
      "0xB53C1a33016B2DC2fF3653530bfF1848a515c8c5"
    );
    const lendingPoolAddress =
      await lendingPoolAddressProvider.getLendingPool();
    const lendingPool = await ethers.getContractAt(
      "ILendingPool",
      lendingPoolAddress
    );
    console.log("got lending pool contract");

    const oracleAddress = await lendingPoolAddressProvider.getPriceOracle();
    console.log(`got the oracle address: ${oracleAddress}`);

    const aaveFactory = await ethers.getContractFactory("AaveTunnel", {
      signer: deployer,
      libraries: {
        ValidationLogic: lib.address,
      },
    });
    console.log(`Got the aave Factory: ${aaveFactory}`);

    aave = await aaveFactory.deploy(
      lendingPool.address,
      aTokensAddress,
      wEthAddress,
      oracleAddress
    );
    await aave.deployed();
    console.log("deployed aave contract");

    token = await ethers.getContractAt("IWeth", wEthAddress, deployer);
    console.log("Got the weth contract");

    const tx = await token.deposit({ value: USER_MONEY });
    await tx.wait();
    const tx1 = await token.transfer(user.address, USER_MONEY);
    await tx1.wait();
    const wethBalance = await token.balanceOf(user.address);
    console.log(`Balance of user: ${wethBalance.toString()}`);
  });

  it("Should deposit the money in lending pool", async () => {
    console.log("Supplying asset");
    await token.connect(user).approve(aave.address, USER_MONEY);
    const tx = await aave
      .connect(user)
      .supply(wEthAddress, ethers.utils.parseEther("5"));
    await tx.wait();
    console.log("Supplied asset");
    const deployerSupplied = await aave.getSuppliedAmount(user.address);

    assert.equal(
      deployerSupplied.toString(),
      ethers.utils.parseEther("5").toString()
    );
  });

  it("Should not be able to withdraw money", async () => {
    console.log("withdrawing asset");
    await expect(
      aave.connect(user).withdraw(wEthAddress, ethers.utils.parseEther("5"))
    ).to.be.reverted;
  });
});
