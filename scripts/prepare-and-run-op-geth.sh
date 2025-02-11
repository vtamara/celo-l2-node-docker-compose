#/bin/sh
# Without docker prepares binaries and directories and then runs op-geth 
# Should match docker-composer.yml

CELO_PATH=${CELO_PATH:-./}

# image: us-west1-docker.pkg.dev/devopsre/celo-blockchain-public/op-geth:celo-v2.0.0-rc3
if (test "$BIN_GETH" == "" -a ! -f ${CELO_PATH}op-geth/build/bin/geth) then {
  git clone https://github.com/celo-org/op-geth.git
  cd  op-geth
  git checkout celo-v2.0.0-rc3
  make
  cd ..
} fi;
BIN_GETH=${BIN_GETH:-${CELO_PATH}op-geth/build/bin/geth}

# volumes:
# - ./envs/${NETWORK_NAME}/config:/chainconfig
if (test ! -d ${CELO_PATH}chainconfig) then {
  mkdir ${CELO_PATH}chainconfig
  cp -rf envs/alfajores/config/* ${CELO_PATH}chainconfig/
} fi;
# - ./scripts/:/scripts
if (test "${CELO_PATH}" != "./") then {
  mkdir ${CELO_PATH}scripts
  cp -rf scripts/* ${CELO_PATH}scripts/
} fi;
# - shared:/shared
if (test ! -d ${CELO_PATH}shared) then {
  mkdir ${CELO_PATH}shared
} fi;
# - ${DATADIR_PATH}:/geth alfajores.env includes DATADIR_PATH=./envs/${NETWORK_NAME}/datadir
if (test ! -d ${CELO_PATH}geth) then {
  mkdir ${CELO_PATH}geth
} fi;

# env_file:
# - ./envs/${NETWORK_NAME}/op-geth.env
sed -e "s|/geth|${CELO_PATH}geth|g" envs/alfajores/op-geth.env > ${CELO_PATH}.env
# - .env
cat alfajores.env >> ${CELO_PATH}.env

env `grep "^[^#]" .env | tr  "\n" " "` BIN_GETH=$BIN_GETH CELO_PATH=$CELO_PATH ${CELO_PATH}scripts/start-op-geth.sh 
