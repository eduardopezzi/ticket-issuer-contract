const TickerMaster = artifacts.require("TicketMaster");

module.exports = function(deployer) {
  deployer.deploy(TickerMaster, 100, "Blockchain meetup");
};
