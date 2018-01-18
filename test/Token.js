var NOUSToken = artifacts.require("NOUSToken");
var NOUSSale = artifacts.require("./NousplatformCrowdSale.sol");

const deployedAndWriteInAddressBook = contract =>
    contract.deployed().then(deployedContract => {
        const name = deployedContract.constructor.toJSON().contract_name;

        contracts[name] = {
            name: name.toLowerCase(),
            address: deployedContract.address,
            contract: deployedContract
        }
    });


contract('NOUSToken', function (accounts) {
    it("Nous Dug sale address", function () {
        return NOUSToken.deployed()
            .then(function (instance) {
                console.log("instance", instance);
                return instance.dugSale.call();
            }).then(function (balance) {
                console.log("balance", balance);
                //assert.equal(balance.valueOf(), 10000, "10000 wasn't in the first account");
            });

    })
});