pragma solidity ^0.4.18;

import "./SaiTestBase.sol";

contract SaiTubTest is SaiTestBase {
    function testBasic() public {
        assertEq( skr.balanceOf(tub), 0 ether );
        assertEq( skr.balanceOf(this), 0 ether );
        assertEq( gem.balanceOf(tub), 0 ether );

        // edge case
        assertEq( uint256(tub.per()), ray(1 ether) );
        tub.join(10 ether);
        assertEq( uint256(tub.per()), ray(1 ether) );

        assertEq( skr.balanceOf(this), 10 ether );
        assertEq( gem.balanceOf(tub), 10 ether );
        // price formula
        tub.join(10 ether);
        assertEq( uint256(tub.per()), ray(1 ether) );
        assertEq( skr.balanceOf(this), 20 ether );
        assertEq( gem.balanceOf(tub), 20 ether );

        var cup = tub.open();

        assertEq( skr.balanceOf(this), 20 ether );
        assertEq( skr.balanceOf(tub), 0 ether );
        tub.lock(cup, 10 ether); // lock skr token
        assertEq( skr.balanceOf(this), 10 ether );
        assertEq( skr.balanceOf(tub), 10 ether );

        assertEq( sai.balanceOf(this), 0 ether);
        tub.draw(cup, 5 ether);
        assertEq( sai.balanceOf(this), 5 ether);


        assertEq( sai.balanceOf(this), 5 ether);
        tub.wipe(cup, 2 ether);
        assertEq( sai.balanceOf(this), 3 ether);

        assertEq( sai.balanceOf(this), 3 ether);
        assertEq( skr.balanceOf(this), 10 ether );
        tub.shut(cup);
        assertEq( sai.balanceOf(this), 0 ether);
        assertEq( skr.balanceOf(this), 20 ether );
    }
    function testMold() public {
        var setAxe = bytes4(keccak256('setAxe(uint256)'));
        var setCap = bytes4(keccak256('setCap(uint256)'));
        var setMat = bytes4(keccak256('setMat(uint256)'));

        assertTrue(mom.call(setCap, 0 ether));
        assertTrue(mom.call(setCap, 5 ether));

        assertTrue(!mom.call(setAxe, ray(2 ether)));
        assertTrue( mom.call(setMat, ray(2 ether)));
        assertTrue( mom.call(setAxe, ray(2 ether)));
        assertTrue(!mom.call(setMat, ray(1 ether)));
    }
    function testPriceFeedSetters() public {
        var setPip = bytes4(keccak256('setPip(address)'));
        var setPep = bytes4(keccak256('setPep(address)'));
        var setVox = bytes4(keccak256('setVox(address)'));

        assertTrue(tub.pip() != address(0x1));
        assertTrue(tub.pep() != address(0x2));
        assertTrue(tub.vox() != address(0x3));
        assertTrue(mom.call(setPip, address(0x1)));
        assertTrue(mom.call(setPep, address(0x2)));
        assertTrue(mom.call(setVox, address(0x3)));
        assertTrue(tub.pip() == address(0x1));
        assertTrue(tub.pep() == address(0x2));
        assertTrue(tub.vox() == address(0x3));
    }
    function testJoinInitial() public {
        assertEq(skr.totalSupply(),     0 ether);
        assertEq(skr.balanceOf(this),   0 ether);
        assertEq(gem.balanceOf(this), 100 ether);
        tub.join(10 ether);
        assertEq(skr.balanceOf(this), 10 ether);
        assertEq(gem.balanceOf(this), 90 ether);
        assertEq(gem.balanceOf(tub),  10 ether);
    }
    function testJoinExit() public {
        assertEq(skr.balanceOf(this), 0 ether);
        assertEq(gem.balanceOf(this), 100 ether);
        tub.join(10 ether);
        assertEq(skr.balanceOf(this), 10 ether);
        assertEq(gem.balanceOf(this), 90 ether);
        assertEq(gem.balanceOf(tub),  10 ether);

        tub.exit(5 ether);
        assertEq(skr.balanceOf(this),  5 ether);
        assertEq(gem.balanceOf(this), 95 ether);
        assertEq(gem.balanceOf(tub),   5 ether);

        tub.join(2 ether);
        assertEq(skr.balanceOf(this),  7 ether);
        assertEq(gem.balanceOf(this), 93 ether);
        assertEq(gem.balanceOf(tub),   7 ether);

        tub.exit(1 ether);
        assertEq(skr.balanceOf(this),  6 ether);
        assertEq(gem.balanceOf(this), 94 ether);
        assertEq(gem.balanceOf(tub),   6 ether);
    }
    function testFailOverDraw() public {
        mom.setMat(ray(1 ether));
        tub.join(10 ether);
        var cup = tub.open();
        tub.lock(cup, 10 ether);

        tub.draw(cup, 11 ether);
    }
    function testFailOverDrawExcess() public {
        mom.setMat(ray(1 ether));
        tub.join(20 ether);
        var cup = tub.open();
        tub.lock(cup, 10 ether);

        tub.draw(cup, 11 ether);
    }
    function testDraw() public {
        mom.setMat(ray(1 ether));
        tub.join(10 ether);
        var cup = tub.open();
        tub.lock(cup, 10 ether);

        assertEq(sai.balanceOf(this),  0 ether);
        tub.draw(cup, 10 ether);
        assertEq(sai.balanceOf(this), 10 ether);
    }
    function testWipe() public {
        mom.setMat(ray(1 ether));
        tub.join(10 ether);
        var cup = tub.open();
        tub.lock(cup, 10 ether);
        tub.draw(cup, 10 ether);

        assertEq(sai.balanceOf(this), 10 ether);
        tub.wipe(cup, 5 ether);
        assertEq(sai.balanceOf(this),  5 ether);
    }
    function testUnsafe() public {
        tub.join(10 ether);
        var cup = tub.open();
        tub.lock(cup, 10 ether);
        tub.draw(cup, 9 ether);

        assertTrue(tub.safe(cup));
        mark(1 ether / 2);
        assertTrue(!tub.safe(cup));
    }
    function testBiteUnderParity() public {
        assertEq(uint(tub.axe()), uint(ray(1 ether)));  // 100% collateralisation limit
        tub.join(10 ether);
        var cup = tub.open();
        tub.lock(cup, 10 ether);
        tub.draw(cup, 5 ether);           // 200% collateralisation
        mark(1 ether / 4);                // 50% collateralisation

        assertEq(tap.fog(), uint(0));
        tub.bite(cup);
        assertEq(tap.fog(), uint(10 ether));
    }
    function testBiteOverParity() public {
        mom.setMat(ray(2 ether));  // require 200% collateralisation
        tub.join(10 ether);
        var cup = tub.open();
        tub.lock(cup, 10 ether);

        tub.draw(cup, 4 ether);  // 250% collateralisation
        assertTrue(tub.safe(cup));
        mark(1 ether / 2);       // 125% collateralisation
        assertTrue(!tub.safe(cup));

        assertEq(tub.din(),    4 ether);
        assertEq(tub.tab(cup), 4 ether);
        assertEq(tap.fog(),    0 ether);
        assertEq(tap.woe(),    0 ether);
        tub.bite(cup);
        assertEq(tub.din(),    0 ether);
        assertEq(tub.tab(cup), 0 ether);
        assertEq(tap.fog(),    8 ether);
        assertEq(tap.woe(),    4 ether);

        // cdp should now be safe with 0 sai debt and 2 skr remaining
        var skr_before = skr.balanceOf(this);
        tub.free(cup, 1 ether);
        assertEq(skr.balanceOf(this) - skr_before, 1 ether);
    }
    function testLock() public {
        tub.join(10 ether);
        var cup = tub.open();

        assertEq(skr.balanceOf(tub),  0 ether);
        tub.lock(cup, 10 ether);
        assertEq(skr.balanceOf(tub), 10 ether);
    }
    function testFree() public {
        mom.setMat(ray(2 ether));  // require 200% collateralisation
        tub.join(10 ether);
        var cup = tub.open();
        tub.lock(cup, 10 ether);
        tub.draw(cup, 4 ether);  // 250% collateralisation

        var skr_before = skr.balanceOf(this);
        tub.free(cup, 2 ether);  // 225%
        assertEq(skr.balanceOf(this) - skr_before, 2 ether);
    }
    function testFailFreeToUnderCollat() public {
        mom.setMat(ray(2 ether));  // require 200% collateralisation
        tub.join(10 ether);
        var cup = tub.open();
        tub.lock(cup, 10 ether);
        tub.draw(cup, 4 ether);  // 250% collateralisation

        tub.free(cup, 3 ether);  // 175% -- fails
    }
    function testFailDrawOverDebtCeiling() public {
        mom.setCap(4 ether);
        tub.join(10 ether);
        var cup = tub.open();
        tub.lock(cup, 10 ether);

        tub.draw(cup, 5 ether);
    }
    function testDebtCeiling() public {
        mom.setCap(5 ether);
        mom.setMat(ray(2 ether));  // require 200% collat
        tub.join(10 ether);
        var cup = tub.open();
        tub.lock(cup, 10 ether);

        tub.draw(cup, 5 ether);          // 200% collat, full debt ceiling
        mark(1 ether / 2);  // 100% collat

        assertEq(tub.air(), uint(10 ether));
        assertEq(tap.fog(), uint(0 ether));
        tub.bite(cup);
        assertEq(tub.air(), uint(0 ether));
        assertEq(tap.fog(), uint(10 ether));

        tub.join(10 ether);
        // skr hasn't been diluted yet so still 1:1 skr:gem
        assertEq(skr.balanceOf(this), 10 ether);
    }
}