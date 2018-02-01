var NOUSToken = artifacts.require("NOUSToken");
//var NOUSSale = artifacts.require("./NousplatformCrowdSale.sol");



contract('NOUSToken', function (accounts) {
    //console.log("accounts", accounts);

    let NOUSTokenInstance;
    let owner = accounts[0];
    let dugSaleAddress = accounts[9];

    let account_one = accounts[1];
    let account_two = accounts[2];
    let account_three = accounts[3];

    it("Set dug sale address", async () => {
        NOUSTokenInstance = await NOUSToken.deployed();
        await NOUSTokenInstance.setDugSale(dugSaleAddress);
        assert.equal(await NOUSTokenInstance.getDugSaleAddress({from: accounts[0]}), dugSaleAddress);
    });

    it("Mint Token", async () => {
        await NOUSTokenInstance.mint(account_one, 10000, {from: dugSaleAddress});
        await NOUSTokenInstance.mint(account_two, 20000, {from: dugSaleAddress});
        await NOUSTokenInstance.mint(account_two, 1500, {from: dugSaleAddress});
        await NOUSTokenInstance.mint(account_three, 30000, {from: dugSaleAddress});

        assert.equal(await NOUSTokenInstance.balanceOf(account_one), 10000);
        assert.equal(await NOUSTokenInstance.balanceOf(account_two), 21500);
        assert.equal(await NOUSTokenInstance.balanceOf(account_three), 30000);
    });

    it("Finish mining and transfer token", async () => {
        await NOUSTokenInstance.finishMinting({from: owner});
        assert.equal(await NOUSTokenInstance.canMints(), false);
        try {
            await NOUSTokenInstance.mint(account_one, 10000, {from: dugSaleAddress});
            assert(false, "Maning not stopping.");
        } catch(e) {
            console.log('catch');
            assert(true, "Current Maning stopping.");
        }
    });




});