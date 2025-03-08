#/bin/sh
# Without docker prepares binaries and directories and then runs op-node
# Should match section op-node: of docker-compose.yml

CELO_PATH=${CELO_PATH:-./}

JUST=`which just`
# image: us-west1-docker.pkg.dev/devopsre/celo-blockchain-public/op-node:celo-v2.0.0-rc3
if (test "$BIN_OPNODE" == "" -a ! -f ${CELO_PATH}optimism/op-node/bin/op-node) then {
  git clone https://github.com/celo-org/optimism.git
  cd  optimism
  git checkout celo-v2.0.0-rc4
  cd op-node
  $JUST
  cd ../..
} fi;
BIN_OPNODE=${BIN_OPNODE:-${CELO_PATH}optimism/op-node/bin/op-node}

#    ports:
#      - ${PORT__OP_NODE_P2P:-9003}:9003/udp
#      - ${PORT__OP_NODE_P2P:-9003}:9003/tcp
#      - ${PORT__OP_NODE_HTTP:-9545}:9545
#    extra_hosts:
#      - "host.docker.internal:host-gateway"

# volumes:
# - ./envs/${NETWORK_NAME}/config:/chainconfig
if (test ! -d ${CELO_PATH}chainconfig) then {
  echo "Run scripts/prepare-and-run-op-geth.sh first"
  exit 1
} fi;
# - ./scripts/:/scripts
if (test "${CELO_PATH}" != "./" -a ! -d ${CELO_PATH}scripts) then {
  echo "Run scripts/prepare-and-run-op-geth.sh first"
  exit 1
} fi;
# - shared:/shared
if (test ! -d ${CELO_PATH}shared) then {
  echo "Run scripts/prepare-and-run-op-geth.sh first"
  exit 1
} fi;

# env_file:
#      - ./envs/${NETWORK_NAME}/op-node.env
cat ./envs/alfajores/op-node.env > ${CELO_PATH}.op-node-exp.env
#      - .env
cat ${CELO_PATH}.env >> ${CELO_PATH}.op-node-exp.env


#entrypoint: /scripts/start-op-node.sh
env `grep "^[^#]" ${CELO_PATH}.op-node-exp.env | tr  "\n" " "` \
   BIN_OPNODE=$BIN_OPNODE \
   CELO_PATH=$CELO_PATH \
   OPGETH_HTTP="http://localhost:8551" \
   ${CELO_PATH}scripts/start-op-node.sh 
