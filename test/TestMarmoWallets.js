const Marmo = artifacts.require('./Marmo.sol');
const MarmoCreator = artifacts.require('./MarmoFactory.sol');
const TestERC20 = artifacts.require('./TestERC20.sol');

const eutils = require('ethereumjs-util');
const Helper = require('./Helper.js');

const BN = web3.utils.BN;
require('chai')
    .use(require('chai-as-promised'))
    .use(require('chai-bn')(BN))
    .should();

function bn (number) {
    return new BN(number);
}

const privs = [
    '0x62d29230c55255d404f85cf45d2db438911a8e8c76b9e917656fdbd8c4adccf4',
    '0x5ef1dbf8ef171b33cd72a5d11b713442dcd2c70695753a0f6df9b38136e08d54',
    '0x6306c990056a965674edf80c7e1518d1c337abe005ffd7dcd17b25a2db0dfb2f',
    '0xadfc814c0e30d88889a5cf3701e8da4ea65fc15111f54591e6f0ee4aa129f40f',
    '0x2a050363f79a7da50302c2ed81a141f4307d056846339183c671d8defa10db33',
    '0x6de344483ec377e3262437805e3e9f290b1094d7c19bab52eca42bb471edc81a',
    '0x871cbb62ecf06d97185ca70e1722e51684db71066f43c672b6589d47c15d9cb3',
    '0x68159b0ce11c69e75aaa79286f4c6f9e11523f4c12631e608e6a6d60d57dbd94',
    '0x60b51acb27b07e5f8000ad8451469d1326d10357cad955ec4f5d5537ede0e9d8',
    '0x3a423f1c02a85be8641f67e36d91ae4089766ceb18bd7308c2e845d8e90fa705',
];

function signHash (hash, priv) {
    const sig = eutils.ecsign(
        eutils.toBuffer(hash),
        eutils.toBuffer(priv)
    );

    return eutils.bufferToHex(Buffer.concat([sig.r, sig.s, eutils.toBuffer(sig.v)]));
}

