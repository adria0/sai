pragma solidity ^0.4.15;

import "./SaiTestBase.sol";

contract CageTest is SaiTestBase {
    // ensure cage sets the settle prices right
    function cageSetup() public returns (bytes32) {
        mom.setHat(5 ether);            // 5 sai debt ceiling
        mark(1 ether);   // price 1:1 gem:ref
        mom.setMat(ray(2 ether));       // require 200% collat
        tub.join(10 ether);
        var cup = tub.open();
        tub.lock(cup, 10 ether);
        tub.draw(cup, 5 ether);       // 200% collateralisation

        return cup;
    }
    function testCageSafeOverCollat() public {
        cageSetup();

        assertEq(top.fix(), 0);
        assertEq(tub.fit(), 0);
        assertEq(tap.woe(), 0);         // no bad debt
        assertEq(tub.pie(), 10 ether);

        tub.join(20 ether);   // give us some more skr
        mark(1 ether);
        top.cage();

        assertEq(tub.din(),      5 ether);  // debt remains in tub
        assertEq(wad(top.fix()), 1 ether);  // sai redeems 1:1 with gem
        assertEq(wad(tub.fit()), 1 ether);  // skr redeems 1:1 with gem just before pushing gem to tub

        assertEq(gem.balanceOf(tap),  5 ether);  // saved for sai
        assertEq(gem.balanceOf(tub), 25 ether);  // saved for skr
    }
    function testCageUnsafeOverCollat() public {
        cageSetup();

        assertEq(top.fix(), 0);
        assertEq(tub.fit(), 0);
        assertEq(tub.per(), ray(1 ether));

        tub.join(20 ether);   // give us some more skr
        var price = wdiv(3 ether, 4 ether);
        mark(price);
        top.cage();        // 150% collat

        assertEq(top.fix(), rdiv(1 ether, price));  // sai redeems 4:3 with gem
        assertEq(tub.fit(), ray(price));                 // skr redeems 1:1 with gem just before pushing gem to tub

        // gem needed for sai is 5 * 4 / 3
        var saved = rmul(5 ether, rdiv(WAD, price));
        assertEq(gem.balanceOf(tap),  saved);             // saved for sai
        assertEq(gem.balanceOf(tub),  30 ether - saved);  // saved for skr
    }
    function testCageAtCollat() public {
        cageSetup();

        assertEq(top.fix(), 0);
        assertEq(tub.fit(), 0);
        assertEq(tub.per(), ray(1 ether));

        var price = wdiv(1 ether, 2 ether);  // 100% collat
        mark(price);
        top.cage();

        assertEq(top.fix(), ray(2 ether));  // sai redeems 1:2 with gem, 1:1 with ref
        assertEq(tub.per(), 0);       // skr redeems 1:0 with gem after cage
    }
    function testCageAtCollatFreeSkr() public {
        cageSetup();

        assertEq(top.fix(), 0);
        assertEq(tub.fit(), 0);
        assertEq(tub.per(), ray(1 ether));

        tub.join(20 ether);   // give us some more skr
        var price = wdiv(1 ether, 2 ether);  // 100% collat
        mark(price);
        top.cage();

        assertEq(top.fix(), ray(2 ether));  // sai redeems 1:2 with gem, 1:1 with ref
        assertEq(tub.fit(), ray(price));       // skr redeems 1:1 with gem just before pushing gem to tub
    }
    function testCageUnderCollat() public {
        cageSetup();

        assertEq(top.fix(), 0);
        assertEq(tub.fit(), 0);
        assertEq(tub.per(), ray(1 ether));

        var price = wdiv(1 ether, 4 ether);   // 50% collat
        mark(price);
        top.cage();

        assertEq(2 * sai.totalSupply(), gem.balanceOf(tap));
        assertEq(top.fix(), ray(2 ether));  // sai redeems 1:2 with gem, 2:1 with ref
        assertEq(tub.per(), 0);       // skr redeems 1:0 with gem after cage
    }
    function testCageUnderCollatFreeSkr() public {
        cageSetup();

        assertEq(top.fix(), 0);
        assertEq(tub.fit(), 0);
        assertEq(tub.per(), ray(1 ether));

        tub.join(20 ether);   // give us some more skr
        var price = wdiv(1 ether, 4 ether);   // 50% collat
        mark(price);
        top.cage();

        assertEq(4 * sai.totalSupply(), gem.balanceOf(tap));
        assertEq(top.fix(), ray(4 ether));                 // sai redeems 1:4 with gem, 1:1 with ref
    }

    // ensure cash returns the expected amount
    function testCashSafeOverCollat() public {
        var cup = cageSetup();
        mark(1 ether);
        top.cage();

        assertEq(sai.balanceOf(this),  5 ether);
        assertEq(skr.balanceOf(this),  0 ether);
        assertEq(gem.balanceOf(this), 90 ether);
        assertEq(gem.balanceOf(tub),   5 ether);
        assertEq(gem.balanceOf(tap),   5 ether);

        tap.cash(sai.balanceOf(this));
        assertEq(sai.balanceOf(this),   0 ether);
        assertEq(skr.balanceOf(this),   0 ether);
        assertEq(gem.balanceOf(this),  95 ether);
        assertEq(gem.balanceOf(tub),    5 ether);

        assertEq(tub.ink(cup), 10 ether);
        tub.bite(cup);
        assertEq(tub.ink(cup), 5 ether);
        tub.free(cup, tub.ink(cup));
        assertEq(skr.balanceOf(this),   5 ether);
        tap.vent();
        top.flow();
        tub.exit(uint256(skr.balanceOf(this)));
        assertEq(gem.balanceOf(this), 100 ether);
        assertEq(gem.balanceOf(tub),    0 ether);

        assertEq(skr.totalSupply(), 0);
    }
    function testCashSafeOverCollatWithFreeSkr() public {
        var cup = cageSetup();
        tub.join(20 ether);   // give us some more skr
        mark(1 ether);
        top.cage();

        assertEq(sai.balanceOf(this),  5 ether);
        assertEq(skr.balanceOf(this), 20 ether);
        assertEq(gem.balanceOf(this), 70 ether);
        assertEq(gem.balanceOf(tub),  25 ether);
        assertEq(gem.balanceOf(tap),   5 ether);

        tub.bite(cup);
        tub.free(cup, tub.ink(cup));
        tap.vent();
        top.flow();
        assertEq(skr.balanceOf(this), 25 ether);
        tap.cash(sai.balanceOf(this));
        tub.exit(uint256(skr.balanceOf(this)));
        assertEq(gem.balanceOf(this), 100 ether);
        assertEq(sai.balanceOf(this),   0 ether);
        assertEq(gem.balanceOf(tub),    0 ether);

        tap.vent();
        assertEq(sai.totalSupply(), 0);
        assertEq(sin.totalSupply(), 0);

        assertEq(skr.totalSupply(), 0);
    }
    function testFailCashSafeOverCollatWithFreeSkrExitBeforeBail() public {
        // fails because exit is before bail
        var cup = cageSetup();
        tub.join(20 ether);   // give us some more skr
        mark(1 ether);
        top.cage();

        tap.cash(sai.balanceOf(this));
        tub.exit(uint256(skr.balanceOf(this)));
        assertEq(skr.balanceOf(this), 0 ether);
        uint256 gemBySAI = 5 ether; // Adding 5 gem from 5 sai
        uint256 gemBySKR = wdiv(wmul(20 ether, 30 ether - gemBySAI), 30 ether);
        assertEq(gem.balanceOf(this), 70 ether + gemBySAI + gemBySKR);

        assertEq(sai.balanceOf(this), 0);
        assertEq(sai.totalSupply(), 0);
        assertEq(sin.totalSupply(), 0);

        tub.bite(cup);
        tub.free(cup, tub.ink(cup));
        tap.vent();
        top.flow();
        assertEq(skr.balanceOf(this), 5 ether); // skr retrieved by bail(cup)

        tub.exit(uint256(skr.balanceOf(this)));
        assertEq(gem.balanceOf(this), 100 ether);
        assertEq(sai.balanceOf(this),   0 ether);
        assertEq(gem.balanceOf(tub),    0 ether);
        assertEq(sai.totalSupply(), 0);
        assertEq(sin.totalSupply(), 0);

        assertEq(skr.totalSupply(), 0);
    }
    function testCashUnsafeOverCollat() public {
        var cup = cageSetup();
        tub.join(20 ether);   // give us some more skr
        var price = wdiv(3 ether, 4 ether);
        mark(price);
        top.cage();        // 150% collat

        assertEq(sai.balanceOf(this),  5 ether);
        assertEq(skr.balanceOf(this), 20 ether);
        assertEq(gem.balanceOf(this), 70 ether);

        tap.cash(sai.balanceOf(this));
        assertEq(sai.balanceOf(this),   0 ether);
        assertEq(skr.balanceOf(this),  20 ether);

        uint256 gemBySAI = wdiv(wmul(5 ether, 4 ether), 3 ether);
        uint256 gemBySKR = 0;

        assertEq(gem.balanceOf(this), 70 ether + gemBySAI + gemBySKR);
        assertEq(gem.balanceOf(tub),  30 ether - gemBySAI - gemBySKR);

        // how much gem should be returned?
        // there were 10 gems initially, of which 5 were 100% collat
        // at the cage price, 5 * 4 / 3 are 100% collat,
        // leaving 10 - 5 * 4 / 3 as excess = 3.333
        // this should all be returned
        var ink = tub.ink(cup);
        var tab = tub.tab(cup);
        var skrToRecover = sub(ink, wdiv(tab, price));
        tub.bite(cup);
        tub.free(cup, tub.ink(cup));

        assertEq(skr.balanceOf(this), 20 ether + skrToRecover);
        assertEq(skr.balanceOf(tub),  0 ether);

        tap.vent();
        top.flow();
        tub.exit(uint256(skr.balanceOf(this)));
        assertEq(gem.balanceOf(this), 100 ether);
        assertEq(gem.balanceOf(tub),    0 ether);

        tap.vent();
        assertEq(skr.totalSupply(), 0);
        assertEq(sai.totalSupply(), 0);
        assertEq(sin.totalSupply(), 0);
    }
    function testCashAtCollat() public {
        var cup = cageSetup();
        var price = wdiv(1 ether, 2 ether);  // 100% collat
        mark(price);
        top.cage();

        assertEq(sai.balanceOf(this),  5 ether);
        assertEq(skr.balanceOf(this),  0 ether);
        assertEq(gem.balanceOf(this), 90 ether);
        tap.cash(sai.balanceOf(this));
        assertEq(sai.balanceOf(this),   0 ether);
        assertEq(skr.balanceOf(this),   0 ether);

        var saved = rmul(5 ether, rdiv(WAD, price));

        assertEq(gem.balanceOf(this),  90 ether + saved);
        assertEq(gem.balanceOf(tub),   10 ether - saved);

        // how much gem should be returned?
        // none :D
        assertEq(gem.balanceOf(this), 100 ether);
        assertEq(gem.balanceOf(tub),    0 ether);
        tub.bite(cup);
        tub.free(cup, tub.ink(cup));
        assertEq(gem.balanceOf(this), 100 ether);
        assertEq(gem.balanceOf(tub),    0 ether);

        tap.vent();
        assertEq(skr.totalSupply(), 0);
        assertEq(sai.totalSupply(), 0);
        assertEq(sin.totalSupply(), 0);
    }
    function testCashAtCollatFreeSkr() public {
        var cup = cageSetup();
        tub.join(20 ether);   // give us some more skr
        var price = wdiv(1 ether, 2 ether);  // 100% collat
        mark(price);
        top.cage();

        assertEq(sai.balanceOf(this),   5 ether);
        assertEq(skr.balanceOf(this),  20 ether);
        assertEq(gem.balanceOf(this),  70 ether);

        tap.cash(sai.balanceOf(this));
        assertEq(sai.balanceOf(this),   0 ether);

        tub.bite(cup);
        tub.free(cup, tub.ink(cup));
        tap.vent();
        top.flow();
        tub.exit(uint256(skr.balanceOf(this)));
        assertEq(gem.balanceOf(this), 100 ether);
        assertEq(gem.balanceOf(tub),    0 ether);

        assertEq(skr.totalSupply(), 0);
    }
    function testFailCashAtCollatFreeSkrExitBeforeBail() public {
        var cup = cageSetup();
        tub.join(20 ether);   // give us some more skr
        var price = wdiv(1 ether, 2 ether);  // 100% collat
        mark(price);
        top.cage();

        assertEq(sai.balanceOf(this),  5 ether);
        assertEq(skr.balanceOf(this), 20 ether);
        assertEq(gem.balanceOf(this), 70 ether);

        tap.cash(sai.balanceOf(this));
        assertEq(sai.balanceOf(this),   0 ether);
        tub.exit(uint256(skr.balanceOf(this)));
        assertEq(skr.balanceOf(this),   0 ether);


        var gemBySAI = wmul(5 ether, 2 ether);
        var gemBySKR = wdiv(wmul(20 ether, 30 ether - gemBySAI), 30 ether);

        assertEq(gem.balanceOf(this), 70 ether + gemBySAI + gemBySKR);
        assertEq(gem.balanceOf(tub),  30 ether - gemBySAI - gemBySKR);

        assertEq(sai.totalSupply(), 0);
        assertEq(sin.totalSupply(), 0);

        tub.bite(cup);
        tub.free(cup, tub.ink(cup));
        tap.vent();
        tub.exit(uint256(skr.balanceOf(this)));

        // Cup did not have skr to free, then the ramaining gem in tub can not be shared as there is not more skr to exit
        assertEq(gem.balanceOf(this), 70 ether + gemBySAI + gemBySKR);
        assertEq(gem.balanceOf(tub),  30 ether - gemBySAI - gemBySKR);

        assertEq(skr.totalSupply(), 0);
    }
    function testCashUnderCollat() public {
        var cup = cageSetup();
        var price = wdiv(1 ether, 4 ether);  // 50% collat
        mark(price);
        top.cage();

        assertEq(sai.balanceOf(this),  5 ether);
        assertEq(skr.balanceOf(this),  0 ether);
        assertEq(gem.balanceOf(this), 90 ether);
        tap.cash(sai.balanceOf(this));
        assertEq(sai.balanceOf(this),   0 ether);
        assertEq(skr.balanceOf(this),   0 ether);

        // get back all 10 gems, which are now only worth 2.5 ref
        // so you've lost 50% on you sai
        assertEq(gem.balanceOf(this), 100 ether);
        assertEq(gem.balanceOf(tub),    0 ether);

        // how much gem should be returned?
        // none :D
        assertEq(gem.balanceOf(this), 100 ether);
        assertEq(gem.balanceOf(tub),    0 ether);
        tub.bite(cup);
        tub.free(cup, tub.ink(cup));
        assertEq(gem.balanceOf(this), 100 ether);
        assertEq(gem.balanceOf(tub),    0 ether);

        tap.vent();
        assertEq(skr.totalSupply(), 0);
        assertEq(sai.totalSupply(), 0);
        assertEq(sin.totalSupply(), 0);
    }
    function testCashUnderCollatFreeSkr() public {
        var cup = cageSetup();
        tub.join(20 ether);   // give us some more skr
        var price = wdiv(1 ether, 4 ether);   // 50% collat
        mark(price);
        top.cage();

        assertEq(sai.balanceOf(this),  5 ether);
        assertEq(gem.balanceOf(this), 70 ether);
        tap.cash(sai.balanceOf(this));
        assertEq(sai.balanceOf(this),  0 ether);
        // returns 20 gems, taken from the free skr,
        // sai is made whole
        assertEq(gem.balanceOf(this), 90 ether);

        assertEq(skr.balanceOf(this),  20 ether);
        tub.bite(cup);
        tub.free(cup, tub.ink(cup));

        tap.vent();
        top.flow();
        tub.exit(uint256(skr.balanceOf(this)));
        assertEq(skr.balanceOf(this),   0 ether);
        // the skr has taken a 50% loss - 10 gems returned from 20 put in
        assertEq(gem.balanceOf(this), 100 ether);
        assertEq(gem.balanceOf(tub),    0 ether);

        assertEq(sai.totalSupply(), 0);
        assertEq(sin.totalSupply(), 0);

        assertEq(skr.totalSupply(), 0);
    }

    function testThreeCupsOverCollat() public {
        var cup = cageSetup();
        tub.join(90 ether);   // give us some more skr
        var cup2 = tub.open(); // open a new cup
        tub.lock(cup2, 20 ether); // lock collateral but not draw DAI
        var cup3 = tub.open(); // open a new cup
        tub.lock(cup3, 20 ether); // lock collateral but not draw DAI

        assertEq(gem.balanceOf(tap), 0);
        assertEq(gem.balanceOf(tub), 100 ether);
        assertEq(gem.balanceOf(this), 0);
        assertEq(skr.balanceOf(this), 50 ether); // free skr
        assertEq(skr.balanceOf(tub), 50 ether); // locked skr

        uint256 price = 1 ether;
        mark(price);
        top.cage();

        assertEq(gem.balanceOf(tap), 5 ether); // Needed to payout 5 sai
        assertEq(gem.balanceOf(tub), 95 ether);

        tub.bite(cup);
        tub.free(cup, tub.ink(cup)); // 5 skr recovered, and 5 skr burnt

        assertEq(skr.balanceOf(this), 55 ether); // free skr
        assertEq(skr.balanceOf(tub), 40 ether); // locked skr

        tub.bite(cup2);
        tub.free(cup2, tub.ink(cup2)); // 20 skr recovered

        assertEq(skr.balanceOf(this), 75 ether); // free skr
        assertEq(skr.balanceOf(tub), 20 ether); // locked skr

        tub.bite(cup3);
        tub.free(cup3, tub.ink(cup3)); // 20 skr recovered

        assertEq(skr.balanceOf(this), 95 ether); // free skr
        assertEq(skr.balanceOf(tub), 0); // locked skr

        tap.cash(sai.balanceOf(this));

        assertEq(sai.balanceOf(this), 0);
        assertEq(gem.balanceOf(this), 5 ether);

        tap.vent();
        top.flow();
        tub.exit(uint256(skr.balanceOf(this))); // exit 95 skr at price 95/95

        assertEq(gem.balanceOf(tub), 0);
        assertEq(gem.balanceOf(tap), 0);
        assertEq(gem.balanceOf(this), 100 ether);
        assertEq(skr.totalSupply(), 0);
    }
    function testThreeCupsAtCollat() public {
        var cup = cageSetup();
        tub.join(90 ether);   // give us some more skr
        var cup2 = tub.open(); // open a new cup
        tub.lock(cup2, 20 ether); // lock collateral but not draw DAI
        var cup3 = tub.open(); // open a new cup
        tub.lock(cup3, 20 ether); // lock collateral but not draw DAI

        assertEq(gem.balanceOf(tap), 0);
        assertEq(gem.balanceOf(tub), 100 ether);
        assertEq(gem.balanceOf(this), 0);
        assertEq(skr.balanceOf(this), 50 ether); // free skr
        assertEq(skr.balanceOf(tub), 50 ether); // locked skr

        var price = wdiv(1 ether, 2 ether);
        mark(price);
        top.cage();

        assertEq(gem.balanceOf(tap), 10 ether); // Needed to payout 10 sai
        assertEq(gem.balanceOf(tub), 90 ether);

        tub.bite(cup);
        tub.free(cup, tub.ink(cup)); // 10 skr burnt

        assertEq(skr.balanceOf(this), 50 ether); // free skr
        assertEq(skr.balanceOf(tub), 40 ether); // locked skr

        tub.bite(cup2);
        tub.free(cup2, tub.ink(cup2)); // 20 skr recovered

        assertEq(skr.balanceOf(this), 70 ether); // free skr
        assertEq(skr.balanceOf(tub), 20 ether); // locked skr

        tub.bite(cup3);
        tub.free(cup3, tub.ink(cup3)); // 20 skr recovered

        assertEq(skr.balanceOf(this), 90 ether); // free skr
        assertEq(skr.balanceOf(tub), 0); // locked skr

        tap.cash(sai.balanceOf(this));

        assertEq(sai.balanceOf(this), 0);
        assertEq(gem.balanceOf(this), 10 ether);

        tap.vent();
        top.flow();
        tub.exit(uint256(skr.balanceOf(this))); // exit 90 skr at price 90/90

        assertEq(gem.balanceOf(tub), 0);
        assertEq(gem.balanceOf(tap), 0);
        assertEq(gem.balanceOf(this), 100 ether);
        assertEq(skr.totalSupply(), 0);
    }
    function testThreeCupsUnderCollat() public {
        var cup = cageSetup();
        tub.join(90 ether);   // give us some more skr
        var cup2 = tub.open(); // open a new cup
        tub.lock(cup2, 20 ether); // lock collateral but not draw DAI
        var cup3 = tub.open(); // open a new cup
        tub.lock(cup3, 20 ether); // lock collateral but not draw DAI

        assertEq(gem.balanceOf(tap), 0);
        assertEq(gem.balanceOf(tub), 100 ether);
        assertEq(gem.balanceOf(this), 0);
        assertEq(skr.balanceOf(this), 50 ether); // free skr
        assertEq(skr.balanceOf(tub), 50 ether); // locked skr

        var price = wdiv(1 ether, 4 ether);
        mark(price);
        top.cage();

        assertEq(gem.balanceOf(tap), 20 ether); // Needed to payout 5 sai
        assertEq(gem.balanceOf(tub), 80 ether);

        tub.bite(cup);
        tub.free(cup, tub.ink(cup)); // No skr is retrieved as the cup doesn't even cover the debt. 10 locked skr in cup are burnt from tub

        assertEq(skr.balanceOf(this), 50 ether); // free skr
        assertEq(skr.balanceOf(tub), 40 ether); // locked skr

        tub.bite(cup2);
        tub.free(cup2, tub.ink(cup2)); // 20 skr recovered

        assertEq(skr.balanceOf(this), 70 ether); // free skr
        assertEq(skr.balanceOf(tub), 20 ether); // locked skr

        tub.bite(cup3);
        tub.free(cup3, tub.ink(cup3)); // 20 skr recovered

        assertEq(skr.balanceOf(this), 90 ether); // free skr
        assertEq(skr.balanceOf(tub), 0); // locked skr

        tap.cash(sai.balanceOf(this));

        assertEq(sai.balanceOf(this), 0);
        assertEq(gem.balanceOf(this), 20 ether);

        tap.vent();
        top.flow();
        tub.exit(uint256(skr.balanceOf(this))); // exit 90 skr at price 80/90

        assertEq(gem.balanceOf(tub), 0);
        assertEq(gem.balanceOf(tap), 0);
        assertEq(gem.balanceOf(this), 100 ether);
        assertEq(skr.totalSupply(), 0);
    }
    function testThreeCupsSKRZeroValue() public {
        var cup = cageSetup();
        tub.join(90 ether);   // give us some more skr
        var cup2 = tub.open(); // open a new cup
        tub.lock(cup2, 20 ether); // lock collateral but not draw DAI
        var cup3 = tub.open(); // open a new cup
        tub.lock(cup3, 20 ether); // lock collateral but not draw DAI

        assertEq(gem.balanceOf(tap), 0);
        assertEq(gem.balanceOf(tub), 100 ether);
        assertEq(gem.balanceOf(this), 0);
        assertEq(skr.balanceOf(this), 50 ether); // free skr
        assertEq(skr.balanceOf(tub), 50 ether); // locked skr

        var price = wdiv(1 ether, 20 ether);
        mark(price);
        top.cage();

        assertEq(gem.balanceOf(tap), 100 ether); // Needed to payout 5 sai
        assertEq(gem.balanceOf(tub), 0 ether);

        tub.bite(cup);
        tub.free(cup, tub.ink(cup)); // No skr is retrieved as the cup doesn't even cover the debt. 10 locked skr in cup are burnt from tub

        assertEq(skr.balanceOf(this), 50 ether); // free skr
        assertEq(skr.balanceOf(tub), 40 ether); // locked skr

        tub.bite(cup2);
        tub.free(cup2, tub.ink(cup2)); // 20 skr recovered

        assertEq(skr.balanceOf(this), 70 ether); // free skr
        assertEq(skr.balanceOf(tub), 20 ether); // locked skr

        tub.bite(cup3);
        tub.free(cup3, tub.ink(cup3)); // 20 skr recovered

        assertEq(skr.balanceOf(this), 90 ether); // free skr
        assertEq(skr.balanceOf(tub), 0); // locked skr

        tap.cash(sai.balanceOf(this));

        assertEq(sai.balanceOf(this), 0);
        assertEq(gem.balanceOf(this), 100 ether);

        tap.vent();
        top.flow();
        tub.exit(uint256(skr.balanceOf(this))); // exit 90 skr at price 0/90

        assertEq(gem.balanceOf(tub), 0);
        assertEq(gem.balanceOf(tap), 0);
        assertEq(gem.balanceOf(this), 100 ether);
        assertEq(skr.totalSupply(), 0);
    }

    function testPeriodicFixValue() public {
        cageSetup();

        assertEq(gem.balanceOf(tap), 0);
        assertEq(gem.balanceOf(tub), 10 ether);
        assertEq(gem.balanceOf(this), 90 ether);
        assertEq(skr.balanceOf(this), 0 ether); // free skr
        assertEq(skr.balanceOf(tub), 10 ether); // locked skr

        FakePerson person = new FakePerson(tap);
        sai.transfer(person, 2.5 ether); // Transfer half of SAI balance to the other user

        var price = rdiv(9 ether, 8 ether);
        mark(price);
        top.cage();

        assertEq(gem.balanceOf(tap), rmul(5 ether, top.fix())); // Needed to payout 5 sai
        assertEq(gem.balanceOf(tub), sub(10 ether, rmul(5 ether, top.fix())));

        tap.cash(sai.balanceOf(this));

        assertEq(sai.balanceOf(this),     0 ether);
        assertEq(sai.balanceOf(person), 2.5 ether);
        assertEq(gem.balanceOf(this), add(90 ether, rmul(2.5 ether, top.fix())));

        person.cash();
    }

    function testCageExitAfterPeriod() public {
        var cup = cageSetup();
        mom.setMat(ray(1 ether));  // 100% collat limit
        tub.free(cup, 5 ether);  // 100% collat

        assertEq(uint(top.caged()), 0);
        top.cage();
        assertEq(uint(top.caged()), vox.era());

        // exit fails because ice != 0 && fog !=0 and not enough time passed
        assertTrue(!tub.call(bytes4(keccak256('exit(uint256)')), 5 ether));

        top.setCooldown(1 days);
        warp(1 days);
        assertTrue(!tub.call(bytes4(keccak256('exit(uint256)')), 5 ether));

        warp(1 seconds);
        top.flow();
        assertEq(skr.balanceOf(this), 5 ether);
        assertEq(gem.balanceOf(this), 90 ether);
        assertTrue(tub.call(bytes4(keccak256('exit(uint256)')), 4 ether));
        assertEq(skr.balanceOf(this), 1 ether);
        // n.b. we don't get back 4 as there is still skr in the cup
        assertEq(gem.balanceOf(this), 92 ether);

        // now we can cash in our sai
        assertEq(sai.balanceOf(this), 5 ether);
        tap.cash(sai.balanceOf(this));
        assertEq(sai.balanceOf(this), 0 ether);
        assertEq(gem.balanceOf(this), 97 ether);

        // the remaining gem can be claimed only if the cup skr is burned
        assertEq(tub.air(), 5 ether);
        assertEq(tap.fog(), 0 ether);
        assertEq(tub.din(), 5 ether);
        assertEq(tap.woe(), 0 ether);
        tub.bite(cup);
        assertEq(tub.air(), 0 ether);
        assertEq(tap.fog(), 5 ether);
        assertEq(tub.din(), 0 ether);
        assertEq(tap.woe(), 5 ether);

        tap.vent();
        assertEq(tap.fog(), 0 ether);
        assertEq(tap.woe(), 0 ether);

        // now this remaining 1 skr will claim all the remaining 3 ether.
        // this is why exiting early is bad if you want to maximise returns.
        // if we had exited with all the skr earlier, there would be 2.5 gem
        // trapped in the tub.
        tub.exit(1 ether);
        assertEq(skr.balanceOf(this),   0 ether);
        assertEq(gem.balanceOf(this), 100 ether);
    }

    function testShutEmptyCup() public {
        var cup = tub.open();
        var (lad,,,) = tub.cups(cup);
        assertEq(lad, this);
        tub.shut(cup);
        (lad,,,) = tub.cups(cup);
        assertEq(lad, 0);
    }
}
