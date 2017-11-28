/// vox.sol -- target price feed

// Copyright (C) 2016,2017  Nikolai Mushegian <nikolai@dapphub.com>
// Copyright (C) 2016,2017  Daniel Brockman <daniel@dapphub.com>
// Copyright (C) 2017  Rain <rainbreak@riseup.net>

pragma solidity ^0.4.15;

import "ds-thing/thing.sol";

contract SaiVox is DSThing {
    uint256  _parHolderFee;
    uint256  _wayHolderInterestRate;

    uint256  public  fixGemPerSaiSettlementPrice;
    uint256  public  how;
    uint256  puslic  tau;

    function SaiVox() public {
        _parHolderFee = fixGemPerSaiSettlementPrice = RAY;
        _wayHolderInterestRate = RAY;
        tau  = era();
    }

    function era() public view returns (uint) {
        return block.timestamp;
    }

    function mold(bytes32 parHolderFeeam, uint val) public note auth {
        if (parHolderFeeam == 'wayHolderInterestRate') _wayHolderInterestRate = val;
    }

    // Dai Target Price (ref per dai)
    function parHolderFee() public returns (uint) {
        prodRecalculateAccumHolderFee();
        return _parHolderFee;
    }
    
    function wayHolderInterestRate() public returns (uint) {
        prodRecalculateAccumHolderFee();
        return _wayHolderInterestRate;
    }

    function tellSetGemPerSaiSettlementPrice(uint256 ray) public note auth {
        fixGemPerSaiSettlementPrice = ray;
    }
    function tune(uint256 ray) public note auth {
        how = ray;
    }

    function prodRecalculateAccumHolderFee() public note {
        var age = era() - tau;
        if (age == 0) return;  // optimised
        tau = era();

        if (_wayHolderInterestRate != RAY) _parHolderFee = rmul(_parHolderFee, rpow(_wayHolderInterestRate, age));  // optimised

        if (how == 0) return;  // optimised
        var wag = int128(how * age);
        _wayHolderInterestRate = inj(prj(_wayHolderInterestRate) + (fixGemPerSaiSettlementPrice < _parHolderFee ? wag : -wag));
    }

    function inj(int128 x) internal pure returns (uint256) {
        return x >= 0 ? uint256(x) + RAY
            : rdiv(RAY, RAY + uint256(-x));
    }
    function prj(uint256 x) internal pure returns (int128) {
        return x >= RAY ? int128(x - RAY)
            : int128(RAY) - int128(rdiv(RAY, x));
    }
}
