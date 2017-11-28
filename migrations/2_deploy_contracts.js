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
                                instances[0].transferOwnership(instanceNousSale.address);
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

// NOUSToken: 0x9c5b2f71ba6e403ccda71f0d70e4ec95638075fe
// RefundVault: 0xa8aef92d96854b345e10cbfa32d85b81216482f7
// BonusForAffiliate: 0x5da285649e6e4718a4bddab280935691e3927464
// PaymentBounty: 0x5fed265f952463e826709baa140bd580f9deeef6
//
// NOUSSale: 0x7851573b1a90b84a9565aeb9b8be897bcb3ce93c
//
// NOUSPreorder: 0x4b3320c85c961c07fbd6c7b8370705ac20393b5f
// NOUSPresale: 0x8a08eae84cb9a8cfedd343a49b6b37d25fff902f
// NOUSCrowdsale: 0x0a2fcd2569302166bc4bd45ad48d4c0433756276
// NOUSReservFund: 0x81e68bcf17922c9280bda883cfd3a4e0be13707c




// NOUSToken: 0x953ff0d8709e5145b1aa8136acfec79039e36280
// RefundVault: 0x93ef9e1d0b3d6df35feed9947a1284454033547e
// BonusForAffiliate: 0xfddb435b5e83881489194b0653defb7c6d6a51ce
// PaymentBounty: 0x23e3e33dea9b74e97574c34d0d26bda3044f1bd4
//
// NOUSSale: 0x872f8e5face2d746a9c493550426bb319cb5f55d
//
// NOUSPreorder: 0xe92780393a9fdc3a70e8b488a4b7b87a93301178
// NOUSPresale: 0x9dc5331c293b8a29c0a8f94061b520051fc6bca0
// NOUSReservFund: 0x4f468370f41ce9a260c7b4b4dbbff1310ecfd745
// NOUSCrowdsale: 0xd6d41e181c46a083629e21d6f5fbaafd5f2d52c5

//"0x9dc5331c293b8a29c0a8f94061b520051fc6bca0",1,225000,0,10,1511733600,1511949600,8000


// NOUSToken: 0x67b7d61247588065d23c8ed93aaaeb4e69ceea0c
// RefundVault: 0x5fedda3ef38f4444b706370798578f26bb19a3bf
// BonusForAffiliate: 0xadb6da18e0a015f79d2afb6154cc9edfa9701822
// PaymentBounty: 0x7f8e49b6c66ad77b8649566b09e706a652d76176

// NOUSSale: 0x403a8808ce1cd06eadc2ffcea3d7d3c3444eb7bf

// NOUSPreorder: 0xae985feb48d94ac179d040b69b4f4f3eee646dc8
// NOUSPresale: 0x303b2ee7683b779d3554dbba3b8407da8896896d
// NOUSCrowdsale: 0x2e7ef08451992727d9eee90565d9460c7bd70517
// NOUSReservFund: 0x7ac8430283f329836c6a186732ada3dc7f105480




/*
NOUSToken: 0x2eee4ce641839d4ed0299e6228f36d04e8479e1d
RefundVault: 0xc9ed4516e63dcabeee592f2db7ec932647fda409
BonusForAffiliate: 0x3f5a4905bd18f924e4d42d83dd3dfaa98926f2e3
PaymentBounty: 0x0e4c3a69726167867e2a11b629066cc11c17cb40

NOUSSale: 0xaab5634656868d2aa87aa0c41cc0f8ec37550dec

  NOUSPreorder: 0x2f84ef9a2ef239f404813c2ba961f2db8d07df9a
  NOUSPresale: 0x2a9b8200eaa5fa8fee6180405a919b5cdff216b2
  NOUSReservFund: 0x4c8efc924024affa26ae30afaa6c68b79f16150e
  NOUSCrowdsale: 0xfd22317ba8484721f2c0ebde6336f13ab64f5b34
*/









/*
NOUSToken: 0x860134d046fd08406fad30217ea3a21c32dd7fab
RefundVault: 0x3522d17023919a33fd7dd7fca443a9a878051687
NOUSSale: 0x572a7d0e0eacb71c1305250d75acb0830b37d5b9
  Replacing NOUSPresale...
  Replacing NOUSCrowdsale...
  Replacing NOUSReservFund...
  NOUSCrowdsale: 0x64729085f3065a81504dff5d1758dfcdee25abd7
  NOUSPresale: 0xace2c215e47c97a9c6ae288a0d981cd7d6a6d530
  NOUSReservFund: 0x8c55d9de8fe1f198e27093aeab1770f820404f30
 */

/*
NOUSToken: 0xfc7b61ac981d8a668ea01972c998929143b712ae
RefundVault: 0x6f0714b87ca073b1c12153c6751e921594c00037
NOUSSale: 0xadce3dd7888a28b3c10a68c2c4e57728f1c5b6a0
Replacing NOUSPresale...
    Replacing NOUSCrowdsale...
    Replacing NOUSReservFund...
    NOUSCrowdsale: 0x03bb336c2cb70461eb2cf435f37362a4c6ca5125
NOUSPresale: 0x56d3f5046c5eee5bd111cd6f30bbea2fe4ad7518
NOUSReservFund: 0x857d476e369927c6a4a66149fa2fd55297105b6a
*/



