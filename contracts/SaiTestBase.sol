pragma solidity ^0.4.15;

import "./DSTest.sol";

import "./DSMath.sol";

import './DSToken.sol';
import './DSGuard.sol';
import './DSValue.sol';

import './SaiMom.sol';

contract TestWarp is DSNote {
    uint256  _era;

    function TestWarp() public {
        _era = now;
    }

    function era() public view returns (uint256) {
        return _era == 0 ? now : _era;
    }

    function warp(uint age) public note {
        require(_era != 0);
        _era = age == 0 ? 0 : _era + age;
    }
}

contract DevTub is SaiTub, TestWarp {
    function DevTub(
        DSToken  sai_,
        DSToken  sin_,
        DSToken  skr_,
        ERC20    gem_,
        DSToken  gov_,
        DSValue  pip_,
        DSValue  pep_,
        SaiVox   vox_,
        address  tap_,
        address  pit_
    ) public
      SaiTub(sai_, sin_, skr_, gem_, gov_, pip_, pep_, vox_, tap_, pit_) {}
}

contract DevTop is SaiTop, TestWarp {
    function DevTop(SaiTub tub_, SaiTap tap_) public SaiTop(tub_, tap_) {}
}
contract DevVox is SaiVox, TestWarp {}

contract FakePerson {
    SaiTap  public tap;
    DSToken public sai;

    function FakePerson(SaiTap _tap) public {
        tap = _tap;
        sai = tap.sai();
        sai.approve(tap);
    }

    function cash() public {
        tap.cash(sai.balanceOf(this));
    }
}

contract SaiTestBase is DSTest, DSMath {
    DevVox   vox;
    DevTub   tub;
    DevTop   top;
    SaiTap   tap;

    SaiMom   mom;

    DSToken  gem;
    DSToken  sai;
    DSToken  sin;
    DSToken  skr;
    DSToken  gov;

    address  pit;

    DSValue  tag;
    DSValue  pep;
    DSGuard  dad;

    function ray(uint256 wad) internal pure returns (uint256) {
        return wad * 10 ** 9;
    }
    function wad(uint256 ray_) internal pure returns (uint256) {
        return wdiv(ray_, RAY);
    }

    function mark(uint price) internal {
        tag.poke(bytes32(price));
    }
    function mark(DSToken tkn, uint price) internal {
        if (tkn == gov) pep.poke(bytes32(price));
        else if (tkn == gem) mark(price);
    }
    function warp(uint256 age) internal {
        vox.warp(age);
        tub.warp(age);
        top.warp(age);
    }

    function configureAuth() public {
        vox.setAuthority(dad);
        tub.setAuthority(dad);
        tap.setAuthority(dad);
        top.setAuthority(dad);

        sai.setAuthority(dad);
        sin.setAuthority(dad);
        skr.setAuthority(dad);

        vox.setOwner(0);
        tub.setOwner(0);
        tap.setOwner(0);
        top.setOwner(0);

        sai.setOwner(0);
        sin.setOwner(0);
        skr.setOwner(0);

        dad.permit(top, tub, bytes4(keccak256("cage(uint256,uint256)")));
        dad.permit(top, tub, bytes4(keccak256("flow()")));
        dad.permit(top, tap, bytes4(keccak256("cage(uint256)")));

        dad.permit(tub, skr, bytes4(keccak256('mint(address,uint256)')));
        dad.permit(tub, skr, bytes4(keccak256('burn(address,uint256)')));

        dad.permit(tub, sai, bytes4(keccak256('mint(address,uint256)')));
        dad.permit(tub, sai, bytes4(keccak256('burn(address,uint256)')));

        dad.permit(tub, sin, bytes4(keccak256('mint(address,uint256)')));
        dad.permit(tub, sin, bytes4(keccak256('mint(uint256)')));
        dad.permit(tub, sin, bytes4(keccak256('burn(uint256)')));

        dad.permit(tap, sai, bytes4(keccak256('burn(uint256)')));
        dad.permit(tap, sin, bytes4(keccak256('burn(uint256)')));

        dad.permit(tap, skr, bytes4(keccak256('mint(uint256)')));
        dad.permit(tap, skr, bytes4(keccak256('burn(uint256)')));
        dad.permit(tap, skr, bytes4(keccak256('burn(address,uint256)')));

        // mom controls
        dad.permit(mom, vox, bytes4(keccak256("mold(bytes32,uint256)")));
        dad.permit(mom, tub, bytes4(keccak256("mold(bytes32,uint256)")));
        dad.permit(mom, tap, bytes4(keccak256("mold(bytes32,uint256)")));

        dad.permit(this, top, bytes4(keccak256("cage(uint256)")));
        dad.permit(this, top, bytes4(keccak256("cage()")));
        dad.permit(this, top, bytes4(keccak256("setCooldown(uint256)")));

        // convenience in tests
        dad.permit(this, sai, bytes4(keccak256('mint(uint256)')));
        dad.permit(this, sai, bytes4(keccak256('burn(uint256)')));
        dad.permit(this, sai, bytes4(keccak256('mint(address,uint256)')));
        dad.permit(this, sai, bytes4(keccak256('burn(address,uint256)')));
        dad.permit(this, sin, bytes4(keccak256('mint(uint256)')));
        dad.permit(this, sin, bytes4(keccak256('burn(uint256)')));
        dad.permit(this, sin, bytes4(keccak256('mint(address,uint256)')));
        dad.permit(this, sin, bytes4(keccak256('burn(address,uint256)')));
        dad.permit(this, skr, bytes4(keccak256('mint(uint256)')));
        dad.permit(this, skr, bytes4(keccak256('burn(uint256)')));
        dad.permit(this, skr, bytes4(keccak256('mint(address,uint256)')));
        dad.permit(this, skr, bytes4(keccak256('burn(address,uint256)')));

        dad.setOwner(0);
    }

    function setUp() public {
        gem = new DSToken("GEM");
        gem.mint(100 ether);

        sai = new DSToken("SAI");
        sin = new DSToken("SIN");

        skr = new DSToken("SKR");

        gov = new DSToken("GOV");

        tag = new DSValue();
        pep = new DSValue();
        vox = new DevVox();

        pit = address(0x123);

        tap = new SaiTap();
        tub = new DevTub(sai, sin, skr, gem, gov, tag, pep, vox, tap, pit);
        top = new DevTop(tub, tap);
        tap.turn(tub);

        dad = new DSGuard();

        mom = new SaiMom(tub, tap, vox);

        configureAuth();

        sai.approve(tub);
        skr.approve(tub);
        gem.approve(tub);
        gov.approve(tub);

        sai.approve(tap);
        skr.approve(tap);

        mark(1 ether);
        mark(gov, 1 ether);

        mom.setHat(20 ether);
    }
}


