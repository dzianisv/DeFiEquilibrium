#!/bin/bash

set -eu
source .env

deploy() {
    forge create --rpc-url "${ETH_RPC_URL}" --mnemonic "${ETH_WALLET_SEED}" --mnemonic-index 0 $@
}

send() {
    cast send --rpc-url "${ETH_RPC_URL}" --mnemonic "${ETH_WALLET_SEED}" --mnemonic-index 0 $@
}

token_address=$(deploy test/TestCoin.sol:TestCoin | sed -n 's/Deployed to: \(0x[a-fA-F0-9]\{40\}\)/\1/p')
send "$token_address" "mint(address,uint)" "$ETH_WALLET_ADDRESS" 1000000
asset_manager_address=$(deploy --constructor-args "${token_address}" src/AssetManager.sol:AssetManager | sed -n 's/Deployed to: \(0x[a-fA-F0-9]\{40\}\)/\1/p')
echo $asset_manager_address