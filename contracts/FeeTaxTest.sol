pragma solidity ^0.4.18;

import "./SaiTestBase.sol";

contract FeeTaxTest is SaiTestBase {
    function feeSetup() public returns (bytes32 cup) {
        mark(10 ether);
        mark(gov, 1 ether / 2);
        gem.mint(1000 ether);
        gov.mint(100 ether);

        mom.setCap(1000 ether);
        mom.setFee(1000000564701133626865910626);  // 5% / day
        mom.setTax(1000000564701133626865910626);  // 5% / day

        // warp(1 days);  // make chi,rhi != 1

        cup = tub.open();
        tub.join(100 ether);
        tub.lock(cup, 100 ether);
        tub.draw(cup, 100 ether);
    }
    function testFeeTaxDrip() public {
        feeSetup();
        warp(1 days);
        assertEq(tub.chi() / 10 ** 9, 1.0500 ether);
        assertEq(tub.rhi() / 10 ** 9, 1.1025 ether);
    }
    // Unpaid fees do not accumulate as sin
    function testFeeTaxIce() public {
        var cup = feeSetup();

        assertEq(tub.tab(cup), 100 ether);
        assertEq(tub.rap(cup),   0 ether);

        assertEq(tub.din(),    100 ether);
        assertEq(tap.joy(),      0 ether);

        warp(1 days);

        assertEq(tub.tab(cup), 105 ether);
        assertEq(tub.rap(cup),   5.25 ether);

        assertEq(tub.din(),    105 ether);
        assertEq(tap.joy(),      5 ether);
    }
    function testFeeTaxDraw() public {
        var cup = feeSetup();
        warp(1 days);
        assertEq(tub.tab(cup), 105 ether);
        tub.draw(cup, 100 ether);
        assertEq(tub.tab(cup), 205 ether);
    }
    function testFeeTaxCalcFromRap() public {
        var cup = feeSetup();

        assertEq(tub.tab(cup), 100.00 ether);
        assertEq(tub.rap(cup),   0.00 ether);
        warp(1 days);
        assertEq(tub.tab(cup), 105.00 ether);
        assertEq(tub.rap(cup),   5.25 ether);
    }
    function testFeeTaxWipeAll() public {
        var cup = feeSetup();
        warp(1 days);

        var wad = tub.tab(cup);
        assertEq(wad, 105 ether);
        var owe = tub.rap(cup);
        assertEq(owe, 5.25 ether);

        var ( , , art, ire) = tub.cups(cup);
        assertEq(art, 100 ether);
        assertEq(ire, 100 ether);
        assertEq(rdiv(wad, tub.chi()), art);
        assertEq(rdiv(add(wad, owe), tub.rhi()), ire);

        sai.mint(5 ether);  // need to magic up some extra sai to pay tax

        assertEq(tub.rap(cup), 5.25 ether);
        assertEq(gov.balanceOf(this), 100 ether);
        tub.wipe(cup, 105 ether);
        assertEq(tub.rap(cup), 0 ether);
        assertEq(gov.balanceOf(this), 89.5 ether);
    }
}