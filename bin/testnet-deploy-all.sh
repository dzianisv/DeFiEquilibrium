#!/bin/bash

set -eu


forge script \
     --broadcast --rpc-url "${ETH_RPC_URL}" \
     --private-key "${ETH_WALLET_PRIVATE_KEY}" \
     --verify  --etherscan-api-key "null" \
     script/TestDeploy.s.sol:TestDeploy
