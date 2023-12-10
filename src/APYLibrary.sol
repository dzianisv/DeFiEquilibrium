// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/interfaces/IERC4626.sol";

struct Vault {
    IERC4626 vault;
    uint256 sharePrice;
}
    
library APYLibrary {
    function pricePerShare(IERC4626 _vault) internal view returns (uint256) {
        // IERC20 asset = IERC20(_vault.asset());
        // this code assumes that asset.decimals() == vault.decimals();
        // TODO: implement this with consideration that totalAssets() could be much less then vault.totalSupply()
        if (_vault.totalSupply() == 0) {
            return 0;
        }

        return  (_vault.totalAssets() * 10**3) / _vault.totalSupply();
    }
}

using APYLibrary for IERC4626;

library VaultLibrary {
    function getPeromanceIndex(Vault memory _vault) internal view returns (int256) {
        uint256 prevSharePrice = _vault.sharePrice;
        uint256 currentSharePrice = _vault.vault.pricePerShare();
        return int256(currentSharePrice) - int256(prevSharePrice);
    }
}