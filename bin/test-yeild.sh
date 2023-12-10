#!/bin/bash

set -eu
source .env


exec forge script --broadcast --rpc-url "${ETH_RPC_URL}" --private-key "${ETH_WALLET_PRIVATE_KEY}" script/TestDeploy.s.sol:TestYield