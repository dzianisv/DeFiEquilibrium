// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@beefy/contracts/BIFI/vaults/BeefyWrapper.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./TestCoin.sol";

contract TestERC4626Vault is ERC4626Upgradeable, Ownable {
    function initialize(TestCoin _underlyingAsset, string memory name, string memory symbolPrefix) public initializer {
        __ERC20_init(name,  string.concat(symbolPrefix, _underlyingAsset.symbol()));
        __ERC4626_init(IERC20Upgradeable(_underlyingAsset));
    }

    function _msgSender() internal view override(Context, ContextUpgradeable) returns (address) {
        return super._msgSender();
    }

    function _msgData() internal view override(Context, ContextUpgradeable) returns (bytes calldata) {
        return super._msgData();
    }

    // test function to simulate interest
    function yield(uint256 PY) public onlyOwner returns (uint256) {
        TestCoin assetToken = TestCoin(asset());
        uint256 assets = assetToken.balanceOf(address(this));
        if (assets > 0) {
            assetToken.mint(address(this), assets + assets * 100 / PY);
        }
        return assetToken.balanceOf(address(this));
    }
}

