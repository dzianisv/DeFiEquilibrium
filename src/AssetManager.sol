// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@beefy/contracts/BIFI/vaults/BeefyWrapper.sol";
import "@openzeppelin/contracts/interfaces/IERC4626.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";

import "./APYLibrary.sol";

contract AssetManager is ERC4626Upgradeable, Ownable {
    using APYLibrary for IERC4626;
    using VaultLibrary for Vault;
    using MathUpgradeable for uint256;

    Vault[] public vaults;
    IERC4626[] public activeVaults;

    uint8 public diversification = 3;

    function initialize(IERC20Metadata _underlyingAsset) public initializer {
        __ERC20_init(
            string.concat(
                "Assets Manager Tokenized Yield-bearing vault for ",
                _underlyingAsset.name()
            ),
            string.concat("a", _underlyingAsset.symbol())
        );
        __ERC4626_init(IERC20MetadataUpgradeable(address(_underlyingAsset)));
    }

    function _msgSender()
        internal
        view
        override(Context, ContextUpgradeable)
        returns (address)
    {
        return super._msgSender();
    }

    function _msgData()
        internal
        view
        override(Context, ContextUpgradeable)
        returns (bytes calldata)
    {
        return super._msgData();
    }

    function addBeefyVault(IVault _vault) public onlyOwner returns (IERC4626) {
        BeefyWrapper wraper = new BeefyWrapper();
        wraper.initialize(address(_vault), _vault.name(), _vault.symbol());
        IERC4626 vault = IERC4626(address(wraper));
        addVault(vault);
        return vault;
    }

    // TODO: 3. Inefficient Looping: The addVault and removeVault functions loop through the entire vaults array to check if a vault exists or to remove a vault. This could be inefficient as the number of vaults increases. Consider using a mapping for constant time lookups and deletions.
    function addVault(IERC4626 _vault) public onlyOwner {
        require(address(_vault) != address(0), "invalid vault address");
        for (uint256 i = 0; i < vaults.length; i++) {
            require(vaults[i].vault != _vault, "Vault already exists");
        }
        vaults.push(Vault(_vault, _vault.pricePerShare()));
    }

    // TODO: 3. Inefficient Looping: The addVault and removeVault functions loop through the entire vaults array to check if a vault exists or to remove a vault. This could be inefficient as the number of vaults increases. Consider using a mapping for constant time lookups and deletions.
    function removeVault(IERC4626 _vault) public onlyOwner {
        for (uint256 i = 0; i < vaults.length; i++) {
            if (vaults[i].vault == _vault) {
                vaults[i] = vaults[vaults.length - 1];
                vaults.pop();
                break;
            }
        }
    }

    function totalAssets()
        public
        view
        virtual
        override(ERC4626Upgradeable)
        returns (uint256)
    {
        uint total = IERC20(asset()).balanceOf(address(this));

        for (uint i = 0; i < activeVaults.length; i++) {
            IERC4626 v = activeVaults[i];
            total += v.totalAssets();
        }

        return total;
    }

    function getPerfomanceIndex(IERC4626 _vault) public view returns (int256) {
        for (uint i = 0; i < vaults.length; i++) {
            Vault storage v = vaults[i];
            if (v.vault == _vault) {
                return v.getPeromanceIndex();
            }
        }

        return 0;
    }

    function reinvest() public onlyOwner returns (uint256) {
        ERC20 assetToken = ERC20(asset());

        uint256 reinvested = 0;
        int256[] memory vaultsSharePriceIncrease = new int256[](vaults.length);

        for (uint i = 0; i < vaults.length; i++) {
            Vault storage v = vaults[i];
            vaultsSharePriceIncrease[i] = v.getPeromanceIndex();
            v.sharePrice = v.vault.pricePerShare();
        }

        // Sort vaults by share price increase
        uint256[] memory sortedIndices = sortVaultsByPerformance(
            vaultsSharePriceIncrease
        );

        // Create an array of top-performing vault addresses
        address[] memory vaultsForReinvestment = new address[](diversification);
        for (uint i = 0; i < diversification; i++) {
            vaultsForReinvestment[i] = address(vaults[sortedIndices[i]].vault);
        }

        // Withdraw from active vaults that are not in the top-performing list
        uint256 len = activeVaults.length;
        uint vaultsForReinvestmentN = vaultsForReinvestment.length;

        for (uint i = 0; i < len; i++) {
            int256 idx = indexOf(
                address(activeVaults[i]),
                vaultsForReinvestment
            );
            if (idx == -1) {
                // Withdraw all assets from the non-top performing vault
                uint256 amount = activeVaults[i].balanceOf(address(this));
                activeVaults[i].redeem(amount, address(this), address(this));

                // Remove the vault from activeVaults
                activeVaults[i] = activeVaults[len - 1];
                activeVaults.pop();
                len--;
                i--;
            } else {
                // if vault already in the activeVaults set, then remove it from vaultsForReinvestment
                vaultsForReinvestment[uint(idx)] = vaultsForReinvestment[
                    vaultsForReinvestmentN - 1
                ];
                vaultsForReinvestmentN--;
            }
        }

        uint countToReinvest = vaultsForReinvestment.length -
            activeVaults.length;

        if (countToReinvest == 0) {
            return countToReinvest;
        }

        // Deposit all available assets evenly across the top-performing vaults
        uint256 amountToDeposit = assetToken.balanceOf(address(this)) /
            countToReinvest;

        // Deposit into top-performing vaults
        for (uint i = 0; i < vaultsForReinvestmentN; i++) {
            IERC4626 currentVault = IERC4626(vaultsForReinvestment[i]);
            assetToken.increaseAllowance(
                address(currentVault),
                amountToDeposit
            );
            currentVault.deposit(amountToDeposit, address(this));

            // Add the vault to activeVaults
            activeVaults.push(currentVault);
            reinvested++;
        }

        return reinvested;
    }

    function _redistribute() internal {
        ERC20 assetToken = ERC20(asset());
        require(activeVaults.length > 0, "no active vaults");

        // redistribute after depositing
        uint depositAmount = assetToken.balanceOf(address(this)) /
            activeVaults.length;

        if (depositAmount > 0) {
            for (uint i = 0; i < activeVaults.length; i++) {
                IERC4626 currentVault = activeVaults[i];
                assetToken.increaseAllowance(
                    address(currentVault),
                    depositAmount
                );
                currentVault.deposit(depositAmount, address(this));
            }
        }
    }

    function indexOf(
        address item,
        address[] memory list
    ) internal pure returns (int256) {
        for (uint i = 0; i < list.length; i++) {
            if (item == list[i]) {
                return int256(i);
            }
        }
        return -1;
    }

    // The sortVaultsByPerformance function remains unchanged

    // A function to sort vaults by their performance
    function sortVaultsByPerformance(
        int256[] memory increases
    ) internal pure returns (uint256[] memory) {
        uint256[] memory indices = new uint256[](increases.length);

        for (uint i = 0; i < increases.length; i++) {
            indices[i] = i;
        }

        // Simple insertion sort. For a larger number of vaults, a more efficient sorting algorithm might be necessary.
        for (uint i = 1; i < increases.length; i++) {
            uint j = i;
            while (j > 0 && increases[indices[j]] > increases[indices[j - 1]]) {
                (indices[j], indices[j - 1]) = (indices[j - 1], indices[j]);
                j--;
            }
        }

        return indices;
    }

    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) public virtual override(ERC4626Upgradeable) returns (uint256) {
        _requireAssets(assets);
        return super.withdraw(assets, receiver, owner);
    }

    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) public virtual override(ERC4626Upgradeable) returns (uint256) {
        _requireAssets(convertToAssets(shares));
        return super.redeem(shares, receiver, owner);
    }

    // withdraw more liquidity to pay back
    function _requireAssets(uint256 assets) internal {
        IERC20 assetToken = IERC20(asset());
        uint i = 0;
        while (
            assets > assetToken.balanceOf(address(this)) &&
            i < activeVaults.length
        ) {
            IERC4626 vault = IERC4626(activeVaults[i]);
            vault.withdraw(
                assets.min(vault.totalAssets()),
                address(this),
                address(this)
            );
            i++;
        }

        require(
            assets <= assetToken.balanceOf(address(this)),
            "no enough tokens"
        );
    }

    function deposit(
        uint256 assets,
        address receiver
    ) public virtual override(ERC4626Upgradeable) returns (uint256) {
        uint256 r = super.deposit(assets, receiver);
        _redistribute();
        return r;
    }

    function mint(
        uint256 shares,
        address receiver
    ) public virtual override(ERC4626Upgradeable) returns (uint256) {
        uint256 r = super.mint(shares, receiver);
        _redistribute();
        return r;
    }

    function getVaults() public view returns (address[] memory) {
        address[] memory r = new address[](vaults.length);
        for (uint i = 0; i < vaults.length; i++) {
            r[i] = address(vaults[i].vault);
        }

        return r;
    }
}
