pragma solidity ^0.4.18;

import "./SaiTestBase.sol";

contract WayTest is SaiTestBase {
    function waySetup() public returns (bytes32 cup) {
        mark(10 ether);
        gem.mint(1000 ether);

        mom.setCap(1000 ether);

        cup = tub.open();
        tub.join(100 ether);
        tub.lock(cup, 100 ether);
        tub.draw(cup, 100 ether);
    }
    // what does way actually do?
    // it changes the value of sai relative to ref
    // way > 1 -> par increasing, more ref per sai
    // way < 1 -> par decreasing, less ref per sai

    // this changes the safety level of cups,
    // affecting `draw`, `wipe`, `free` and `bite`

    // if way < 1, par is decreasing and the con (in ref)
    // of a cup is decreasing, so cup holders need
    // less ref to wipe (but the same sai)
    // This makes cups *more* collateralised with time.
    function testTau() public {
        assertEq(uint(vox.era()), now);
        assertEq(uint(vox.tau()), now);
    }
    function testWayPar() public {
        mom.setWay(999999406327787478619865402);  // -5% / day

        assertEq(wad(vox.par()), 1.00 ether);
        warp(1 days);
        assertEq(wad(vox.par()), 0.95 ether);

        mom.setWay(1000008022568992670911001251);  // 200% / day
        warp(1 days);
        assertEq(wad(vox.par()), 1.90 ether);
    }
    function testWayDecreasingPrincipal() public {
        var cup = waySetup();
        mark(0.98 ether);
        assertTrue(!tub.safe(cup));

        mom.setWay(999999406327787478619865402);  // -5% / day
        warp(1 days);
        assertTrue(tub.safe(cup));
    }
    // `cage` is slightly affected: the cage price is
    // now in *sai per gem*, where before ref per gem
    // was equivalent.
    // `bail` is unaffected, as all values are in sai.
    function testWayCage() public {
        waySetup();

        mom.setWay(1000008022568992670911001251);  // 200% / day
        warp(1 days);  // par now 2

        // we have 100 sai
        // gem is worth 10 ref
        // sai is worth 2 ref
        // we should get back 100 / (10 / 2) = 20 gem

        top.cage();

        assertEq(gem.balanceOf(this), 1000 ether);
        assertEq(sai.balanceOf(this),  100 ether);
        assertEq(sai.balanceOf(tap),     0 ether);
        tap.cash(sai.balanceOf(this));
        assertEq(gem.balanceOf(this), 1020 ether);
        assertEq(sai.balanceOf(this),   0 ether);
        assertEq(sai.balanceOf(tap),    0 ether);
    }

    // `boom` and `bust` as par is now needed to determine
    // the skr / sai price.
    function testWayBust() public {
        var cup = waySetup();
        mark(0.5 ether);
        tub.bite(cup);

        assertEq(tap.joy(),   0 ether);
        assertEq(tap.woe(), 100 ether);
        assertEq(tap.fog(), 100 ether);
        assertEq(sai.balanceOf(this), 100 ether);

        tap.bust(50 ether);

        assertEq(tap.fog(),  50 ether);
        assertEq(tap.woe(),  75 ether);
        assertEq(sai.balanceOf(this), 75 ether);

        mom.setWay(999991977495368425989823173);  // -50% / day
        warp(1 days);
        assertEq(wad(vox.par()), 0.5 ether);
        // sai now worth half as much, so we cover twice as much debt
        // for the same skr
        tap.bust(50 ether);

        assertEq(tap.fog(),   0 ether);
        assertEq(tap.woe(),  25 ether);
        assertEq(sai.balanceOf(this), 25 ether);
    }
    function testWayBoom() public {
        var cup = waySetup();
        tub.join(100 ether);       // give us some spare skr
        sai.push(tap, 100 ether);  // force some joy into the tap
        assertEq(tap.joy(), 100 ether);

        mark(2 ether);
        mom.setWay(1000008022568992670911001251);  // 200% / day
        warp(1 days);
        assertEq(wad(vox.par()), 2 ether);
        tap.boom(100 ether);
        assertEq(tap.joy(),   0 ether);
        assertEq(tub.per(), ray(2 ether));

        tub.join(100 ether);
        tub.draw(cup, 100 ether);
        sai.push(tap, 100 ether);  // force some joy into the tap

        // n.b. per is now 2
        assertEq(tap.joy(), 100 ether);
        mark(2 ether);
        mom.setWay(999991977495368425989823173);  // -50% / day
        warp(2 days);
        assertEq(wad(vox.par()), 0.5 ether);
        tap.boom(12.5 ether);
        assertEq(tap.joy(),   0 ether);
    }
}