/*
 minETH 5500
NOUSToken: 0x4c51903cd51f6d1dd95594eaec030ed9f88e1b26
RefundVault: 0xb9aeae4633220c234af551c5d96836c9d1d33e5b
NOUSSale: 0xf0b69f818985e3fbe6da23083b59303223adf84b
Deploying NOUSPresale...
    Deploying NOUSCrowdsale...
    Deploying NOUSReservFund...
    NOUSPresale: 0x153e12097117988e48d9c673759afa8cfc48eb95
NOUSCrowdsale: 0x77716b97029a6ebb977ee51f683c5bda97748a43
NOUSReservFund: 0xc4e6456534d2aefe54b299f0a04f24eb9c7338a9
*/


/*
ETHMix 5
NOUSToken: 0xc9a4c7575645aa4dc9c2e24d1202c8b9b5156446
RefundVault: 0xf5d0c21b603560ccb26ec005784cd9d5dd779358
NOUSSale: 0xa29ce17d2d93ab02a41924b696504802820a7b9b
Deploying NOUSPresale...
    Deploying NOUSCrowdsale...
    Deploying NOUSReservFund...
    NOUSCrowdsale: 0xc7184f000f0b74ad6f8bf55158e9137a20179926
NOUSPresale: 0xcab91b76e1a94b91582688c8beeaf4a774c35e27
NOUSReservFund: 0x47da3301d02246ab5e1e010c3733aa084ee42943
*/

/*
23.10
NOUSToken: 0x1f6081d57f94c47e4ab509b9310778f3796633a4
RefundVault: 0xa98e0dce0035716b408ed595ff9ad2dd5d237ab0
NOUSSale: 0x65042ea304f99096dc35d5122d179f650e7e6e9e
Deploying NOUSPresale...
    Deploying NOUSCrowdsale...
    Deploying NOUSReservFund...
    NOUSPresale: 0x55999b24a756680843c53588c4632da69a0added
NOUSCrowdsale: 0xa73a961770ddf53a29203161f6352884f2fd767b
NOUSReservFund: 0x5d66eb493035b2fbe1c00de32c7aa9bc7f8956d0
*/

/*
NOUSToken: 0xedba51dd61126dc26843f521ba4fc29dc3ff2bdf
RefundVault: 0x3f06120593115bb81dc633881312fae2f00b908e
NOUSSale: 0x1ddadceb68773519d2eca37d8d754796335e9f20
Deploying NOUSPresale...
    Deploying NOUSCrowdsale...
    Deploying NOUSReservFund...
    NOUSCrowdsale: 0x75a07385b02f16735e25642ec49118d626e9dde4
NOUSPresale: 0x9e33a0cf53e1740a621207692a86209640dcfcd2
NOUSReservFund: 0x21286015eb1087a1d2dd8f660992a40d0373897f
*/



/*

NOUSToken: 0x14ab8750e71b5ee09d72138a19a2f94303ca7f4e
RefundVault: 0x16e6facdb45aef0eb67705bb8b0b9788d2ccd653
Saving artifacts...
    NOUSSale: 0x64226d4c4dfac033ac6ff74788de6752b2f5ab5a
Deploying NOUSPresale...
    Deploying NOUSCrowdsale...
    Deploying NOUSReservFund...
    NOUSCrowdsale: 0x58f9ec86718d82f3a5bcb962975b6f75330e49b4
NOUSPresale: 0xafb68271944ba4a6fdc5d594e4991107d20b4f5c
NOUSReservFund: 0x329d57de9ee2536deb2287d7d580c424cc6e3ac7
*/

//
// NOUSToken: 0x14d31cd5ded4735d6e89c8f376c7940cb15227dc
// RefundVault: 0x4cd7b59c0084684526b3ae4a0874d98a59c88ebe
// BonusForAffiliate: 0x5581f2a3f02760e214f4f725e90e736fce715aa4




// NOUSToken: 0x2c86360bb46fbb44f7826615fb79073a3c200ef1
// RefundVault: 0x5b1227b0d67c86efca6e9b4110f44945dde181e5
// BonusForAffiliate: 0xcc6ae619069d2d73ae96a38973081a063ce01bee
// PaymentBounty: 0xce422470f63bc9dc303f370938410a0d0ac7b253
// NOUSSale: 0x778271da121c49656654783fcd0cccf479e79edc
// NOUSReservFund: 0xcb066540e6bcba536d180b3a0b1066eceae7048f
// NOUSCrowdsale: 0xd661524ae7ee1a8145c089109f4b9115b8646a74
// NOUSPreorder: 0x81d915d04d2b9aebd2f22c71bf6a6e572b3cdad8
// NOUSPresale: 0x098d14884021f7c036fff1feda6fb41d567bbc4e




