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

    var wallet = "0x37debdf452a2e9c95c7ed85955ffd6e812a66062";

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
                                let nousSaleAddress = instanceNousSale.address;
                                instances[0].setDugSale(nousSaleAddress);
                                instances[1].setDugSale(nousSaleAddress);
                                instances[2].setDugSale(nousSaleAddress);
                                bountyInst.transferOwnership(nousSaleAddress);
                                return nousSaleAddress;
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

//
//
// Available Accounts
// ==================
// (0) 0xf09963ee63b18c2c3aa075e2818c8c3b7549dc54
// (1) 0x260790c3c20310e08753f40a826d655f8112b834
// (2) 0x120168d386a909781b9cea6e0a76b3461e7a1cb4
// (3) 0xb95a3cdc41e7ca9ee09e6a96cd5552cb5e593f16
// (4) 0x9f79e220e4a6b7b6c42c81e3c339a7e45ec5b6e9
// (5) 0x7f0465f1c7f16e7262301068bed8849405e9a83e
// (6) 0x1390a78ec434ed3a9d80f5b1cd3f46d78fa2a1a5
// (7) 0xc271f41ff7419347ae87495e5d330e5526a8ba60
// (8) 0x2d8f04a15c26386d19f104d6380336f045f56738
// (9) 0x4c7244b5f2072233e45e97db15198d85fa4cff6f
//
// Private Keys
// ==================
// (0) a88e69ea411e7d321be4d05ca994ce5c487d0cc9dd3d4702fcf99457f6f658c5
// (1) 2b0a4c92ef2f9fa689a1d6e9d551213913ef74c5d14960ad38c0f017ac5e656e
// (2) 72b23cada742c9247a66632c4bf1ca9c511dc893f818553cc5f6ac5ff19c5047
// (3) 459761bcbf9cdd9f71d6d9eb154f7b32d6935f3431902aad9c81144e4db30803
// (4) c831b1161ebd6d7f658e946ea23b99c0a6aee88ef6c4bb46750d88482a76d27c
// (5) 0b69835354615ae24048a04f20e8e3eb8cd76d88c3b5b0902eb6be290a871619
// (6) 9384ef174cb8e188e6be42a9d053fcb1996cd0ffd3c946b3a08779e1012cbf0d
// (7) 9ba52997fced950e1b75d45ff389f433ba7b9d64cfbc57b802a00d2c61a6bbe5
// (8) 648d3eb1ca1071a55b6aafe62eda5f5bde936539f7f9bc49104204f1fc2f4e21
// (9) 40a308fa6e88ff2aea60b29bf6d56be54614732541b3735ffa1c28ef6cea607c



