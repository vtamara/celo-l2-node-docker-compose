#!/bin/sh
set -e

CELO_PATH=${CELO_PATH:-/}

OPNODE=${OPNODE:-opnode}

if [ -n "${IS_CUSTOM_CHAIN}" ]; then
  export EXTENDED_ARG="${EXTENDED_ARG:-} --rollup.config=${CELO_PATH}chainconfig/rollup.json"
else
  export EXTENDED_ARG="${EXTENDED_ARG:-} --network=$NETWORK_NAME --rollup.load-protocol-versions=true --rollup.halt=major"
fi

# OP_NODE_ALTDA_DA_SERVER is picked up by the op-node binary.
export OP_NODE_ALTDA_DA_SERVER=$EIGENDA_PROXY_ENDPOINT
if [ -n $USE_LOCAL_EIGENDA_PROXY_IF_UNSET ]; then
  OP_NODE_ALTDA_DA_SERVER="http://eigenda-proxy:4242"
fi

# Start op-node.
exec ${OPNODE} \
  --l1=$OP_NODE__RPC_ENDPOINT \
  --l2=http://op-geth:8551 \
  --rpc.addr=0.0.0.0 \
  --rpc.port=9545 \
  --l2.jwt-secret=${CELO_PATH}shared/jwt.txt \
  --l1.trustrpc \
  --l1.rpckind=$OP_NODE__RPC_TYPE \
  --l1.beacon=$OP_NODE__L1_BEACON \
  --metrics.enabled \
  --metrics.addr=0.0.0.0 \
  --metrics.port=7300 \
  --syncmode=execution-layer \
  --p2p.priv.path=${CELO_PATH}shared/op-node_p2p_priv.txt \
  $EXTENDED_ARG $@
