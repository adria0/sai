/* global artifacts */
/* global contract */
/* global web3 */
/* global assert */

/*

You need to change something in libraries to work

in
    /usr/local/lib/node_modules/truffle/build/cli.bundled.js:317993
change
    if (totalGas.cmp(gasLimit) <= 0 && results.return.length <= 24576)
to 
    if (totalGas.cmp(gasLimit) <= 0)



in
    /usr/local/lib/node_modules/truffle/build/cli.bundled.js:71294
change
    totalGas = totalGas.addn(returnFee)
to
    totalGas = totalGas.add(new BN(returnFee))



*/

const assertFail = require("./helpers/assertFail.js");

const AxeTest  = artifacts.require("../AxeTest.sol");
const BinTest = artifacts.require("../BinTest.sol");
const CageTest = artifacts.require("../CageTest.sol");
const FeeTaxTest = artifacts.require("../FeeTaxTest.sol");
const FeeTest = artifacts.require("../FeeTest.sol");
const GapTest = artifacts.require("../GapTest.sol");
const LiquidationTest = artifacts.require("../LiquidationTest.sol");
const SaiTubTest = artifacts.require("../SaiTubTest.sol");
const TapTest = artifacts.require("../TapTest.sol");
const TaxTest = artifacts.require("../TaxTest.sol");
const TubTest = artifacts.require("../TubTest.sol");
const VoxTest = artifacts.require("../VoxTest.sol");
const WayTest= artifacts.require("../WayTest.sol");


contract("AxeTest", (accounts) => {

    shorten = error => {
        error = error.toString().replace("\n","")
        if (error.length > 100) {
            return error.substr(0,100);
        }
        return error.toString();
    }

    dotests = async contract => {

        let gas = 2000000000

        let hasSetup = false
        let abi

        try {
            abi = (await contract.new( { gas : gas })).abi
        } catch (error) {
            console.log("***FAILED   "+contract.contractName+" Creating instance ",error)
            return
        }

        for (var i = 0; i < abi.length; i++) {
            const f =  abi[i]
            if (f.name == "setUp") {
                hasSetUp = true;
                break;
            }
        }

        for (var i = 0; i < abi.length; i++) {
            const f = abi[i]
            if (f.name.startsWith("test")) {
                const shouldFail = f.name.startsWith("testFail")
                let   phase=""                
                try {
                    phase = "create"
                    let instance = await contract.new( { gas : gas  })
                    phase = "setup"
                    if (hasSetUp) {
                        await instance.setUp( { gas : gas  })
                    }
                    phase = "call"
                    await instance[f.name]({ gas : gas })

                    if (shouldFail) {
                        console.log("*FAILED !fail "+contract.contractName+"."+f.name)
                    } else {
                        console.log("*OK           "+contract.contractName+"."+f.name)
                    }
                } catch (error) {
                    if (shouldFail && phase == "call") {
                        console.log("*OK           "+contract.contractName+"."+f.name)                        
                    } else {
                        console.log("*FAILED  fail "+contract.contractName+"."+f.name,"phase="+phase,shorten(error))
                    }

                }
            }
        }

    }

    it("AxeTest", async () => { await dotests(AxeTest) })
    it("BinTest", async () => { await dotests(BinTest) })
    it("CageTest", async () => { await dotests(CageTest) })
    it("FeeTaxTest", async () => { await dotests(FeeTaxTest) })
    it("FeeTest", async () => { await dotests(FeeTest) })
    it("GapTest", async () => { await dotests(GapTest) })
    it("LiquidationTest", async () => { await dotests(LiquidationTest) })
    it("SaiTubTest", async () => { await dotests(SaiTubTest) })
    it("TapTest", async () => { await dotests(TapTest) })
    it("TaxTest", async () => { await dotests(TaxTest) })
    it("TubTest", async () => { await dotests(TubTest) })
    it("VoxTest", async () => { await dotests(VoxTest) })
    it("WayTest", async () => { await dotests(WayTest) })

})

