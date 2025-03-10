#!/bin/sh
set -e

BIN_EIGENDA=${BIN_EIGENDA:-eigenda-proxy}

CELO_PATH=${CELO_PATH:-/}

# Archive blobs configuration
if [ -n "$EIGENDA_LOCAL_ARCHIVE_BLOBS" ]; then
  export EXTENDED_EIGENDA_PARAMETERS="${EXTENDED_EIGENDA_PARAMETERS:-} --s3.credential-type=$EIGENDA_LOCAL_S3_CREDENTIAL_TYPE \
  --s3.access-key-id=$EIGENDA_LOCAL_S3_ACCESS_KEY_ID \
  --s3.access-key-secret=$EIGENDA_LOCAL_S3_ACCESS_KEY_SECRET \
  --s3.bucket=$EIGENDA_LOCAL_S3_BUCKET \
  --s3.path=$EIGENDA_LOCAL_S3_PATH \
  --s3.endpoint=$EIGENDA_LOCAL_S3_ENDPOINT \
  --storage.fallback-targets=s3"
  echo "EXTENDED_EIGENDA_PARAMETERS=${EXTENDED_EIGENDA_PARAMETERS}"
fi

PWD=`pwd`
cmd="exec ${BIN_EIGENDA} --addr=0.0.0.0 \
  --port=4242 \
  --eigenda.disperser-rpc='$EIGENDA_LOCAL_DISPERSER_RPC' \
  --eigenda.eth-rpc='$OP_NODE__RPC_ENDPOINT' \
  --eigenda.signer-private-key-hex=$(dd bs=1 count=32 if=/dev/urandom of=/dev/stdout | xxd -p -c 32) \
  --eigenda.svc-manager-addr='$EIGENDA_LOCAL_SVC_MANAGER_ADDR' \
  --eigenda.status-query-timeout='45m' \
  --eigenda.disable-tls=false \
  --eigenda.confirmation-depth=1 \
  --eigenda.max-blob-length='32MiB' \
  --eigenda.g1-path='$PWD/eigenda-proxy/resources/g1.point' \
  --eigenda.g2-power-of-2-path='$PWD/eigenda-proxy/resources/g2.point.powerOf2' \
  $EXTENDED_EIGENDA_PARAMETERS"
echo $cmd
eval $cmd
