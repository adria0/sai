pragma solidity ^0.4.18;

import "./SaiTestBase.sol";

contract TapTest is SaiTestBase {
    function testTapSetup() public {
        assertEq(sai.balanceOf(tap), tap.joy());
        assertEq(sin.balanceOf(tap), tap.woe());
        assertEq(skr.balanceOf(tap), tap.fog());

        assertEq(tap.joy(), 0);
        assertEq(tap.woe(), 0);
        assertEq(tap.fog(), 0);

        sai.mint(tap, 3);
        sin.mint(tap, 4);
        skr.mint(tap, 5);

        assertEq(tap.joy(), 3);
        assertEq(tap.woe(), 4);
        assertEq(tap.fog(), 5);
    }
    // boom (flap) is surplus sale (sai for skr->burn)
    function testTapBoom() public {
        sai.mint(tap, 50 ether);
        tub.join(60 ether);

        assertEq(sai.balanceOf(this),  0 ether);
        assertEq(skr.balanceOf(this), 60 ether);
        tap.boom(50 ether);
        assertEq(sai.balanceOf(this), 50 ether);
        assertEq(skr.balanceOf(this), 10 ether);
        assertEq(tap.joy(), 0);
    }
    function testFailTapBoomOverJoy() public {
        sai.mint(tap, 50 ether);
        tub.join(60 ether);
        tap.boom(51 ether);
    }
    function testTapBoomHeals() public {
        sai.mint(tap, 60 ether);
        sin.mint(tap, 50 ether);
        tub.join(10 ether);

        tap.boom(0 ether);
        assertEq(tap.joy(), 10 ether);
    }
    function testFailTapBoomNetWoe() public {
        sai.mint(tap, 50 ether);
        sin.mint(tap, 60 ether);
        tub.join(10 ether);
        tap.boom(1 ether);
    }
    function testTapBoomBurnsSkr() public {
        sai.mint(tap, 50 ether);
        tub.join(60 ether);

        assertEq(skr.totalSupply(), 60 ether);
        tap.boom(20 ether);
        assertEq(skr.totalSupply(), 40 ether);
    }
    function testTapBoomIncreasesPer() public {
        sai.mint(tap, 50 ether);
        tub.join(60 ether);

        assertEq(tub.per(), ray(1 ether));
        tap.boom(30 ether);
        assertEq(tub.per(), ray(2 ether));
    }
    function testTapBoomMarkDep() public {
        sai.mint(tap, 50 ether);
        tub.join(50 ether);

        mark(2 ether);
        tap.boom(10 ether);
        assertEq(sai.balanceOf(this), 20 ether);
        assertEq(sai.balanceOf(tap),  30 ether);
        assertEq(skr.balanceOf(this), 40 ether);
    }
    function testTapBoomPerDep() public {
        sai.mint(tap, 50 ether);
        tub.join(50 ether);

        assertEq(tub.per(), ray(1 ether));
        skr.mint(50 ether);  // halves per
        assertEq(tub.per(), ray(.5 ether));

        tap.boom(10 ether);
        assertEq(sai.balanceOf(this),  5 ether);
        assertEq(sai.balanceOf(tap),  45 ether);
        assertEq(skr.balanceOf(this), 90 ether);
    }
    // flip is collateral sale (skr for sai)
    function testTapBustFlip() public {
        sai.mint(50 ether);
        tub.join(50 ether);
        skr.push(tap, 50 ether);
        assertEq(tap.fog(), 50 ether);

        assertEq(skr.balanceOf(this),  0 ether);
        assertEq(sai.balanceOf(this), 50 ether);
        tap.bust(30 ether);
        assertEq(skr.balanceOf(this), 30 ether);
        assertEq(sai.balanceOf(this), 20 ether);
    }
    function testFailTapBustFlipOverFog() public { // FAIL
        sai.mint(50 ether);
        tub.join(50 ether);
        skr.push(tap, 50 ether);

        tap.bust(51 ether);
    }
    function testTapBustFlipHealsNetJoy() public {
        sai.mint(tap, 10 ether);
        sin.mint(tap, 20 ether);
        tub.join(50 ether);
        skr.push(tap, 50 ether);

        sai.mint(15 ether);
        tap.bust(15 ether);
        assertEq(tap.joy(), 5 ether);
        assertEq(tap.woe(), 0 ether);
    }
    function testTapBustFlipHealsNetWoe() public {
        sai.mint(tap, 10 ether);
        sin.mint(tap, 20 ether);
        tub.join(50 ether);
        skr.push(tap, 50 ether);

        sai.mint(5 ether);
        tap.bust(5 ether);
        assertEq(tap.joy(), 0 ether);
        assertEq(tap.woe(), 5 ether);
    }
    // flop is debt sale (woe->skr for sai)
    function testTapBustFlop() public {
        tub.join(50 ether);  // avoid per=1 init case
        sai.mint(100 ether);
        sin.mint(tap, 50 ether);
        assertEq(tap.woe(), 50 ether);

        assertEq(skr.balanceOf(this),  50 ether);
        assertEq(sai.balanceOf(this), 100 ether);
        tap.bust(50 ether);
        assertEq(skr.balanceOf(this), 100 ether);
        assertEq(sai.balanceOf(this),  75 ether);
    }
    function testFailTapBustFlopNetJoy() public {
        tub.join(50 ether);  // avoid per=1 init case
        sai.mint(100 ether);
        sin.mint(tap, 50 ether);
        sai.mint(tap, 100 ether);

        tap.bust(1);  // anything but zero should fail
    }
    function testTapBustFlopMintsSkr() public {
        tub.join(50 ether);  // avoid per=1 init case
        sai.mint(100 ether);
        sin.mint(tap, 50 ether);

        assertEq(skr.totalSupply(),  50 ether);
        tap.bust(20 ether);
        assertEq(skr.totalSupply(),  70 ether);
    }
    function testTapBustFlopDecreasesPer() public {
        tub.join(50 ether);  // avoid per=1 init case
        sai.mint(100 ether);
        sin.mint(tap, 50 ether);

        assertEq(tub.per(), ray(1 ether));
        tap.bust(50 ether);
        assertEq(tub.per(), ray(.5 ether));
    }

    function testTapBustAsk() public {
        tub.join(50 ether);
        assertEq(tap.ask(50 ether), 50 ether);

        skr.mint(50 ether);
        assertEq(tap.ask(50 ether), 25 ether);

        skr.mint(100 ether);
        assertEq(tap.ask(50 ether), 12.5 ether);

        skr.burn(175 ether);
        assertEq(tap.ask(50 ether), 100 ether);

        skr.mint(25 ether);
        assertEq(tap.ask(50 ether), 50 ether);

        skr.mint(10 ether);
        // per = 5 / 6
        assertEq(tap.ask(60 ether), 50 ether);

        skr.mint(30 ether);
        // per = 5 / 9
        assertEq(tap.ask(90 ether), 50 ether);

        skr.mint(10 ether);
        // per = 1 / 2
        assertEq(tap.ask(100 ether), 50 ether);
    }
    // flipflop is debt sale when collateral present
    function testTapBustFlipFlopRounding() public {
        tub.join(50 ether);  // avoid per=1 init case
        sai.mint(100 ether);
        sin.mint(tap, 100 ether);
        skr.push(tap,  50 ether);
        assertEq(tap.joy(),   0 ether);
        assertEq(tap.woe(), 100 ether);
        assertEq(tap.fog(),  50 ether);

        assertEq(skr.balanceOf(this),   0 ether);
        assertEq(sai.balanceOf(this), 100 ether);
        assertEq(skr.totalSupply(),    50 ether);

        assertEq(tub.per(), ray(1 ether));
        assertEq(tap.s2s(), ray(1 ether));
        assertEq(tub.tag(), ray(1 ether));
        assertEq(tap.ask(60 ether), 60 ether);
        tap.bust(60 ether);
        assertEq(tub.per(), rdiv(5, 6));
        assertEq(tap.s2s(), rdiv(5, 6));
        assertEq(tub.tag(), rdiv(5, 6));
        // non ray prices would give small rounding error because wad math
        assertEq(tap.ask(60 ether), 50 ether);
        assertEq(skr.totalSupply(),    60 ether);
        assertEq(tap.fog(),             0 ether);
        assertEq(skr.balanceOf(this),  60 ether);
        assertEq(sai.balanceOf(this),  50 ether);
    }
    function testTapBustFlipFlop() public {
        tub.join(50 ether);  // avoid per=1 init case
        sai.mint(100 ether);
        sin.mint(tap, 100 ether);
        skr.push(tap,  50 ether);
        assertEq(tap.joy(),   0 ether);
        assertEq(tap.woe(), 100 ether);
        assertEq(tap.fog(),  50 ether);

        assertEq(skr.balanceOf(this),   0 ether);
        assertEq(sai.balanceOf(this), 100 ether);
        assertEq(skr.totalSupply(),    50 ether);
        assertEq(tub.per(), ray(1 ether));
        tap.bust(80 ether);
        assertEq(tub.per(), rdiv(5, 8));
        assertEq(skr.totalSupply(),    80 ether);
        assertEq(tap.fog(),             0 ether);
        assertEq(skr.balanceOf(this),  80 ether);
        assertEq(sai.balanceOf(this),  50 ether);  // expected 50, actual 50 ether + 2???!!!
    }
}
