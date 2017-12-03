/* global artifacts */
/* global contract */
/* global web3 */
/* global assert */

const assertFail = require("./helpers/assertFail.js");

const AxeTest  = artifacts.require("../AxeTest.sol");
const CageTest = artifacts.require("../CageTest.sol");
const DSAuthTest = artifacts.require("../DSAuthTest.sol");
const DSGuardTest = artifacts.require("../DSGuardTest.sol");
const DSMathTest  = artifacts.require("../DSMathTest.sol");
const DSNoteTest = artifacts.require("../DSNoteTest.sol");
const DSStopTest = artifacts.require("../DSStopTest.sol");
const DSTokenTest = artifacts.require("../DSTokenTest.sol");
const DSValueTest = artifacts.require("../DSValueTest.sol");
const FeeTest = artifacts.require("../FeeTest.sol");
const GasTest = artifacts.require("../GasTest.sol");
const LiquidationTest = artifacts.require("../LiquidationTest.sol");
const SaiTubTest = artifacts.require("../SaiTubTest.sol");
const TubTest= artifacts.require("../TubTest.sol");
const VoxTest = artifacts.require("../VoxTest.sol");

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

    it("DSStopTest", async () => { await dotests(DSStopTest) })
    it("DSNoteTest", async () => { await dotests(DSNoteTest) })
    it("AxeTest", async () => { await dotests(AxeTest) })
    it("CageTest", async () => { await dotests(CageTest) })
    it("DSAuthTest", async () => { await dotests(DSAuthTest) })
    it("DSGuardTest", async () => { await dotests(DSGuardTest) })
    it("DSMathTest", async () => { await dotests(DSMathTest) })
    it("DSTokenTest", async () => { await dotests(DSTokenTest) })
    it("DSValueTest", async () => { await dotests(DSValueTest) })
    it("FeeTest", async () => { await dotests(FeeTest) })
    it("GasTest", async () => { await dotests(GasTest) })
    it("LiquidationTest", async () => { await dotests(LiquidationTest) })
    it("SaiTubTest", async () => { await dotests(SaiTubTest) })
    it("TubTest", async () => { await dotests(TubTest) })
    it("VoxTest", async () => { await dotests(VoxTest) })

})

