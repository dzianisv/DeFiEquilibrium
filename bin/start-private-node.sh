#!/bin/bash

set -euo pipefail

source .env
exec anvil --mnemonic "$ETH_WALLET_SEED"