// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console2} from "forge-std/Script.sol";

import "@openzeppelin/contracts/interfaces/IERC4626.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {Test, console2} from "forge-std/Test.sol";
import {AssetManager} from "../src/AssetManager.sol";
import "../test/TestCoin.sol";
import "../test/TestERC4626Vault.sol";


contract TestDeploy is Script {
    function run() public {
        vm.startBroadcast();
        TestCoin coin = new TestCoin();

        console2.log("TestCoin: ", address(coin));

        AssetManager aManager = new AssetManager();
        aManager.initialize(IERC20Metadata(address(coin)));

        console2.log("AssetManager: ", address(aManager));

        TestERC4626Vault[5] memory vaults;
        string[5] memory vaultNames = ["Whale Wading Wonderland", "Stablecoin Slip 'n Slide", "USDC Circus Splash", "Dollar Drenched Delight", "Liquid Laughter Lagoon"];
        string[5] memory vaultSymbols = ["wading", "slip", "circus", "drenched", "liquid"];

        for (uint i = 0; i < vaults.length; i++) {
            TestERC4626Vault vault = new TestERC4626Vault();
            vault.initialize(coin, vaultNames[i], vaultSymbols[i]);
            aManager.addVault(IERC4626(address(vault)));
            console2.log("Vault: ", address(vault));
            vaults[i] = vault;
        }

        aManager.reinvest();

        uint amount = 1000 * 10** coin.decimals();
        coin.mint(msg.sender, amount);
        coin.approve(address(aManager), amount);


        vm.stopBroadcast();
    }
}

contract TestYield is Script {
    function run() public {
        address[5] memory vaults = [
            address(0xdd1962fAB14a8635aD037B5d59DAd67361e1bA3B),
            address(0xDEdE69A14fd671d98894104A3D29e91b95fF7F76),
            address(0x2b6e4EB06C8e93F1bb6dd7Ff58dF0c0726952a1D),
            address(0xF5a7244a37c69A29b7e4Db804C4f532b4be7Fd67),
            address(0x143F557E3e44B4f1bc7a3Bd6b5e514D5742bdf43)
        ];

        vm.startBroadcast();
        for (uint i = 0; i < vaults.length; i++) {
            TestERC4626Vault vault = TestERC4626Vault(vaults[i]);
            vault.yield((i+1)* 10);
        }
        vm.stopBroadcast();
    }
}
