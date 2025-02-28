#!/bin/sh
set -e

BIN_GETH=${BIN_GETH:-geth}

CELO_PATH=${CELO_PATH:-/}

# Create JWT if it doesn't exist
if [ ! -f "${CELO_PATH}shared/jwt.txt" ]; then
  echo "Creating JWT..."
  mkdir -p ${CELO_PATH}shared
  dd bs=1 count=32 if=/dev/urandom of=/dev/stdout | xxd -p -c 32 > ${CELO_PATH}shared/jwt.txt
fi

# Check if either OP_GETH__HISTORICAL_RPC or HISTORICAL_RPC_DATADIR_PATH is set and if so set the historical rpc option.
if [ -n "$OP_GETH__HISTORICAL_RPC" ] || [ -n "$HISTORICAL_RPC_DATADIR_PATH" ] ; then
  export EXTENDED_ARG="${EXTENDED_ARG:-} --rollup.historicalrpc=${OP_GETH__HISTORICAL_RPC:-http://historical-rpc-node:8545}"
fi

if [ -n "$IPC_PATH" ]; then
  export EXTENDED_ARG="${EXTENDED_ARG:-} --ipcpath=$IPC_PATH"
fi

# Init genesis if it's a custom chain and the datadir is empty
if [ -n "${IS_CUSTOM_CHAIN}" ] && [ -z "$(ls -A "$BEDROCK_DATADIR")" ]; then
  echo "Initializing custom chain genesis..."
  ${BIN_GETH} init --datadir="$BEDROCK_DATADIR" ${CELO_PATH}chainconfig/genesis.json
fi

# Determine syncmode based on NODE_TYPE
if [ -z "$OP_GETH__SYNCMODE" ]; then
  if [ "$NODE_TYPE" = "full" ]; then
    export OP_GETH__SYNCMODE="snap"
  else
    export OP_GETH__SYNCMODE="full"
  fi
fi

# Start op-geth.
exec ${BIN_GETH} \
  --datadir="$BEDROCK_DATADIR" \
  --http \
  --http.corsdomain="*" \
  --http.vhosts="*" \
  --http.addr=0.0.0.0 \
  --http.port=8545 \
  --http.api=web3,debug,eth,txpool,net,engine \
  --ws \
  --ws.addr=0.0.0.0 \
  --ws.port=8546 \
  --ws.origins="*" \
  --ws.api=debug,eth,txpool,net,engine,web3 \
  --metrics \
  --metrics.influxdb \
  --metrics.influxdb.endpoint=http://influxdb:8086 \
  --metrics.influxdb.database=opgeth \
  --syncmode="$OP_GETH__SYNCMODE" \
  --gcmode="$NODE_TYPE" \
  --authrpc.vhosts="*" \
  --authrpc.addr=0.0.0.0 \
  --authrpc.port=8551 \
  --authrpc.jwtsecret=${CELO_PATH}shared/jwt.txt \
  --rollup.sequencerhttp="$BEDROCK_SEQUENCER_HTTP" \
  --rollup.disabletxpoolgossip=true \
  --port="${PORT__OP_GETH_P2P:-39393}" \
  --discovery.port="${PORT__OP_GETH_P2P:-39393}" \
  --snapshot=true \
  --verbosity=3 \
  --history.transactions=0 \
  $EXTENDED_ARG $@

