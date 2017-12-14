pragma solidity ^0.4.18;

import "./SaiTestBase.sol";

contract GapTest is SaiTestBase {
    // boom and bust have a spread parameter
    function setUp() public {
        super.setUp();

        gem.mint(500 ether);
        tub.join(500 ether);

        sai.mint(500 ether);
        sin.mint(500 ether);

        mark(2 ether);  // 2 ref per eth => 2 sai per skr
    }
    function testGapSaiTapBid() public {
        mark(1 ether);
        mom.setTapGap(1.01 ether);  // 1% spread
        assertEq(tap.bid(1 ether), 0.99 ether);
        mark(2 ether);
        assertEq(tap.bid(1 ether), 1.98 ether);
    }
    function testGapSaiTapAsk() public {
        mark(1 ether);
        mom.setTapGap(1.01 ether);  // 1% spread
        assertEq(tap.ask(1 ether), 1.01 ether);
        mark(2 ether);
        assertEq(tap.ask(1 ether), 2.02 ether);
    }
    function testGapBoom() public {
        sai.push(tap, 198 ether);
        assertEq(tap.joy(), 198 ether);

        mom.setTapGap(1.01 ether);  // 1% spread

        var sai_before = sai.balanceOf(this);
        var skr_before = skr.balanceOf(this);
        tap.boom(50 ether);
        var sai_after = sai.balanceOf(this);
        var skr_after = skr.balanceOf(this);
        assertEq(sai_after - sai_before, 99 ether);
        assertEq(skr_before - skr_after, 50 ether);
    }
    function testGapBust() public {
        skr.push(tap, 100 ether);
        sin.push(tap, 200 ether);
        assertEq(tap.fog(), 100 ether);
        assertEq(tap.woe(), 200 ether);

        mom.setTapGap(1.01 ether);

        var sai_before = sai.balanceOf(this);
        var skr_before = skr.balanceOf(this);
        tap.bust(50 ether);
        var sai_after = sai.balanceOf(this);
        var skr_after = skr.balanceOf(this);
        assertEq(skr_after - skr_before,  50 ether);
        assertEq(sai_before - sai_after, 101 ether);
    }
    function testGapLimits() public {
        uint256 legal   = 1.04 ether;
        uint256 illegal = 1.06 ether;

        var setGap = bytes4(keccak256("setTapGap(uint256)"));

        assertTrue(mom.call(setGap, legal));
        assertEq(tap.gap(), legal);

        assertTrue(!mom.call(setGap, illegal));
        assertEq(tap.gap(), legal);
    }

    // join and exit have a spread parameter
    function testGapJarBidAsk() public {
        assertEq(tub.per(), ray(1 ether));
        assertEq(tub.bid(1 ether), 1 ether);
        assertEq(tub.ask(1 ether), 1 ether);

        mom.setTubGap(1.01 ether);
        assertEq(tub.bid(1 ether), 0.99 ether);
        assertEq(tub.ask(1 ether), 1.01 ether);

        assertEq(skr.balanceOf(this), 500 ether);
        assertEq(skr.totalSupply(),   500 ether);
        skr.burn(250 ether);

        assertEq(tub.per(), ray(2 ether));
        assertEq(tub.bid(1 ether), 1.98 ether);
        assertEq(tub.ask(1 ether), 2.02 ether);
    }
    function testGapJoin() public {
        gem.mint(100 ether);

        mom.setTubGap(1.05 ether);
        var skr_before = skr.balanceOf(this);
        var gem_before = gem.balanceOf(this);
        tub.join(100 ether);
        var skr_after = skr.balanceOf(this);
        var gem_after = gem.balanceOf(this);

        assertEq(skr_after - skr_before, 100 ether);
        assertEq(gem_before - gem_after, 105 ether);
    }
    function testGapExit() public {
        gem.mint(100 ether);
        tub.join(100 ether);

        mom.setTubGap(1.05 ether);
        var skr_before = skr.balanceOf(this);
        var gem_before = gem.balanceOf(this);
        tub.exit(100 ether);
        var skr_after = skr.balanceOf(this);
        var gem_after = gem.balanceOf(this);

        assertEq(gem_after - gem_before,  95 ether);
        assertEq(skr_before - skr_after, 100 ether);
    }
}

contract GasTest is SaiTestBase {
    bytes32 cup;
    function setUp() public {
        super.setUp();

        mark(1 ether);
        gem.mint(1000 ether);

        mom.setCap(1000 ether);

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
