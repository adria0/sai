module.exports = {
    // port: 6545,
    // testrpcOptions: '-p 6545 -u 0x54fd80d6ae7584d8e9a19fe1df43f04e5282cc43',
    testrpcOptions: '-g 1 -l 0xfffffffffff',
    testCommand: 'truffle test',
    skipFiles: ['AxeTest.sol','DSMathTest.sol','DSTokenBaseTest.sol','GasTest.sol','TubTest.sol',
		'CageTest.sol','DSNoteTest.sol','DSTokenTest.sol','LiquidationTest.sol','VoxTest.sol',
		'DSAuthTest.sol','DSStopTest.sol','DSValueTest.sol','SaiTestBase.sol',
		'DSGuardTest.sol','DSTest.sol','FeeTest.sol','SaiTubTest.sol']

};
