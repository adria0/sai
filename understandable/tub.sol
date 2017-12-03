/// tub.sol -- simplified CDP engine (baby brother of `vat')

// Copyright (C) 2017  Nikolai Mushegian <nikolai@dapphub.com>
// Copyright (C) 2017  Daniel Brockman <daniel@dapphub.com>
// Copyright (C) 2017  Rain <rainbreak@riseup.net>

pragma solidity ^0.4.15;

import "ds-thing/thing.sol";
import "ds-token/token.sol";
import "ds-value/value.sol";

import "./voxTargetPriceFeed.sol";

contract SaiTubEvents {
    event LogNewCup(address indexed lapOwner, bytes32 cup);
}

contract SaiTub is DSThing, SaiTubEvents {

    DSToken  public  sai;  // Stablecoin
    DSToken  public  sin;  // Debt (negative sai)

    DSToken  public  skr;  // Abstracted collateral
    ERC20    public  gem;  // Underlying collateral

    DSToken  public  gov;  // Governance token

    SaiVox   public  voxTargetPriceFeed;  // Target price feed
    DSValue  public  pipDollarsPerGem;  // Reference price feed
    DSValue  public  pepGovernancePriceFeed;  // Governance price feed

    address  public  tap;  // Liquidator
    address  public  pitGovernanceWallet;  // Governance Vault

    uint256  public  axeLiquidationPenality;  // Liquidation penalty
    uint256  public  hatMaxSaiDebt;  // Debt ceiling
    uint256  public  matLiquidationRatio;  // Liquidation ratio
    uint256  public  taxStabilityFee;  // Stability fee
    uint256  public  feeGovernance;  // Governance fee
    uint256  public  gapJoinExitSpread;  // Join-Exit Spread

    bool     public  offStartedLiquidationPhase;  // Cage flag
    bool     public  outReadyToExit;  // Post cageStartLiquidationPhase exit

    uint256  public  fixGemPerSkrSettlementPrice;  // REF per SKR (just before settlement)

    uint256  public  rho;  // Time of last dripUpdateTaxRatesAndTopupTAP
    uint256         _chi;  // Accumulated Tax Rates
    uint256         _rhi;  // Accumulated Tax + Fee Rates
    uint256  public  rumTotalSaiDebtChiNorm;  // Total normalised debt

    uint256                   public  cupi;
    mapping (bytes32 => Cup)  public  cups;

    struct Cup {
        address  lapOwner; // CDP owner
        uint256  inkSkrCount; // Locked collateral (in SKR)
        uint256  artSaiDebtChiNorm;      // OutstandinTotalSaiDebtWithoutNormg normalised debt (tax only)
        uint256  irkSaiDebtRhiNorm;      // OutstandinTotalSaiDebtWithoutNormg normalised debt
    }

    function lapOwner(bytes32 cup) public view returns (address) {
        return cups[cup].lapOwner;
    }
    function inkSkrCount(bytes32 cup) public view returns (uint) {
        return cups[cup].inkSkrCount;
    }
    function tabCupSaiDebtWithoutNorm(bytes32 cup) public returns (uint) {
        return rmul(cups[cup].artSaiDebtChiNorm, chiAccumuTax());
    }
    function rapCupGovernanceDebt(bytes32 cup) public returns (uint) {
        return sub(rmul(cups[cup].irkSaiDebtRhiNorm, rhi()), tabCupSaiDebtWithoutNorm(cup));
    }

    // Total CDP Debt
    function dinTotalSaiDebtWithoutNorm() public returns (uint) {
        return rmul(rumTotalSaiDebtChiNorm, chiAccumuTax());
    }
    // Backing collateral
    function airSkrInContract() public view returns (uint) {
        return skr.balanceOf(this);
    }
    // Raw collateral
    function pieGemsInContract() public view returns (uint) {
        return gem.balanceOf(this);
    }

    //------------------------------------------------------------------

    function SaiTub(
        DSToken  sai_,
        DSToken  sin_,
        DSToken  skr_,
        ERC20    gem_,
        DSToken  gov_,
        DSValue  pipDollarsPerGem_,
        DSValue  pepGovernancePriceFeed_,
        SaiVox   voxTargetPriceFeed_,
        address  tap_,
        address  pitGovernanceWallet_
    ) public {
        gem = gem_;
        skr = skr_;

        sai = sai_;
        sin = sin_;

        gov = gov_;
        pitGovernanceWallet = pitGovernanceWallet_;

        pipDollarsPerGem = pipDollarsPerGem_;
        pepGovernancePriceFeed = pepGovernancePriceFeed_;
        voxTargetPriceFeed = voxTargetPriceFeed_;
        tap = tap_;

        axeLiquidationPenality = RAY;
        matLiquidationRatio = RAY;
        taxStabilityFee = RAY;
        feeGovernance = RAY;
        gapJoinExitSpread = WAD;

        _chi = RAY;
        _rhi = RAY;

        rho = era();
    }

    function era() public constant returns (uint) {
        return block.timestamp;
    }

    //--Risk-parameter-config-------------------------------------------

    function mold(bytes32 param, uint val) public note auth {
        if      (param == 'hatMaxSaiDebt') hatMaxSaiDebt = val;
        else if (param == 'matLiquidationRatio') matLiquidationRatio = val;
        else if (param == 'tax') { require(val >= RAY); dripUpdateTaxRatesAndTopupTAP(); taxStabilityFee = val; }
        else if (param == 'fee') { require(val >= RAY); dripUpdateTaxRatesAndTopupTAP(); feeGovernance = val; }
        else if (param == 'axeLiquidationPenality') axeLiquidationPenality = val;
        else if (param == 'gapJoinExitSpread') gapJoinExitSpread = val;
        else return;
    }

    //--Collateral-wrapper----------------------------------------------

    // Wrapper ratio (gem per skr)
    function perGemPerSkrGlobalRatio() public view returns (uint ray) {
        // per = gem.balanceOf(this) / skr.totalSupply()
        return skr.totalSupply() == 0 ? RAY : rdiv(pieGemsInContract(), skr.totalSupply());
    }

    // Join price (gem per skr)
    function askJoinSkrToGems(uint skrs) public view returns (uint) {
        return rmul(skrs, wmul(perGemPerSkrGlobalRatio(), gapJoinExitSpread));
    }

    // Exit price (gem per skr)
    function bidExitSkrToGems(uint skrs) public view returns (uint) {
        return rmul(skrs, wmul(perGemPerSkrGlobalRatio(), sub(2 * WAD, gapJoinExitSpread)));
    }

    function join(uint skrs) public note {
        require(!offStartedLiquidationPhase);
        require(gem.transferFrom(msg.sender, this, askJoinSkrToGems(skrs)));
        skr.mint(msg.sender, skrs);
    }

    function exit(uint skrs) public note {
        require(!offStartedLiquidationPhase || outReadyToExit);
        require(gem.transfer(msg.sender, bidExitSkrToGems(skrs)));
        skr.burn(msg.sender, skrs);
    }

    //--Stability-fee-accumulation--------------------------------------

    // Accumulated Rates
    function chiAccumuTax() public returns (uint) {
        dripUpdateTaxRatesAndTopupTAP();
        return _chi;
    }
    function rhi() public returns (uint) {
        dripUpdateTaxRatesAndTopupTAP();
        return _rhi;
    }

    function dripUpdateTaxRatesAndTopupTAP() public note {
        if (offStartedLiquidationPhase) return;

        var rho_ = era();
        var age = rho_ - rho;
        if (age == 0) return;    // optimised
        rho = rho_;

        var inc = RAY;

        if (taxStabilityFee != RAY) {  // optimised
            inc = rpow(taxStabilityFee, age);
            var dinTotalSaiDebtWithoutNorm_ = dinTotalSaiDebtWithoutNorm();
            _chi = rmul(_chi, inc);

            sai.mint(tap, sub(dinTotalSaiDebtWithoutNorm(), dinTotalSaiDebtWithoutNorm_));
        }

        // optimised //  fee^deltarho
        if (feeGovernance != RAY) inc = rmul(inc, rpow(feeGovernance, age));
        if (inc != RAY) _rhi = rmul(_rhi, inc);
    }

    //--CDP-risk-indicator----------------------------------------------

    // Abstracted collateral price (ref per skr)
    function tagDollarsPerSkr() public view returns (uint wad) {
        // per = gem.balanceOf(this) / skr.totalSupply() 
        // tag = pip * ( gem.balanceOf(this) / skr.totalSupply() )
        return offStartedLiquidationPhase ? fixGemPerSkrSettlementPrice : wmul(perGemPerSkrGlobalRatio(), uint(pipDollarsPerGem.read()));
    }

    // Returns true if cup is well-collateralized
    function safe(bytes32 cup) public returns (bool) {
        var pro = rmul(tagDollarsPerSkr(), inkSkrCount(cup));
        var min = rmul(
            rmul(voxTargetPriceFeed.parHolderFee(), tabCupSaiDebtWithoutNorm(cup)),
            matLiquidationRatio
        );
        return pro >= min;
    }

    tagDollarsPerSkr() *  inkSkrCount(cup)
    (perGemPerSkrGlobalRatio() * uint(pipDollarsPerGem.read()) * inkSkrCount(cup)
    (perGemPerSkrGlobalRatio() * uint(pipDollarsPerGem.read()) * cups[cup].ink


    voxTargetPriceFeed.parHolderFee() * tabCupSaiDebtWithoutNorm(cup) * matLiquidationRatio

    tagDollarsPerSkr() * inkSkrCount(cup) >= 
    voxTargetPriceFeed.parHolderFee() * tabCupSaiDebtWithoutNorm(cup) * matLiquidationRatio


    //--CDP-operations--------------------------------------------------

    function openCreateCup() public note returns (bytes32 cup) {
        require(!offStartedLiquidationPhase);
        cupi = add(cupi, 1);
        cup = bytes32(cupi);
        cups[cup].lapOwner = msg.sender;
        LogNewCup(msg.sender, cup);
    }

    function giveTransferCupOwnership(bytes32 cup, address guy) public note {
        require(msg.sender == cups[cup].lapOwner);
        require(guy != 0);
        cups[cup].lapOwner = guy;
    }

    function lockSkrsInCup(bytes32 cup, uint skrs) public note {
        require(!offStartedLiquidationPhase);
        require(msg.sender == cups[cup].lapOwner);
        cups[cup].inkSkrCount = add(cups[cup].inkSkrCount, skrs);
        skr.pull(msg.sender, skrs);
    }


    function freeUnlockSkrsFromCup(bytes32 cup, uint skrs) public note {
        require(msg.sender == cups[cup].lapOwner);
        cups[cup].inkSkrCount = sub(cups[cup].inkSkrCount, skrs);
        skr.push(msg.sender, skrs);
        require(safe(cup));
    }

    function drawCreateSaiDebt(bytes32 cup, uint sais) public note {
        require(!offStartedLiquidationPhase);

        require(msg.sender == cups[cup].lapOwner);

        // update cup.art & rum
        cups[cup].artSaiDebtChiNorm = add(cups[cup].artSaiDebtChiNorm, rdiv(sais, chiAccumuTax()));
        rumTotalSaiDebtChiNorm = add(rumTotalSaiDebtChiNorm, rdiv(sais, chiAccumuTax()));

        // update irk
        cups[cup].irkSaiDebtRhiNorm = add(cups[cup].irkSaiDebtRhiNorm, rdiv(sais, rhi()));

        // mint sais
        sai.mint(cups[cup].lapOwner, sais);

        // check if all is safe
        require(safe(cup));
        require(sai.totalSupply() <= hatMaxSaiDebt);
    }


    function wipeReturnSaiDebt(bytes32 cup, uint sais) public note {
        require(!offStartedLiquidationPhase);
        require(msg.sender == cups[cup].lapOwner);

        // update cup.art & rum
        cups[cup].artSaiDebtChiNorm = sub(cups[cup].artSaiDebtChiNorm, rdiv(sais, chiAccumuTax()));
        rumTotalSaiDebtChiNorm = sub(rumTotalSaiDebtChiNorm, rdiv(sais, chiAccumuTax()));

        // destroy sais
        sai.burn(msg.sender, sais);

        // update governance irk
        var owe = rmul(sais, rdiv(rapCupGovernanceDebt(cup), tabCupSaiDebtWithoutNorm(cup)));
        cups[cup].irkSaiDebtRhiNorm = sub(cups[cup].irkSaiDebtRhiNorm, rdiv(add(sais, owe), rhi()));
        
        // move governance tokens
        var (val, ok) = pepGovernancePriceFeed.peek();
        if (ok && val != 0) gov.move(msg.sender, pitGovernanceWallet, wdiv(owe, uint(val)));
    }


    function shutDownMyCup(bytes32 cup) public note {
        require(!offStartedLiquidationPhase);
        require(msg.sender == cups[cup].lapOwner);

        // destroy sais and set the sai debt to zero
        if (tabCupSaiDebtWithoutNorm(cup) != 0)
            wipeReturnSaiDebt(cup, tabCupSaiDebtWithoutNorm(cup));

        // send back the skrs to owner
        if (inkSkrCount(cup) != 0)
            freeUnlockSkrsFromCup(cup, inkSkrCount(cup));

        delete cups[cup];
    }

    // initiate liquidation of an undercollateral cup
    function biteDestroyCup(bytes32 cup) public note {
        require(!safe(cup) || offStartedLiquidationPhase);

        // Take on all of the debt, except unpaid fees
        var saiDebt = tabCupSaiDebtWithoutNorm(cup);

        // create SIN in TAP exactly the amount
        sin.mint(tap, saiDebt);
        rumTotalSaiDebtChiNorm = sub(rumTotalSaiDebtChiNorm, cups[cup].artSaiDebtChiNorm);

        cups[cup].artSaiDebtChiNorm = 0;
        cups[cup].irkSaiDebtRhiNorm = 0;

        // Amount owed in SKR, including liquidation penalty
        var owed = rdiv(
            rmul(
                rmul(saiDebt, axeLiquidationPenality),
                voxTargetPriceFeed.parHolderFee()
            ),
            tagDollarsPerSkr()
        );

        if (owed > cups[cup].inkSkrCount) {
            owed = cups[cup].inkSkrCount;
        }

        // transfer SKRs to TAP
        skr.push(tap, owed);
        cups[cup].inkSkrCount = sub(cups[cup].inkSkrCount, owed);
    }

    // only can be executed by top contract
    function cageStartLiquidationPhase(uint fixGemPerSkrSettlementPrice_, uint jam) public note auth {
        require(!offStartedLiquidationPhase && fixGemPerSkrSettlementPrice_ != 0);

        offStartedLiquidationPhase = true;

        axeLiquidationPenality = RAY;
        fixGemPerSkrSettlementPrice = fixGemPerSkrSettlementPrice_;         // ref per skr

        /// #amb -> is possible that some gems could be trapped in the contract due a cage?
        require(gem.transfer(tap, jam));
    }

    
    function flowSetReadyToExit() public note auth {
        require(offStartedLiquidationPhase);
        outReadyToExit = true;
    }

}
