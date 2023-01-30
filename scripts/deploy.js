require("dotenv").config();
const hre = require("hardhat");
const {
  getRole,
  verify,
  ex,
  printAddress,
  deploySC,
  deploySCNoUp,
} = require("../utils");

var MINTER_ROLE = getRole("MINTER_ROLE");
var BURNER_ROLE = getRole("BURNER_ROLE");

async function deployPublicSale() {

  var publicSaleContract = await deploySC('PublicSale');
  var implementation = await printAddress("PublicSale", publicSaleContract.address);

  // set up
  await ex(publicSaleContract);

  await verify(implementation, "PublicSale", []);
}
async function updatePublicSale() {

  var publicSaleContractAddress = '0x1D83FE68F02500380EF108f1a03b3F5e4B9865DD';
  var PublicSaleContract = await hre.ethers.getContractFactory('PublicSale');
  var newPublicSaleContract = await hre.upgrades.upgradeProxy(
    publicSaleContractAddress,
    PublicSaleContract,
  );

  var tx = await newPublicSaleContract.deployed();
  await tx.deployTransaction.wait(2);

  var implementation = await printAddress("PublicSale", newPublicSaleContract.address);

  await verify(implementation, "PublicSale", []);
}

async function deployGoerli() {
  // gnosis safe
  // Crear un gnosis safe en https://gnosis-safe.io/app/
  // Extraer el address del gnosis safe y pasarlo al contrato con un setter
  // var gnosis = { address: "" };
}

async function deployNFT() {
  var MiPrimerNft = await hre.ethers.getContractFactory("MiPrimerNft");
  var miPrimerNft = await MiPrimerNft.deploy();
  var tx = await miPrimerNft.deployed();
  await tx.deployTransaction.wait(5);
  console.log(
    "MiPrimerNft esta publicado en el address",
    miPrimerNft.address
  );
  await hre.run("verify:verify", {
    address: miPrimerNft.address,
    constructorArguments: [],
  });
}

async function deployMiPrimerToken() {
  var MiPrimerToken = await hre.ethers.getContractFactory("MiPrimerToken");
  var miPrimerToken = await MiPrimerToken.deploy();
  var tx = await miPrimerToken.deployed();
  await tx.deployTransaction.wait(5);
  console.log(
    "Mi primer token esta publicado en el address",
    miPrimerToken.address
  );
  await hre.run("verify:verify", {
    address: miPrimerToken.address,
    constructorArguments: [],
  });
}

async function deployUSDC() {
  var USDCoin = await hre.ethers.getContractFactory("USDCoin");
  var uSDCoin = await USDCoin.deploy();
  var tx = await uSDCoin.deployed();

  // 5 bloques de confirmacion
  await tx.deployTransaction.wait(5);
  console.log("USDCCoin6 esta publicado en el address", uSDCoin.address);

  console.log("Empezo la verificaion");
  // script para verificacion del contrato
  await hre.run("verify:verify", {
    address: uSDCoin.address,
    constructorArguments: [],
  });
}

// usdc contract address: 0x424aa621EeCf2d5A4C5171750Eb2a6407A02fE21
// token contract address: 0xfE865B499AADF5643E6a68a2E4Fe3D61ad1F9d64
// nft contract address: 0x7721DD243f638bA2751dA6c8112076cDdbe44f2F
// PublicSale Proxy Address: 0x1D83FE68F02500380EF108f1a03b3F5e4B9865DD
// PublicSale Impl Address: 0x3d6B5610A0cf28B8Eab43D7B30440b7A8b9c8c0C

// deployMumbai()
// deployGoerli()
// deployUSDC()
// deployMiPrimerToken()
// deployPublicSale()
// deployNFT()
updatePublicSale()
  //
  .catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
