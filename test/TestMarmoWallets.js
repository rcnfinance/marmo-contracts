const Marmo = artifacts.require("./Marmo.sol");
const MarmoCreator = artifacts.require("./MarmoFactory.sol");

const Helper = require('./Helper.js');

contract('Marmo wallets', function (accounts) {
    before(async function(){
        marmoCode = await Marmo.new();
        creator = await MarmoCreator.new(marmoCode.address);
    });
    describe("Create marmo wallets", function() {
        it("Should reveal the marmo wallet", async function() {
            const creator = await MarmoCreator.new(marmoCode.address);
            await creator.reveal(accounts[0]);
        });
        it("Should predict the Marmo wallet", async function() {
            const predicted = await creator.marmoOf(accounts[1]);
            assert.equal("0x", await web3.eth.getCode(predicted), "Wallet already exists");
            await creator.reveal(accounts[1]);
            assert.notEqual("0x", await web3.eth.getCode(predicted), "Wallet is not created");
        });
        it("Should fail to reveal if already revealed", async function() {
            await Helper.tryCatchRevert(creator.reveal(accounts[1]), "");
        });
    });
})
