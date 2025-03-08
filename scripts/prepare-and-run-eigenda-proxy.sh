#/bin/sh
# Without docker prepares binaries and directories and then runs eigenda-proxy
# Should match section eigenda-proxy: of docker-compose.yml

CELO_PATH=${CELO_PATH:-./}

#    image: ghcr.io/layr-labs/eigenda-proxy:v1.6.4
if (test "$BIN_EIGENDA" == "" -a ! -f ${CELO_PATH}eigenda-proxy/bin/eigenda-proxy) then {
  git clone https://github.com/Layr-Labs/eigenda-proxy.git
  cd  eigenda-proxy
  git checkout v1.6.4
  gmake
  cd ..
} fi;
BIN_EIGENDA=${BIN_EIGENDA:-${CELO_PATH}eigenda-proxy/bin/eigenda-proxy}

# volumes:
# - ./scripts/:/scripts
if (test "${CELO_PATH}" != "./" -a ! -d ${CELO_PATH}scripts) then {
  echo "Run scripts/prepare-and-run-op-geth.sh first"
  exit 1
} fi;
# - eigenda-data:/data
if (test ! -d ${CELO_PATH}eigenda-data) then {
  mkdir ${CELO_PATH}eigenda-data
} fi;

# env_file:
#      - .env
cat ${CELO_PATH}.env > ${CELO_PATH}.eigenda-exp.env

# ports:
#      - ${PORT_EIGENDA_PROXY:-4242}:4242
#    extra_hosts:
#      - "host.docker.internal:host-gateway"
#    deploy:
      # If USE_LOCAL_EIGENDA_PROXY_IF_UNSET is unset or empty, then we set replicas to 1,
      # otherwise use the value of USE_LOCAL_EIGENDA_PROXY_IF_UNSET which should be 0.
#      replicas: ${USE_LOCAL_EIGENDA_PROXY_IF_UNSET:-1}

# entrypoint: /scripts/start-eigenda-proxy.sh
env `grep "^[^#]" ${CELO_PATH}.eigenda-exp.env | tr  "\n" " "` EIGENDA_LOCAL_ARCHIVE_BLOBS="" BIN_EIGENDA=$BIN_EIGENDA CELO_PATH=$CELO_PATH ${CELO_PATH}scripts/start-eigenda-proxy.sh 
