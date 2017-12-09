/// tap.sol -- liquidation engine (see also `vow`)

// Copyright (C) 2017  Nikolai Mushegian <nikolai@dapphub.com>
// Copyright (C) 2017  Daniel Brockman <daniel@dapphub.com>
// Copyright (C) 2017  Rain <rainbreak@riseup.net>

pragma solidity ^0.4.15;

import "./tub.sol";

contract SaiTap is DSThing {

    DSToken  public  sai;
    DSToken  public  sin;
    DSToken  public  skr;

    SaiVox   public  vox;
    SaiTub   public  tub;

    uint256  public  gapJoinExitSpread;  // Boom-Bust Spread
    bool     public  offStartedLiquidationPhase;  // Cage flag
    uint256  public  fixGemPerSkrSettlementPrice;  // Cage price

    // Surplus
    function joyAmountOfSurplusSai() public view returns (uint) {
        return sai.balanceOf(this);
    }
    // Bad debt
    function woeBadDebt() public view returns (uint) {
        return sin.balanceOf(this);
    }
    // Collateral pending liquidation
    function fogAmountOfSkrPendingLiquidation() public view returns (uint) {
        return skr.balanceOf(this);
    }


    function SaiTap() public {
        gapJoinExitSpread = WAD;
    }

    function mold(bytes32 param, uint val) public note auth {
        if (param == 'gap') gapJoinExitSpread = val;
    }

    // Associate with tub
    function turnAssociateTub(SaiTub tub_) public note auth {
        tub = tub_;

        sai = tub.sai();
        sin = tub.sin();
        skr = tub.skr();

        vox = tub.vox();
    }

    // Cancel debt
    function healCancelDebt() public note {
        if (joyAmountOfSurplusSai() == 0 || woeBadDebt() == 0) return;  // optimised
        var wad = min(joyAmountOfSurplusSai(), woeBadDebt());
        sai.burn(wad);
        sin.burn(wad);
    }

    // Feed price (sai per skr)
    function s2s() public returns (uint) {
        var tag = tub.tag();    // ref per skr
        var par = vox.par();    // ref per sai
        return rdiv(tag, par);  // sai per skr
    }
    // Boom price (sai per skr)
    function bidExitSkrToGems(uint wad) public returns (uint) {
        return rmul(wad, wmul(s2s(), sub(2 * WAD, gapJoinExitSpread)));
    }
    // Bust price (sai per skr)
    function ask(uint wad) public returns (uint) {
        return rmul(wad, wmul(s2s(), gapJoinExitSpread));
    }

    function flip(uint skr) internal {
        skr.push(msg.sender, skr);
        sai.pull(msg.sender, ask(skr));
        healCancelDebt();
    }

    function flop(uint skr) internal {
        skr.mint(sub(skr, fogAmountOfSkrPendingLiquidation()));
        skr.push(msg.sender, skr);
        sai.pull(msg.sender, ask(skr));
        healCancelDebt();
        require(joyAmountOfSurplusSai() == 0);  // can't flop into surplus
    }

    function flapBurnSkrAndSendSai(uint skr) internal {
        healCancelDebt();
        sai.push(msg.sender, bidExitSkrToGems(skr));
        skr.burn(msg.sender, skr);
    }

    function bustSellSomeAmountOfSaiToProcessWoe(uint skr) public note {

        require(!offStartedLiquidationPhase);
        if (skr > fogAmountOfSkrPendingLiquidation())
            flop(skr);
        else
            flip(skr);
    }

    function boomBuySomeAmountOfSaiToProcessJoy (uint skr) public note {
        require(!offStartedLiquidationPhase);
        flapBurnSkrAndSendSai(skr);
    }

    //------------------------------------------------------------------

    function cageStartLiquidationPhase(uint fixGemPerSkrSettlementPrice_) public note auth {
        require(!offStartedLiquidationPhase);
        offStartedLiquidationPhase = true;
        fixGemPerSkrSettlementPrice = fixGemPerSkrSettlementPrice_;
    }

    function cashInSaiBalanceForGemsAfterCage(uint wad) public note {
        require(offStartedLiquidationPhase);
        sai.pull(msg.sender, wad);
        require(tub.gem().transfer(msg.sender, rmul(wad, fixGemPerSkrSettlementPrice)));
    }

    function ventProcessACagedTub() public note {
        require(offStartedLiquidationPhase);

        // TODO: maybe this is vulnerable to rounding mismatch. Just
        // accumulate the sai instead, or burn on cash.  Then all the
        // sin from post-cage liquidation will just remain in the tap
        // forever.
        healCancelDebt();

        skr.burn(fogAmountOfSkrPendingLiquidation());
    }
}
