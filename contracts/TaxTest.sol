pragma solidity ^0.4.18;

import "./SaiTestBase.sol";

contract TaxTest is SaiTestBase {

    function testEraInit() public {
        // assertEq(vox.era(), now);
    }
    function testEraWarp() public {
        taxSetup();
        warp(20);
    //    assertEq(uint(vox.era()), now + 20);
    }
    
    function taxSetup() public returns (bytes32 cup) {
        mark(10 ether);
        gem.mint(1000 ether);

        mom.setCap(1000 ether);
        mom.setTax(1000000564701133626865910626);  // 5% / day
        cup = tub.open();
        tub.join(100 ether);
        tub.lock(cup, 100 ether);
        tub.draw(cup, 100 ether);
    }
    function testTaxEra() public {
        var cup = taxSetup();
        assertEq(tub.tab(cup), 100 ether);
        warp(1 days);
        assertEq(tub.tab(cup), 105 ether);
        warp(1 days);
        assertEq(tub.tab(cup), 110.25 ether);
    }
    // rum doesn't change on drip
    function testTaxRum() public {
        taxSetup();
        assertEq(tub.rum(),    100 ether);
        warp(1 days);
        tub.drip();
        assertEq(tub.rum(),    100 ether);
    }
    // din increases on drip
    function testTaxDin() public {
        taxSetup();
        assertEq(tub.din(),    100 ether);
        warp(1 days);
        tub.drip();
        assertEq(tub.din(),    105 ether);
    }
    // Tax accumulates as sai surplus, and CDP debt
    function testTaxJoy() public {
        var cup = taxSetup();
        assertEq(tub.tab(cup), 100 ether);
        assertEq(tub.din(),    100 ether);
        assertEq(tap.joy(),      0 ether);
        warp(1 days);
        assertEq(tub.tab(cup), 105 ether);
        assertEq(tub.din(),    105 ether);
        assertEq(tap.joy(),      5 ether);
    }
    function testTaxJoy2() public {
        var cup = taxSetup();
        assertEq(tub.tab(cup), 100 ether);
        assertEq(tub.din(),    100 ether);
        assertEq(tap.joy(),      0 ether);
        warp(1 days);
        tub.drip();
        assertEq(tub.tab(cup), 105 ether);
        assertEq(tub.din(),    105 ether);
        assertEq(tap.joy(),      5 ether);
        // now ensure din != rum
        tub.wipe(cup, 5 ether);
        assertEq(tub.tab(cup), 100 ether);
        assertEq(tub.din(),    100 ether);
        assertEq(tap.joy(),      5 ether);
        warp(1 days);
        tub.drip();
        assertEq(tub.tab(cup), 105 ether);
        assertEq(tub.din(),    105 ether);
        assertEq(tap.joy(),     10 ether);
    }
    function testTaxJoy3() public {
        var cup = taxSetup();
        assertEq(tub.tab(cup), 100 ether);
        assertEq(tub.din(),    100 ether);
        assertEq(tap.joy(),      0 ether);
        warp(1 days);
        tub.drip();
        assertEq(tub.tab(cup), 105 ether);
        assertEq(tub.din(),    105 ether);
        assertEq(tap.joy(),      5 ether);
        // now ensure rum changes
        tub.wipe(cup, 5 ether);
        assertEq(tub.tab(cup), 100 ether);
        assertEq(tub.din(),    100 ether);
        assertEq(tap.joy(),      5 ether);
        warp(1 days);
        tub.drip();
        assertEq(tub.tab(cup), 105 ether);
        assertEq(tub.din(),    105 ether);
        assertEq(tap.joy(),     10 ether);
        // and ensure the last rum != din either
        tub.wipe(cup, 5 ether);
        assertEq(tub.tab(cup), 100 ether);
        assertEq(tub.din(),    100 ether);
        assertEq(tap.joy(),     10 ether);
        warp(1 days);
        tub.drip();
        assertEq(tub.tab(cup), 105 ether);
        assertEq(tub.din(),    105 ether);
        assertEq(tap.joy(),     15 ether);
    }
    function testTaxDraw() public {
        var cup = taxSetup();
        warp(1 days);
        assertEq(tub.tab(cup), 105 ether);
        tub.draw(cup, 100 ether);
        assertEq(tub.tab(cup), 205 ether);
        warp(1 days);
        assertEq(tub.tab(cup), 215.25 ether);
    }
    function testTaxWipe() public {
        var cup = taxSetup();
        warp(1 days);
        assertEq(tub.tab(cup), 105 ether);
        tub.wipe(cup, 50 ether);
        assertEq(tub.tab(cup), 55 ether);
        warp(1 days);
        assertEq(tub.tab(cup), 57.75 ether);
    }
    // collected fees are available through boom
    function testTaxBoom() public {
        taxSetup();
        warp(1 days);
        // should have 5 sai available == 0.5 skr
        tub.join(0.5 ether);  // get some unlocked skr

        assertEq(skr.totalSupply(),   100.5 ether);
        assertEq(sai.balanceOf(tap),    0 ether);
        assertEq(sin.balanceOf(tap),    0 ether);
        assertEq(sai.balanceOf(this), 100 ether);
        tub.drip();
        assertEq(sai.balanceOf(tap),    5 ether);
        tap.boom(0.5 ether);
        assertEq(skr.totalSupply(),   100 ether);
        assertEq(sai.balanceOf(tap),    0 ether);
        assertEq(sin.balanceOf(tap),    0 ether);
        assertEq(sai.balanceOf(this), 105 ether);
    }
    // Tax can flip a cup to unsafe
    function testTaxSafe() public {
        var cup = taxSetup();
        mark(1 ether);
        assertTrue(tub.safe(cup));
        warp(1 days);
        assertTrue(!tub.safe(cup));
    }
    function testTaxBite() public {
        var cup = taxSetup();
        mark(1 ether);
        warp(1 days);
        assertEq(tub.tab(cup), 105 ether);
        tub.bite(cup);
        assertEq(tub.tab(cup),   0 ether);
        assertEq(tap.woe(),    105 ether);
    }
    function testTaxBiteRounding() public {
        var cup = taxSetup();
        mark(1 ether);
        mom.setMat(ray(1.5 ether));
        mom.setAxe(ray(1.4 ether));
        mom.setTax(ray(1.000000001547126 ether));
        // log_named_uint('tab', tub.tab(cup));
        // log_named_uint('sin', tub.din());
        for (uint i=0; i<=50; i++) {
            warp(10);
            // log_named_uint('tab', tub.tab(cup));
            // log_named_uint('sin', tub.din());
        }
        uint256 debtAfterWarp = rmul(100 ether, rpow(tub.tax(), 510));
        assertEq(tub.tab(cup), debtAfterWarp);
        tub.bite(cup);
        assertEq(tub.tab(cup), 0 ether);
        assertEq(tap.woe(), rmul(100 ether, rpow(tub.tax(), 510)));
    }
    function testTaxBail() public {
        var cup = taxSetup();
        warp(1 days);
        tub.drip();
        mark(10 ether);
        top.cage();

        warp(1 days);  // should have no effect
        tub.drip();

        assertEq(skr.balanceOf(this),  0 ether);
        assertEq(skr.balanceOf(tub), 100 ether);
        tub.bite(cup);
        tub.free(cup, tub.ink(cup));
        assertEq(skr.balanceOf(this), 89.5 ether);
        assertEq(skr.balanceOf(tub),     0 ether);

        assertEq(sai.balanceOf(this),  100 ether);
        assertEq(gem.balanceOf(this), 1000 ether);
        tap.cash(sai.balanceOf(this));
        assertEq(sai.balanceOf(this),    0 ether);
        assertEq(gem.balanceOf(this), 1010 ether);
    }
    function testTaxCage() public {
        // after cage, un-distributed tax revenue remains as joy - sai
        // surplus in the tap. The remaining joy, plus all outstanding
        // sai, balances the sin debt in the tub, plus any debt (woe) in
        // the tap.

        // The effect of this is that joy remaining in tap is
        // effectively distributed to all skr holders.
        var cup = taxSetup();
        warp(1 days);
        mark(10 ether);

        assertEq(tap.joy(), 0 ether);
        top.cage();                // should drip up to date
        assertEq(tap.joy(), 5 ether);
        warp(1 days);  tub.drip();  // should have no effect
        assertEq(tap.joy(), 5 ether);

        var owe = tub.tab(cup);
        assertEq(owe, 105 ether);
        assertEq(tub.din(), owe);
        assertEq(tap.woe(), 0);
        tub.bite(cup);
        assertEq(tub.din(), 0);
        assertEq(tap.woe(), owe);
        assertEq(tap.joy(), 5 ether);
    }
}
