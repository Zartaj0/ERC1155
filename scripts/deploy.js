
const hre = require("hardhat");

async function main() {

  const Joker = await hre.ethers.getContractFactory("Joker");
  const joker= await Joker.deploy("https://gateway.pinata.cloud/ipfs/QmYLwrqMmzC3k4eZu7qJ4MZJ4SNYMgqbRJFLkyiPtUBZUP/");

  await joker.deployed();

  console.log(
    ` deployed to ${joker.address}`
  );
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
