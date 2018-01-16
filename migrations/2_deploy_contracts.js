var NOUSToken = artifacts.require("./NOUSToken.sol");
var NOUSSale = artifacts.require("./NousplatformCrowdSale.sol");
var RefundVault = artifacts.require("./RefundVault.sol");
var BonusForAffiliate = artifacts.require("./BonusForAffiliate.sol");

var NOUSPreorder = artifacts.require("./NOUSPreorder.sol");
var NOUSPresale = artifacts.require("./NOUSPresale.sol");
var NOUSCrowdsale = artifacts.require("./NOUSCrowdsale.sol");
var NOUSReservFund = artifacts.require("./NOUSReservFund.sol");
var PaymentBounty = artifacts.require("./PaymentBounty.sol");


module.exports = function(deployer) {

    var wallet = "0x68617F24d480a3A2b0056baD44cC1726f0644EF1";

    deployer
        .then(function() {
            Promise.all(
                [
                    NOUSToken.new(),
                    RefundVault.new(wallet),
                    BonusForAffiliate.new(),
                ]
            )
            .then(function(instances) {
                return PaymentBounty.new(instances[0].address)
                    .then(function (bountyInst) {

                        console.log("NOUSToken:", instances[0].address);
                        console.log("RefundVault:", instances[1].address);
                        console.log("BonusForAffiliate:", instances[2].address);
                        console.log("PaymentBounty:", bountyInst.address);

                        return NOUSSale.new(instances[0].address, instances[1].address, instances[2].address, bountyInst.address)
                            .then(function (instanceNousSale) {
                                instances[0].setDugSale(instanceNousSale.address);
                                instances[1].setDugSale(instanceNousSale.address);
                                instances[2].setDugSale(instanceNousSale.address);
                                bountyInst.transferOwnership(instanceNousSale.address);
                                return instanceNousSale.address;
                        })

                    });
            })
            .then(function (nousSaleSddr) {
                console.log("NOUSSale:", nousSaleSddr);
                deployer.deploy([
                    [NOUSPreorder, nousSaleSddr],
                    [NOUSPresale, nousSaleSddr],
                    [NOUSCrowdsale, nousSaleSddr],
                    [NOUSReservFund, nousSaleSddr]
                ]);
            })

    });

};


function toJson(obj) { return JSON.stringify(obj.abi); }
function unloc(i) { return personal.unlockAccount(eth.accounts[i]) }

// NOUSSale: 0x862c1a285cc6966048b52c8c6a8334ed77f4ce75
// NOUSToken: 0x20ebbc2775047e39ed200d178a5f5915f277db27
// RefundVault: 0x63ee71e52b54a6ca44067791d50770e24a030050
// BonusForAffiliate: 0x0819b231394124429e9dc2095f41e27bcb6edf55
// PaymentBounty: 0x13fc66cfb0947e73eba9e6ae07f9ae5d2ede7b7e
//
// NOUSPreorder: 0x8abf4b2df59966e025c003acd43e893d772f7a84
// NOUSPresale: 0xd2c375ae2214fa4fc8f462509402968add68d62b
// NOUSCrowdsale: 0xc86fda0c18884bbc394f07a374fe378e852d35cf
// NOUSReservFund: 0xb9bac69ed5464324691ba6b497db99cd89f40702
