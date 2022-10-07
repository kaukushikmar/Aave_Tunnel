const { ethers, getNamedAccounts } = require("hardhat");

describe("Aave Tunnel", async () => {
  const { deployer } = await getNamedAccounts();
  const lendingPoolAddressProvider = await ethers.getContractAt(
    "ILendingPoolAddressesProvider",
    "0xB53C1a33016B2DC2fF3653530bfF1848a515c8c5"
  );
  const lendingPoolAddress = await lendingPoolAddressProvider.getLendingPool();
  const lendingPool = await ethers.getContractAt(
    "ILendingPool",
    lendingPoolAddress
  );

  const aTokensAddress = "0xFFC97d72E13E01096502Cb8Eb52dEe56f74DAD7B";
  const wEthAddress = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2";

  const oracleAddress = await lendingPoolAddressProvider.getPriceOracle();
  beforeEach(async () => {
    const aaveFactory = await ethers.getContractFactory("AaveTunnel", deployer);
    const aave = await aaveFactory.deploy([
      lendingPool.address,
      aTokensAddress,
      wEthAddress,
      oracleAddress,
    ]);
  });
});
