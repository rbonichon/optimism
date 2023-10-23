#!/usr/bin/env bash
set -euo pipefail

make op-program

CAST="/Users/richard/foundry-nightly-5be158ba6dc7c798a6f032026fe60fc01686b33b/target/debug/cast"

L1RPC=${1:-"http://65.108.142.23:19545"}
L2RPC=${2:-"http://65.108.142.23:8545"}

L2_OUTPUT_ORACLE=0xE6Dfba0953616Bacab0c9A8ecb3a9BBa77FC15c0


L2_FINALIZED_NUMBER=$($CAST block finalized --rpc-url "${L2RPC}" -f number)
L2_FINALIZED_HASH=$($CAST block "${L2_FINALIZED_NUMBER}" --rpc-url "${L2RPC}" -f hash)

L1_FINALIZED_NUMBER=$($CAST block finalized --rpc-url "${L1RPC}" -f number)
L1_FINALIZED_HASH=$($CAST block "${L1_FINALIZED_NUMBER}" --rpc-url "${L1RPC}" -f hash)

OUTPUT_INDEX=$($CAST call --rpc-url "${L1RPC}" "${L2_OUTPUT_ORACLE}" 'getL2OutputIndexAfter(uint256) returns(uint256)' "${L2_FINALIZED_NUMBER}")
OUTPUT_INDEX=$((OUTPUT_INDEX-1))

OUTPUT=$($CAST call --rpc-url "${L1RPC}" "${L2_OUTPUT_ORACLE}" 'getL2Output(uint256) returns(bytes32,uint128,uint128)' "${OUTPUT_INDEX}")
OUTPUT_ROOT=$(echo ${OUTPUT} | cut -d' ' -f 1)
OUTPUT_TIMESTAMP=$(echo ${OUTPUT} | cut -d' ' -f 2)
OUTPUT_L2BLOCK_NUMBER=$(echo ${OUTPUT} | cut -d' ' -f 3)

L1_HEAD=$L1_FINALIZED_HASH
L2_CLAIM=$OUTPUT_ROOT
L2_BLOCK_NUMBER=$OUTPUT_L2BLOCK_NUMBER

STARTING_L2BLOCK_NUMBER=$((L2_BLOCK_NUMBER-100))
STARTING_OUTPUT_INDEX=$($CAST call --rpc-url "${L1RPC}" "${L2_OUTPUT_ORACLE}" 'getL2OutputIndexAfter(uint256) returns(uint256)' "${STARTING_L2BLOCK_NUMBER}")
STARTING_OUTPUT=$($CAST call --rpc-url "${L1RPC}" "${L2_OUTPUT_ORACLE}" 'getL2Output(uint256) returns(bytes32,uint128,uint128)' "${STARTING_OUTPUT_INDEX}")
STARTING_OUTPUT_ROOT=$(echo ${OUTPUT} | cut -d' ' -f 1)
L2_HEAD_NUMBER=$(echo ${OUTPUT} | cut -d' ' -f 3)
L2_HEAD=$($CAST block "${L2_HEAD_NUMBER}" --rpc-url "${L2RPC}" -f hash)

set -x

DATADIR=${3:-./op_program.db}

NETWORK=${4:-goerli}

# Note: You may want to tweak the --datadir directory
./op-program/bin/op-program \
    --log.level DEBUG \
    --l1 $L1RPC \
    --l2 $L2RPC \
    --network ${NETWORK} \
    --datadir ${DATADIR} \
    --l1.head $L1_HEAD \
    --l2.head $L2_HEAD \
    --l2.outputroot $STARTING_OUTPUT_ROOT \
    --l2.claim $L2_CLAIM \
    --l2.blocknumber $L2_BLOCK_NUMBER --server