contract('Marmo wallets', function (accounts) {
    let marmoCode;
    let creator;
    let testToken;

    before(async function () {
        // Validate test node
        for (let i = 0; i < accounts.length; i++) {
            accounts[i].should.equal(
                eutils.toChecksumAddress(eutils.bufferToHex(eutils.privateToAddress(eutils.toBuffer(privs[i])))),
                'Invalid test node setup, incorrect accounts ganache-cli'
            );
        }

        // Setup contracts
        marmoCode = await Marmo.new();
        creator = await MarmoCreator.new(marmoCode.address);
        testToken = await TestERC20.new();
    });
    describe('Create marmo wallets', function () {
        it('Should reveal the marmo wallet', async function () {
            const creator = await MarmoCreator.new(marmoCode.address);
            await creator.reveal(accounts[0]);
        });
        it('Should predict the Marmo wallet', async function () {
            const predicted = await creator.marmoOf(accounts[1]);
            assert.equal('0x', await web3.eth.getCode(predicted), 'Wallet already exists');
            await creator.reveal(accounts[1]);
            assert.notEqual('0x', await web3.eth.getCode(predicted), 'Wallet is not created');
        });
        it('Should fail to reveal if already revealed', async function () {
            await Helper.tryCatchRevert(creator.reveal(accounts[1]), '', true);
        });
    });
    describe('Relay intents', function () {
        it('Should relay signed tx, send ETH', async function () {
            const wallet = await Marmo.at(await creator.marmoOf(accounts[1]));
            await web3.eth.sendTransaction({ from: accounts[0], to: wallet.address, value: 1 });

            const dependencies = "0x";
            const to = accounts[9];
            const value = 1;
            const data = '0x';
            const minGasLimit = 0;
            const maxGasPrice = bn(10).pow(bn(32));
            const salt = '0x';
            const expiration = bn(10).pow(bn(24));

            const id = await wallet.encodeTransactionData(
                dependencies,
                to,
                value,
                data,
                minGasLimit,
                maxGasPrice,
                salt,
                expiration
            );

            const prevBalanceReceiver = bn(await web3.eth.getBalance(accounts[9]));
            bn(await web3.eth.getBalance(wallet.address)).should.be.a.bignumber.that.equals(bn(1));

            const signature = signHash(id, privs[1]);
            await wallet.relay(
                dependencies,
                to,
                value,
                data,
                minGasLimit,
                maxGasPrice,
                salt,
                expiration,
                signature
            );

            bn(await web3.eth.getBalance(wallet.address)).should.be.a.bignumber.that.equals(bn(0));
            bn(await web3.eth.getBalance(accounts[9])).sub(prevBalanceReceiver)
                .should.be.a.bignumber.that.equals(bn(1));
        });
        it('Should relay signed tx, send tokens', async function () {
            const wallet = await Marmo.at(await creator.marmoOf(accounts[1]));
            await testToken.setBalance(wallet.address, 10);
            await testToken.setBalance(accounts[9], 0);

            const dependencies = "0x";
            const to = testToken.address;
            const value = 0;
            const data = web3.eth.abi.encodeFunctionCall({
                name: 'transfer',
                type: 'function',
                inputs: [{
                    type: 'address',
                    name: 'to',
                }, {
                    type: 'uint256',
                    name: 'value',
                }],
            }, [accounts[9], 4]);

            const minGasLimit = 0;
            const maxGasPrice = bn(10).pow(bn(32));
            const salt = '0x';
            const expiration = await Helper.getBlockTime() + 60;

            const id = await wallet.encodeTransactionData(
                dependencies,
                to,
                value,
                data,
                minGasLimit,
                maxGasPrice,
                salt,
                expiration
            );

            const signature = signHash(id, privs[1]);
            await wallet.relay(
                dependencies,
                to,
                value,
                data,
                minGasLimit,
                maxGasPrice,
                salt,
                expiration,
                signature
            );

            bn(await testToken.balanceOf(accounts[9])).should.be.a.bignumber.that.equals(bn(4));
            bn(await testToken.balanceOf(wallet.address)).should.be.a.bignumber.that.equals(bn(6));
        });
        it('Should fail to relay if transaction is wronly signed', async function () {
            const wallet = await Marmo.at(await creator.marmoOf(accounts[1]));
            await web3.eth.sendTransaction({ from: accounts[0], to: wallet.address, value: 1 });

            const dependencies = "0x";
            const to = accounts[9];
            const value = 1;
            const data = '0x';
            const minGasLimit = 0;
            const maxGasPrice = bn(10).pow(bn(32));
            const salt = '0x1';
            const expiration = bn(10).pow(bn(24));

            const id = await wallet.encodeTransactionData(
                dependencies,
                to,
                value,
                data,
                minGasLimit,
                maxGasPrice,
                salt,
                expiration
            );

            const prevBalanceReceiver = bn(await web3.eth.getBalance(accounts[9]));
            bn(await web3.eth.getBalance(wallet.address)).should.be.a.bignumber.that.equals(bn(1));

            const signature = signHash(id, privs[2]);
            await Helper.tryCatchRevert(wallet.relay(
                dependencies,
                to,
                value,
                data,
                minGasLimit,
                maxGasPrice,
                salt,
                expiration,
                signature
            ), 'Invalid signature');

            await Helper.tryCatchRevert(wallet.relay(
                dependencies,
                to,
                value,
                data,
                minGasLimit,
                maxGasPrice,
                salt,
                expiration,
                '0x'
            ), 'Invalid signature');

            bn(await web3.eth.getBalance(wallet.address)).should.be.a.bignumber.that.equals(bn(1));
            bn(await web3.eth.getBalance(accounts[9])).sub(prevBalanceReceiver)
                .should.be.a.bignumber.that.equals(bn(0));
        });
        it('Should relay is dependencies are filled', async function () {
            const wallet = await Marmo.at(await creator.marmoOf(accounts[1]));
            const ddependencies = "0x";
            const dto = accounts[9];
            const dvalue = 0;
            const ddata = '0x';
            const dminGasLimit = 0;
            const dmaxGasPrice = bn(10).pow(bn(32));
            const dsalt = '0x1';
            const dexpiration = bn(10).pow(bn(24));

            const idDependency = await wallet.encodeTransactionData(
                ddependencies,
                dto,
                dvalue,
                ddata,
                dminGasLimit,
                dmaxGasPrice,
                dsalt,
                dexpiration
            );

            await web3.eth.sendTransaction({ from: accounts[0], to: wallet.address, value: 1 });

            const dsignature = signHash(idDependency, privs[1]);
            await wallet.relay(
                ddependencies,
                dto,
                dvalue,
                ddata,
                dminGasLimit,
                dmaxGasPrice,
                dsalt,
                dexpiration,
                dsignature
            );

            (await wallet.relayedBy(idDependency)).should.be.equal(accounts[0]);

            const dependencies = eutils.bufferToHex(
                Buffer.concat([
                    eutils.toBuffer(wallet.address),
                    eutils.toBuffer(
                        web3.eth.abi.encodeFunctionCall({
                            name: 'relayedBy',
                            type: 'function',
                            inputs: [{
                                type: 'bytes32',
                                name: 'id',
                            }],
                        }, [idDependency])
                    )
                ])
            );

            const to = accounts[8];
            const value = 2;
            const data = '0x';
            const minGasLimit = 0;
            const maxGasPrice = bn(10).pow(bn(32));
            const salt = '0x2';
            const expiration = await Helper.getBlockTime() + 60;

            const id = await wallet.encodeTransactionData(
                dependencies,
                to,
                value,
                data,
                minGasLimit,
                maxGasPrice,
                salt,
                expiration
            );

            const prevBalanceReceiver = bn(await web3.eth.getBalance(accounts[8]));
            bn(await web3.eth.getBalance(wallet.address)).should.be.a.bignumber.that.equals(bn(2));

            const signature = signHash(id, privs[1]);
            await wallet.relay(
                dependencies,
                to,
                value,
                data,
                minGasLimit,
                maxGasPrice,
                salt,
                expiration,
                signature
            );

            bn(await web3.eth.getBalance(wallet.address)).should.be.a.bignumber.that.equals(bn(0));
            bn(await web3.eth.getBalance(accounts[8])).sub(prevBalanceReceiver)
                .should.be.a.bignumber.that.equals(bn(2));
        });
        it('Should fail to relay if dependencies are not filled', async function () {
            const wallet = await Marmo.at(await creator.marmoOf(accounts[1]));
            const ddependencies = "0x";
            const dto = accounts[9];
            const dvalue = 1;
            const ddata = '0x';
            const dminGasLimit = 0;
            const dmaxGasPrice = bn(10).pow(bn(32));
            const dsalt = '0xaaaaaa12';
            const dexpiration = bn(10).pow(bn(24));

            const idDependency = await wallet.encodeTransactionData(
                ddependencies,
                dto,
                dvalue,
                ddata,
                dminGasLimit,
                dmaxGasPrice,
                dsalt,
                dexpiration
            );

            const dependencies = eutils.bufferToHex(
                Buffer.concat([
                    eutils.toBuffer(wallet.address),
                    eutils.toBuffer(
                        web3.eth.abi.encodeFunctionCall({
                            name: 'relayedBy',
                            type: 'function',
                            inputs: [{
                                type: 'bytes32',
                                name: 'id',
                            }],
                        }, [idDependency])
                    )
                ])
            );

            const to = accounts[9];
            const value = 1;
            const data = '0x';
            const minGasLimit = 0;
            const maxGasPrice = bn(10).pow(bn(32));
            const salt = '0x3';
            const expiration = await Helper.getBlockTime() + 60;

            const id = await wallet.encodeTransactionData(
                dependencies,
                to,
                value,
                data,
                minGasLimit,
                maxGasPrice,
                salt,
                expiration
            );

            const signature = signHash(id, privs[1]);
            await Helper.tryCatchRevert(wallet.relay(
                dependencies,
                to,
                value,
                data,
                minGasLimit,
                maxGasPrice,
                salt,
                expiration,
                signature
            ), 'Dependencies are not satisfied');
        });
        it('Should fail to relay is intent is already relayed', async function () {
            const wallet = await Marmo.at(await creator.marmoOf(accounts[1]));
            const dependencies = "0x";
            const to = accounts[9];
            const value = 0;
            const data = '0x';
            const minGasLimit = 0;
            const maxGasPrice = bn(10).pow(bn(32));
            const salt = '0x4';
            const expiration = bn(10).pow(bn(24));

            const id = await wallet.encodeTransactionData(
                dependencies,
                to,
                value,
                data,
                minGasLimit,
                maxGasPrice,
                salt,
                expiration
            );

            const signature = signHash(id, privs[1]);

            await wallet.relay(
                dependencies,
                to,
                value,
                data,
                minGasLimit,
                maxGasPrice,
                salt,
                expiration,
                signature
            );

            await Helper.tryCatchRevert(wallet.relay(
                dependencies,
                to,
                value,
                data,
                minGasLimit,
                maxGasPrice,
                salt,
                expiration,
                signature
            ), 'Intent already relayed');
        });
        it('Should relay sending intent from signer (without signature)', async function () {
            const wallet = await Marmo.at(await creator.marmoOf(accounts[1]));
            await web3.eth.sendTransaction({ from: accounts[0], to: wallet.address, value: 1 });

            const dependencies = "0x";
            const to = accounts[9];
            const value = 1;
            const data = '0x';
            const minGasLimit = 0;
            const maxGasPrice = bn(10).pow(bn(32));
            const salt = '0x';
            const expiration = await Helper.getBlockTime() + 60;

            const prevBalanceReceiver = bn(await web3.eth.getBalance(accounts[9]));
            bn(await web3.eth.getBalance(wallet.address)).should.be.a.bignumber.that.equals(bn(1));

            await wallet.relay(
                dependencies,
                to,
                value,
                data,
                minGasLimit,
                maxGasPrice,
                salt,
                expiration,
                '0x',
                {
                    from: accounts[1],
                }
            );

            bn(await web3.eth.getBalance(wallet.address)).should.be.a.bignumber.that.equals(bn(0));
            bn(await web3.eth.getBalance(accounts[9])).sub(prevBalanceReceiver)
                .should.be.a.bignumber.that.equals(bn(1));
        });
        it('Should fail to relay with low gas limit', async function () {
            const wallet = await Marmo.at(await creator.marmoOf(accounts[1]));
            await testToken.setBalance(wallet.address, 10);
            await testToken.setBalance(accounts[9], 0);

            const dependencies = "0x";
            const to = testToken.address;
            const value = 0;
            const data = web3.eth.abi.encodeFunctionCall({
                name: 'transfer',
                type: 'function',
                inputs: [{
                    type: 'address',
                    name: 'to',
                }, {
                    type: 'uint256',
                    name: 'value',
                }],
            }, [accounts[9], 4]);

            const minGasLimit = bn(7000000);
            const maxGasPrice = bn(10).pow(bn(32));
            const salt = '0x6';
            const expiration = await Helper.getBlockTime() + 60;

            const id = await wallet.encodeTransactionData(
                dependencies,
                to,
                value,
                data,
                minGasLimit,
                maxGasPrice,
                salt,
                expiration
            );

            const signature = signHash(id, privs[1]);
            await Helper.tryCatchRevert(wallet.relay(
                dependencies,
                to,
                value,
                data,
                minGasLimit,
                maxGasPrice,
                salt,
                expiration,
                signature
            ), 'gasleft too low');

            bn(await testToken.balanceOf(accounts[9])).should.be.a.bignumber.that.equals(bn(0));
            bn(await testToken.balanceOf(wallet.address)).should.be.a.bignumber.that.equals(bn(10));
        });
        it('Should fail to relay with high gas price', async function () {
            const wallet = await Marmo.at(await creator.marmoOf(accounts[1]));
            await testToken.setBalance(wallet.address, 10);
            await testToken.setBalance(accounts[9], 0);

            const dependencies = "0x";
            const to = testToken.address;
            const value = 0;
            const data = web3.eth.abi.encodeFunctionCall({
                name: 'transfer',
                type: 'function',
                inputs: [{
                    type: 'address',
                    name: 'to',
                }, {
                    type: 'uint256',
                    name: 'value',
                }],
            }, [accounts[9], 4]);

            const minGasLimit = bn(0);
            const maxGasPrice = bn(5);
            const salt = '0x6';
            const expiration = await Helper.getBlockTime() + 60;

            const id = await wallet.encodeTransactionData(
                dependencies,
                to,
                value,
                data,
                minGasLimit,
                maxGasPrice,
                salt,
                expiration
            );

            const signature = signHash(id, privs[1]);
            await Helper.tryCatchRevert(wallet.relay(
                dependencies,
                to,
                value,
                data,
                minGasLimit,
                maxGasPrice,
                salt,
                expiration,
                signature
            ), 'Gas price too high');

            bn(await testToken.balanceOf(accounts[9])).should.be.a.bignumber.that.equals(bn(0));
            bn(await testToken.balanceOf(wallet.address)).should.be.a.bignumber.that.equals(bn(10));
        });
        it('Should fail to relay if expired', async function () {
            const wallet = await Marmo.at(await creator.marmoOf(accounts[1]));
            await testToken.setBalance(wallet.address, 10);
            await testToken.setBalance(accounts[9], 0);

            const dependencies = "0x";
            const to = testToken.address;
            const value = 0;
            const data = web3.eth.abi.encodeFunctionCall({
                name: 'transfer',
                type: 'function',
                inputs: [{
                    type: 'address',
                    name: 'to',
                }, {
                    type: 'uint256',
                    name: 'value',
                }],
            }, [accounts[9], 4]);

            const minGasLimit = bn(0);
            const maxGasPrice = bn(10).pow(bn(32));
            const salt = '0x9';
            const expiration = await Helper.getBlockTime() - 60;

            const id = await wallet.encodeTransactionData(
                dependencies,
                to,
                value,
                data,
                minGasLimit,
                maxGasPrice,
                salt,
                expiration
            );

            const signature = signHash(id, privs[1]);
            await Helper.tryCatchRevert(wallet.relay(
                dependencies,
                to,
                value,
                data,
                minGasLimit,
                maxGasPrice,
                salt,
                expiration,
                signature
            ), 'Intent is expired');

            bn(await testToken.balanceOf(accounts[9])).should.be.a.bignumber.that.equals(bn(0));
            bn(await testToken.balanceOf(wallet.address)).should.be.a.bignumber.that.equals(bn(10));
        });
        it('Should save relayed block number', async function () {
            const wallet = await Marmo.at(await creator.marmoOf(accounts[1]));

            const dependencies = "0x";
            const to = wallet.address;
            const value = 0;
            const data = '0x';
            const minGasLimit = bn(0);
            const maxGasPrice = bn(10).pow(bn(32));
            const salt = '0x10';
            const expiration = await Helper.getBlockTime() + 180;

            const id = await wallet.encodeTransactionData(
                dependencies,
                to,
                value,
                data,
                minGasLimit,
                maxGasPrice,
                salt,
                expiration
            );

            const signature = signHash(id, privs[1]);
            await wallet.relay(
                dependencies,
                to,
                value,
                data,
                minGasLimit,
                maxGasPrice,
                salt,
                expiration,
                signature
            );

            bn(await wallet.relayedAt(id)).should.be.a.bignumber.that.equals(bn(await web3.eth.getBlockNumber()));
        });
        it('Should save relayed by', async function () {
            const wallet = await Marmo.at(await creator.marmoOf(accounts[1]));

            const dependencies = "0x";
            const to = wallet.address;
            const value = 0;
            const data = '0x';
            const minGasLimit = bn(0);
            const maxGasPrice = bn(10).pow(bn(32));
            const salt = '0x11';
            const expiration = await Helper.getBlockTime() + 180;

            const id = await wallet.encodeTransactionData(
                dependencies,
                to,
                value,
                data,
                minGasLimit,
                maxGasPrice,
                salt,
                expiration
            );

            const signature = signHash(id, privs[1]);
            await wallet.relay(
                dependencies,
                to,
                value,
                data,
                minGasLimit,
                maxGasPrice,
                salt,
                expiration,
                signature
            );

            (await wallet.relayedBy(id)).should.be.equals(accounts[0]);
        });
        it('Should not fail relay if call fails', async function () {
            const wallet = await Marmo.at(await creator.marmoOf(accounts[1]));
            await testToken.setBalance(wallet.address, 10);
            await testToken.setBalance(accounts[9], 0);

            const dependencies = "0x";
            const to = testToken.address;
            const value = 0;
            const data = web3.eth.abi.encodeFunctionCall({
                name: 'transfer',
                type: 'function',
                inputs: [{
                    type: 'address',
                    name: 'to',
                }, {
                    type: 'uint256',
                    name: 'value',
                }],
            }, [accounts[9], 11]);

            const minGasLimit = bn(0);
            const maxGasPrice = bn(10).pow(bn(32));
            const salt = '0x12';
            const expiration = await Helper.getBlockTime() + 240;

            const id = await wallet.encodeTransactionData(
                dependencies,
                to,
                value,
                data,
                minGasLimit,
                maxGasPrice,
                salt,
                expiration
            );

            const signature = signHash(id, privs[1]);
            await wallet.relay(
                dependencies,
                to,
                value,
                data,
                minGasLimit,
                maxGasPrice,
                salt,
                expiration,
                signature
            );

            (await wallet.relayedBy(id)).should.be.equals(accounts[0]);
            bn(await testToken.balanceOf(accounts[9])).should.be.a.bignumber.that.equals(bn(0));
            bn(await testToken.balanceOf(wallet.address)).should.be.a.bignumber.that.equals(bn(10));
        });
    });
    describe('Cancel intents', function () {
        it('Should cancel intent and fail to relay', async function () {
            const wallet = await Marmo.at(await creator.marmoOf(accounts[1]));

            // Create transfer intent
            await testToken.setBalance(wallet.address, 10);
            await testToken.setBalance(accounts[9], 0);

            const dependencies = "0x";
            const to = testToken.address;
            const value = 0;
            const data = web3.eth.abi.encodeFunctionCall({
                name: 'transfer',
                type: 'function',
                inputs: [{
                    type: 'address',
                    name: 'to',
                }, {
                    type: 'uint256',
                    name: 'value',
                }],
            }, [accounts[9], 3]);

            const minGasLimit = bn(0);
            const maxGasPrice = bn(10).pow(bn(32));
            const salt = '0x13';
            const expiration = await Helper.getBlockTime() + 86400;

            const id = await wallet.encodeTransactionData(
                dependencies,
                to,
                value,
                data,
                minGasLimit,
                maxGasPrice,
                salt,
                expiration
            );

            const signature = signHash(id, privs[1]);

            // Create cancel intent
            const cdependencies = "0x";
            const cto = wallet.address;
            const cvalue = 0;
            const cdata = web3.eth.abi.encodeFunctionCall({
                name: 'cancel',
                type: 'function',
                inputs: [{
                    type: 'bytes32',
                    name: '_id',
                }],
            }, [id]);

            const cminGasLimit = bn(0);
            const cmaxGasPrice = bn(10).pow(bn(32));
            const csalt = '0x14';
            const cexpiration = await Helper.getBlockTime() + 86400;

            const cid = await wallet.encodeTransactionData(
                cdependencies,
                cto,
                cvalue,
                cdata,
                cminGasLimit,
                cmaxGasPrice,
                csalt,
                cexpiration
            );

            const csignature = signHash(cid, privs[1]);

            await wallet.relay(
                cdependencies,
                cto,
                cvalue,
                cdata,
                cminGasLimit,
                cmaxGasPrice,
                csalt,
                cexpiration,
                csignature
            );

            (await wallet.isCanceled(id)).should.be.equals(true);

            // Try to relay transfer
            await Helper.tryCatchRevert(wallet.relay(
                dependencies,
                to,
                value,
                data,
                minGasLimit,
                maxGasPrice,
                salt,
                expiration,
                signature
            ), 'Intent was canceled');

            bn(await testToken.balanceOf(accounts[9])).should.be.a.bignumber.that.equals(bn(0));
            bn(await testToken.balanceOf(wallet.address)).should.be.a.bignumber.that.equals(bn(10));
        });
        it('Should fail to cancel intent from different wallet', async function () {
            const wallet = await Marmo.at(await creator.marmoOf(accounts[1]));

            // Create transfer intent
            await testToken.setBalance(wallet.address, 10);
            await testToken.setBalance(accounts[9], 0);

            const dependencies = "0x";
            const to = testToken.address;
            const value = 0;
            const data = web3.eth.abi.encodeFunctionCall({
                name: 'transfer',
                type: 'function',
                inputs: [{
                    type: 'address',
                    name: 'to',
                }, {
                    type: 'uint256',
                    name: 'value',
                }],
            }, [accounts[9], 3]);

            const minGasLimit = bn(0);
            const maxGasPrice = bn(10).pow(bn(32));
            const salt = '0x14';
            const expiration = await Helper.getBlockTime() + 86400;

            const id = await wallet.encodeTransactionData(
                dependencies,
                to,
                value,
                data,
                minGasLimit,
                maxGasPrice,
                salt,
                expiration
            );

            const signature = signHash(id, privs[1]);

            // Try to cancel intent
            await Helper.tryCatchRevert(wallet.cancel(id), 'Only wallet can cancel txs');
            (await wallet.isCanceled(id)).should.be.equals(false);

            // Relay ERC20 transfer should success
            await wallet.relay(
                dependencies,
                to,
                value,
                data,
                minGasLimit,
                maxGasPrice,
                salt,
                expiration,
                signature
            );

            bn(await testToken.balanceOf(accounts[9])).should.be.a.bignumber.that.equals(bn(3));
            bn(await testToken.balanceOf(wallet.address)).should.be.a.bignumber.that.equals(bn(7));
        });
        it('Should fail to cancel intent if already relayed', async function () {
            const wallet = await Marmo.at(await creator.marmoOf(accounts[1]));

            // Create transfer intent
            await testToken.setBalance(wallet.address, 10);
            await testToken.setBalance(accounts[9], 0);

            const dependencies = "0x";
            const to = wallet.address;
            const value = 0;
            const data = '0x';
            const minGasLimit = bn(0);
            const maxGasPrice = bn(10).pow(bn(32));
            const salt = '0x16';
            const expiration = await Helper.getBlockTime() + 86400;

            const id = await wallet.encodeTransactionData(
                dependencies,
                to,
                value,
                data,
                minGasLimit,
                maxGasPrice,
                salt,
                expiration
            );

            const signature = signHash(id, privs[1]);

            // Relay intent
            await wallet.relay(
                dependencies,
                to,
                value,
                data,
                minGasLimit,
                maxGasPrice,
                salt,
                expiration,
                signature
            );

            // Create cancel intent
            const cdependencies = "0x";
            const cto = wallet.address;
            const cvalue = 0;
            const cdata = web3.eth.abi.encodeFunctionCall({
                name: 'cancel',
                type: 'function',
                inputs: [{
                    type: 'bytes32',
                    name: '_id',
                }],
            }, [id]);

            const cminGasLimit = bn(0);
            const cmaxGasPrice = bn(10).pow(bn(32));
            const csalt = '0x17';
            const cexpiration = await Helper.getBlockTime() + 86400;

            const cid = await wallet.encodeTransactionData(
                cdependencies,
                cto,
                cvalue,
                cdata,
                cminGasLimit,
                cmaxGasPrice,
                csalt,
                cexpiration
            );

            const csignature = signHash(cid, privs[1]);

            const cancelReceipt = await wallet.relay(
                cdependencies,
                cto,
                cvalue,
                cdata,
                cminGasLimit,
                cmaxGasPrice,
                csalt,
                cexpiration,
                csignature
            );

            (await wallet.isCanceled(id)).should.be.equals(false);
            (await wallet.relayedBy(id)).should.be.equals(accounts[0]);
            (cancelReceipt.logs[0].args._success).should.be.equals(false);
        });
        it('Should fail to cancel intent if already canceled', async function () {
            const wallet = await Marmo.at(await creator.marmoOf(accounts[1]));

            // Create transfer intent
            await testToken.setBalance(wallet.address, 10);
            await testToken.setBalance(accounts[9], 0);

            const dependencies = "0x";
            const to = wallet.address;
            const value = 0;
            const data = '0x';
            const minGasLimit = bn(0);
            const maxGasPrice = bn(10).pow(bn(32));
            const salt = '0x19';
            const expiration = await Helper.getBlockTime() + 86400;

            const id = await wallet.encodeTransactionData(
                dependencies,
                to,
                value,
                data,
                minGasLimit,
                maxGasPrice,
                salt,
                expiration
            );

            // Create cancel intent
            const cdependencies = "0x";
            const cto = wallet.address;
            const cvalue = 0;
            const cdata = web3.eth.abi.encodeFunctionCall({
                name: 'cancel',
                type: 'function',
                inputs: [{
                    type: 'bytes32',
                    name: '_id',
                }],
            }, [id]);

            const cminGasLimit = bn(0);
            const cmaxGasPrice = bn(10).pow(bn(32));
            const csalt = '0x17';
            const cexpiration = await Helper.getBlockTime() + 86400;

            const cid = await wallet.encodeTransactionData(
                cdependencies,
                cto,
                cvalue,
                cdata,
                cminGasLimit,
                cmaxGasPrice,
                csalt,
                cexpiration
            );

            const c2dependencies = "0x";
            const c2to = wallet.address;
            const c2value = 0;
            const c2data = web3.eth.abi.encodeFunctionCall({
                name: 'cancel',
                type: 'function',
                inputs: [{
                    type: 'bytes32',
                    name: '_id',
                }],
            }, [id]);

            const c2minGasLimit = bn(0);
            const c2maxGasPrice = bn(10).pow(bn(32));
            const c2salt = '0x18';
            const c2expiration = await Helper.getBlockTime() + 86400;

            const c2id = await wallet.encodeTransactionData(
                c2dependencies,
                c2to,
                c2value,
                c2data,
                c2minGasLimit,
                c2maxGasPrice,
                c2salt,
                c2expiration
            );

            const csignature = signHash(cid, privs[1]);
            const c2signature = signHash(c2id, privs[1]);

            const cancelReceipt1 = await wallet.relay(
                cdependencies,
                cto,
                cvalue,
                cdata,
                cminGasLimit,
                cmaxGasPrice,
                csalt,
                cexpiration,
                csignature
            );

            const cancelReceipt2 = await wallet.relay(
                c2dependencies,
                c2to,
                c2value,
                c2data,
                c2minGasLimit,
                c2maxGasPrice,
                c2salt,
                c2expiration,
                c2signature
            );

            (await wallet.isCanceled(id)).should.be.equals(true);
            (cancelReceipt1.logs[0].args._success).should.be.equals(true);
            (cancelReceipt2.logs[0].args._success).should.be.equals(false);
        });
    });
});
