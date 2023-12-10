// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@beefy/contracts/BIFI/vaults/BeefyWrapper.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

// interface IVault {
//     function deposit(uint256) external;
//     function withdraw(uint256) external;
//     function balance() external view returns (uint256);
//     function want() external view returns (IERC20MetadataUpgradeable);
//     function totalSupply() external view returns (uint256);
//     function name() external view returns (string memory);
//     function symbol() external view returns (string memory);
// }


contract TestBeefyVault is IVault {
    IERC20MetadataUpgradeable public coin;

    constructor(IERC20MetadataUpgradeable _coin) {
        coin = _coin;
    }

    function deposit(uint256 _amount) external {

    }

    function withdraw(uint256 _shares) external {

    }

    function balance() external view returns (uint256) {
        return 1;
    }

    function available() external view returns (uint256) {
        return 1;
    }

    function totalSupply() external view returns (uint256) {
        return 1;
    }

    function name() external view returns (string memory) {
        return "Test Vault";
    }

    function symbol() external view returns (string memory) {
        return "TestVault";
    }

    function want() external view returns (IERC20MetadataUpgradeable) {
        return IERC20MetadataUpgradeable(coin);
    }
}
