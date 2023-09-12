const { ethers } = require("hardhat");

async function main() {
  const ContractFactory = await ethers.getContractFactory("ApolloToken");

  console.log("Deploying apollo token to testnet");
  const apolloToken = await ContractFactory.deploy();
  await apolloToken.deployed();

  console.log(`Contract ${apolloToken.address} deployed!`);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.log(error);
    process.exit(1);
  });

module.exports.tag = ["all"];
