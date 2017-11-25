pragma solidity ^0.4.15;

import "./SaiTestBase.sol";

contract AxeTest is SaiTestBase {
    function axeSetup() public returns (bytes32) {
        mom.setHat(1000 ether);
        mark(1 ether);
        mom.setMat(ray(2 ether));       // require 200% collat
        tub.join(20 ether);
        var cup = tub.open();
        tub.lock(cup, 20 ether);
        tub.draw(cup, 10 ether);       // 200% collateralisation

        return cup;
    }
    function testAxeBite1() public {
        var cup = axeSetup();

        mom.setAxe(ray(1.5 ether));
        mom.setMat(ray(2.1 ether));

        assertEq(tub.ink(cup), 20 ether);
        tub.bite(cup);
        assertEq(tub.ink(cup), 5 ether);
    }
    function testAxeBite2() public {
        var cup = axeSetup();

        mom.setAxe(ray(1.5 ether));
        mark(0.8 ether);    // collateral value 20 -> 16

        assertEq(tub.ink(cup), 20 ether);
        tub.bite(cup);
        assertEq(tub.ink(cup), 1.25 ether);  // (1 / 0.8)
    }
    function testAxeBiteParity() public {
        var cup = axeSetup();

        mom.setAxe(ray(1.5 ether));
        mark(0.5 ether);    // collateral value 20 -> 10

        assertEq(tub.ink(cup), 20 ether);
        tub.bite(cup);
        assertEq(tub.ink(cup), 0 ether);
    }
    function testAxeBiteUnder() public {
        var cup = axeSetup();

        mom.setAxe(ray(1.5 ether));
        mark(0.4 ether);    // collateral value 20 -> 8

        assertEq(tub.ink(cup), 20 ether);
        tub.bite(cup);
        assertEq(tub.ink(cup), 0 ether);
    }
    function testZeroAxeCage() public {
        var cup = axeSetup();

        mom.setAxe(ray(1 ether));

        assertEq(tub.ink(cup), 20 ether);
        top.cage();
        tub.bite(cup);
        tap.vent();
        top.flow();
        assertEq(tub.ink(cup), 10 ether);
    }
    function testAxeCage() public {
        var cup = axeSetup();

        mom.setAxe(ray(1.5 ether));

        assertEq(tub.ink(cup), 20 ether);
        top.cage();
        tub.bite(cup);
        tap.vent();
        top.flow();
        assertEq(tub.ink(cup), 10 ether);
    }
}
