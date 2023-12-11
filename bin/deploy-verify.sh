#!/bin/bash

set -eu

forge create \
    --rpc-url "${ETH_RPC_URL}"\
    --private-key "${ETH_WALLET_PRIVATE_KEY}" \
    --etherscan-api-key "null" \
    --verify \
    src/AssetManager.sol:AssetManager