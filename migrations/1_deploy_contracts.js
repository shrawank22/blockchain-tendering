const ContractingPlatform = artifacts.require("ContractingPlatform");

module.exports = function (deployer) {
  deployer.deploy(ContractingPlatform);
};