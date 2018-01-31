var NOUSToken = artifacts.require("NOUSToken");
//var NOUSSale = artifacts.require("./NousplatformCrowdSale.sol");



contract('NOUSToken', function (accounts) {
    console.log("accounts", accounts);

    let NOUSTokenInstance;

    it("Set dug sale address", async function () {
        NOUSTokenInstance = await NOUSToken.deployed();
        let nous = await NOUSTokenInstance.setDugSale(accounts[0], {from: accounts[0]});
        let dougSaleAddress = await NOUSTokenInstance.getDugSaleAddress.call({from: accounts[0]});
        console.log("dougSaleAddress", dougSaleAddress);

       /* return NOUSTokenInstance.canMints()
            .then((res)=>{
                assert.equal(res, accounts[0]);
            })*/
        //console.log("await NOUSTokenInstance.canMints()", await  NOUSTokenInstance.canMints());


        //let dugSaleAddress = await NOUSTokenInstance.canMints();



        /*return NOUSTokenInstance.setDugSale.call(accounts[0])
            .then((res) => {
                console.log("res", res);

                return NOUSTokenInstance.getDugSaleAddress.call()
                    .then((res) => {
                        console.log("res", res);
                        return assert.equal(res, accounts[0]);
                    });
            });*/


        //console.log("await NOUSTokenInstance.getDugSaleAddress.call()", await NOUSTokenInstance.getDugSaleAddress.call());

        //assert.equal(await NOUSTokenInstance.getDugSaleAddress.call(), accounts[0]);
    });


});