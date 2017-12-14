pragma solidity ^0.4.18;

import "./SaiTestBase.sol";

contract FeeTest is SaiTestBase {
    function feeSetup() public returns (bytes32 cup) {
        mark(10 ether);
        mark(gov, 1 ether / 2);
        gem.mint(1000 ether);
        gov.mint(100 ether);

        mom.setCap(1000 ether);
        mom.setFee(1000000564701133626865910626);  // 5% / day

        // warp(1 days);  // make chi,rhi != 1

        cup = tub.open();
        tub.join(100 ether);
        tub.lock(cup, 100 ether);
        tub.draw(cup, 100 ether);
    }
    function testFeeSet() public {
        assertEq(tub.fee(), ray(1 ether));
        mom.setFee(ray(1.000000001 ether));
        assertEq(tub.fee(), ray(1.000000001 ether));
    }
    function testFeeSetup() public {
        feeSetup();
        assertEq(tub.chi(), ray(1 ether));
        assertEq(tub.rhi(), ray(1 ether));
    }
    function testFeeDrip() public {
        feeSetup();
        warp(1 days);
        assertEq(tub.chi() / 10 ** 9, 1.00 ether);
        assertEq(tub.rhi() / 10 ** 9, 1.05 ether);
    }
    // Unpaid fees do not accumulate as sin
    function testFeeIce() public {
        var cup = feeSetup();
        assertEq(tub.din(),    100 ether);
        assertEq(tub.tab(cup), 100 ether);
        assertEq(tub.rap(cup),   0 ether);
        warp(1 days);
        assertEq(tub.din(),    100 ether);
        assertEq(tub.tab(cup), 100 ether);
        assertEq(tub.rap(cup),   5 ether);
    }
    function testFeeDraw() public {
        var cup = feeSetup();
        warp(1 days);
        assertEq(tub.rap(cup),   5 ether);
        tub.draw(cup, 100 ether);
        assertEq(tub.rap(cup),   5 ether);
        warp(1 days);
        assertEq(tub.rap(cup),  15.25 ether);
    }
    function testFeeWipe() public {
        var cup = feeSetup();
        warp(1 days);
        assertEq(tub.rap(cup),   5 ether);
        tub.wipe(cup, 50 ether);
        assertEq(tub.rap(cup),  2.5 ether);
        warp(1 days);
        assertEq(tub.rap(cup),  5.125 ether);
    }
    function testFeeCalcFromRap() public {
        var cup = feeSetup();

        assertEq(tub.tab(cup), 100 ether);
        assertEq(tub.rap(cup),   0 ether);
        warp(1 days);
        assertEq(tub.tab(cup), 100 ether);
        assertEq(tub.rap(cup),   5 ether);
    }
    function testFeeWipePays() public {
        var cup = feeSetup();
        warp(1 days);

        assertEq(tub.rap(cup),   5 ether);
        assertEq(gov.balanceOf(this), 100 ether);
        tub.wipe(cup, 50 ether);
        assertEq(tub.tab(cup), 50 ether);
        assertEq(gov.balanceOf(this), 95 ether);
    }
    function testFeeWipeMoves() public {
        var cup = feeSetup();
        warp(1 days);

        assertEq(gov.balanceOf(this), 100 ether);
        assertEq(gov.balanceOf(pit),    0 ether);
        tub.wipe(cup, 50 ether);
        assertEq(gov.balanceOf(this),  95 ether);
        assertEq(gov.balanceOf(pit),    5 ether);
    }
    function testFeeWipeAll() public {
        var cup = feeSetup();
        warp(1 days);

        var wad = tub.tab(cup);
        assertEq(wad, 100 ether);
        var owe = tub.rap(cup);
        assertEq(owe, 5 ether);

        var ( , , art, ire) = tub.cups(cup);
        assertEq(art, 100 ether);
        assertEq(ire, 100 ether);
        assertEq(rdiv(wad, tub.chi()), art);
        assertEq(rdiv(add(wad, owe), tub.rhi()), ire);

        assertEq(tub.rap(cup),   5 ether);
        assertEq(tub.tab(cup), 100 ether);
        assertEq(gov.balanceOf(this), 100 ether);
        tub.wipe(cup, 100 ether);
        assertEq(tub.rap(cup), 0 ether);
        assertEq(tub.tab(cup), 0 ether);
        assertEq(gov.balanceOf(this), 90 ether);
    }
    function testFeeWipeNoFeed() public {
        var cup = feeSetup();
        pep.void();
        warp(1 days);

        // fees continue to accumulate
        assertEq(tub.rap(cup),   5 ether);

        // gov is no longer taken
        assertEq(gov.balanceOf(this), 100 ether);
        tub.wipe(cup, 50 ether);
        assertEq(gov.balanceOf(this), 100 ether);

        // fees are still wiped proportionally
        assertEq(tub.rap(cup),  2.5 ether);
        warp(1 days);
        assertEq(tub.rap(cup),  5.125 ether);
    }
    function testFeeWipeShut() public {
        var cup = feeSetup();
        warp(1 days);
        tub.shut(cup);
    }
    function testFeeWipeShutEmpty() public {
        feeSetup();
        var cup = tub.open();
        tub.join(100 ether);
        tub.lock(cup, 100 ether);
        warp(1 days);
        tub.shut(cup);
    }
}
