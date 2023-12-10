#!/bin/bash

set -eux

forge build
cd web3
npm run build