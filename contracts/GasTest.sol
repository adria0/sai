pragma solidity ^0.4.15;

import "./SaiTestBase.sol";

contract GasTest is SaiTestBase {
    bytes32 cup;
    function setUp() public {
        super.setUp();

        mark(1 ether);
        gem.mint(1000 ether);

        mom.setHat(1000 ether);

        cup = tub.open();
        tub.join(1000 ether);
        tub.lock(cup, 500 ether);
        tub.draw(cup, 100 ether);
    }
    function doLock(uint256 wad) public logs_gas {
        tub.lock(cup, wad);
    }
    function doFree(uint256 wad) public logs_gas {
        tub.free(cup, wad);
    }
    function doDraw(uint256 wad) public logs_gas {
        tub.draw(cup, wad);
    }
    function doWipe(uint256 wad) public logs_gas {
        tub.wipe(cup, wad);
    }
    function doDrip() public logs_gas {
        tub.drip();
    }
    function doBoom(uint256 wad) public logs_gas {
        tap.boom(wad);
    }

    uint256 tic = 15 seconds;

    function testGasLock() public {
        warp(tic);
        doLock(100 ether);
        // assertTrue(false);
    }
    function testGasFree() public {
        warp(tic);
        doFree(100 ether);
        // assertTrue(false);
    }
    function testGasDraw() public {
        warp(tic);
        doDraw(100 ether);
        // assertTrue(false);
    }
    function testGasWipe() public {
        warp(tic);
        doWipe(100 ether);
        // assertTrue(false);
    }
    function testGasBoom() public {
        warp(tic);
        tub.join(10 ether);
        sai.mint(100 ether);
        sai.push(tap, 100 ether);
        skr.approve(tap, uint(-1));
        doBoom(1 ether);
        // assertTrue(false);
    }
    function testGasBoomHeal() public {
        warp(tic);
        tub.join(10 ether);
        sai.mint(100 ether);
        sin.mint(100 ether);
        sai.push(tap, 100 ether);
        sin.push(tap,  50 ether);
        skr.approve(tap, uint(-1));
        doBoom(1 ether);
        // assertTrue(false);
    }
    function testGasDripNoop() public {
        tub.drip();
        doDrip();
    }
    function testGasDrip1s() public {
        warp(1 seconds);
        doDrip();
    }
    function testGasDrip1m() public {
        warp(1 minutes);
        doDrip();
    }
    function testGasDrip1h() public {
        warp(1 hours);
        doDrip();
    }
    function testGasDrip1d() public {
        warp(1 days);
        doDrip();
    }
}
