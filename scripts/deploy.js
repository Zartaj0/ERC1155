// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");

async function main() {

  const Joker = await hre.ethers.getContractFactory("Joker");
  const joker= await Joker.deploy("https://gateway.pinata.cloud/ipfs/QmYLwrqMmzC3k4eZu7qJ4MZJ4SNYMgqbRJFLkyiPtUBZUP/");

  await joker.deployed();

  console.log(
    ` deployed to ${joker.address}`
  );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
