pragma solidity ^0.4.18;

import "./test.sol";

import "./math.sol";

import './token.sol';
import './roles.sol';
import './value.sol';

import './mom.sol';
import './fab.sol';

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
        address  pit_
    ) public
      SaiTub(sai_, sin_, skr_, gem_, gov_, pip_, pep_, vox_, pit_) {}
}

contract DevTop is SaiTop, TestWarp {
    function DevTop(SaiTub tub_, SaiTap tap_) public SaiTop(tub_, tap_) {}
}

contract DevVox is SaiVox, TestWarp {}

contract DevVoxFab {
    function newVox() public returns (DevVox vox) {
        vox = new DevVox();
        vox.setOwner(msg.sender);
    }
}

contract DevTubFab {
    function newTub(DSToken sai, DSToken sin, DSToken skr, DSToken gem, DSToken gov, DSValue pip, DSValue pep, SaiVox vox, address pit) public returns (DevTub tub) {
        tub = new DevTub(sai, sin, skr, gem, gov, pip, pep, vox, pit);
        tub.setOwner(msg.sender);
    }
}

contract DevTopFab {
    function newTop(DevTub tub, SaiTap tap) public returns (DevTop top) {
        top = new DevTop(tub, tap);
        top.setOwner(msg.sender);
    }
}

contract DevDadFab {
    function newDad() public returns (DSGuard dad) {
        dad = new DSGuard();
        // convenience in tests
        dad.permit(DaiFab(msg.sender).owner(), DaiFab(msg.sender).sai(), bytes4(keccak256('mint(uint256)')));
        dad.permit(DaiFab(msg.sender).owner(), DaiFab(msg.sender).sai(), bytes4(keccak256('burn(uint256)')));
        dad.permit(DaiFab(msg.sender).owner(), DaiFab(msg.sender).sai(), bytes4(keccak256('mint(address,uint256)')));
        dad.permit(DaiFab(msg.sender).owner(), DaiFab(msg.sender).sai(), bytes4(keccak256('burn(address,uint256)')));
        dad.permit(DaiFab(msg.sender).owner(), DaiFab(msg.sender).sin(), bytes4(keccak256('mint(uint256)')));
        dad.permit(DaiFab(msg.sender).owner(), DaiFab(msg.sender).sin(), bytes4(keccak256('burn(uint256)')));
        dad.permit(DaiFab(msg.sender).owner(), DaiFab(msg.sender).sin(), bytes4(keccak256('mint(address,uint256)')));
        dad.permit(DaiFab(msg.sender).owner(), DaiFab(msg.sender).sin(), bytes4(keccak256('burn(address,uint256)')));
        dad.permit(DaiFab(msg.sender).owner(), DaiFab(msg.sender).skr(), bytes4(keccak256('mint(uint256)')));
        dad.permit(DaiFab(msg.sender).owner(), DaiFab(msg.sender).skr(), bytes4(keccak256('burn(uint256)')));
        dad.permit(DaiFab(msg.sender).owner(), DaiFab(msg.sender).skr(), bytes4(keccak256('mint(address,uint256)')));
        dad.permit(DaiFab(msg.sender).owner(), DaiFab(msg.sender).skr(), bytes4(keccak256('burn(address,uint256)')));
        dad.setOwner(msg.sender);
    }
}

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

    DSValue  pip;
    DSValue  pep;
    DSRoles  dad;

    function ray(uint256 wad) internal pure returns (uint256) {
        return wad * 10 ** 9;
    }
    function wad(uint256 ray_) internal pure returns (uint256) {
        return wdiv(ray_, RAY);
    }

    function mark(uint price) internal {
        pip.poke(bytes32(price));
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

    function setUp() public {
        GemFab gemFab = new GemFab();
        DevVoxFab voxFab = new DevVoxFab();
        DevTubFab tubFab = new DevTubFab();
        TapFab tapFab = new TapFab();
        DevTopFab topFab = new DevTopFab();
        MomFab momFab = new MomFab();
        DevDadFab dadFab = new DevDadFab();

        DaiFab daiFab = new DaiFab(gemFab, VoxFab(voxFab), TubFab(tubFab), tapFab, TopFab(topFab), momFab, DadFab(dadFab));

        gem = new DSToken('GEM');
        gem.mint(100 ether);
        gov = new DSToken('GOV');
        pip = new DSValue();
        pep = new DSValue();
        pit = address(0x123);

        daiFab.makeTokens();
        daiFab.makeVoxTub(gem, gov, pip, pep, pit);
        daiFab.makeTapTop();
        DSRoles authority = new DSRoles();
        authority.setRootUser(this, true);
        daiFab.configAuth(authority);

        sai = DSToken(daiFab.sai());
        sin = DSToken(daiFab.sin());
        skr = DSToken(daiFab.skr());
        vox = DevVox(daiFab.vox());
        tub = DevTub(daiFab.tub());
        tap = SaiTap(daiFab.tap());
        top = DevTop(daiFab.top());
        mom = SaiMom(daiFab.mom());
        dad = DSRoles(daiFab.dad());

        sai.approve(tub);
        skr.approve(tub);
        gem.approve(tub);
        gov.approve(tub);

        sai.approve(tap);
        skr.approve(tap);

        mark(1 ether);
        mark(gov, 1 ether);

        mom.setCap(20 ether);
    }
}











