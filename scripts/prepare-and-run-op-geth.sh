#/bin/sh
# Without docker prepares binaries and directories and then runs op-geth 
# Based on docker-composer.yml

if (test "$CELOPATH" = "") then {
  CELOPATH="./"
} fi;

# image: us-west1-docker.pkg.dev/devopsre/celo-blockchain-public/op-geth:celo-v2.0.0-rc3
if (test ! -f ${CELOPATH}op-geth/build/bin/geth) then {
  git clone https://github.com/celo-org/op-geth.git
  cd  op-geth
  git checkout celo-v2.0.0-rc3
  make
  cd ..
} fi;

echo $PATH | grep op-geth > /dev/null
if (test "$?" != "0") then {
  export PATH="$PATH:$(pwd)/op-geth/build/bin"
} fi;

# volumes:
# - ./envs/${NETWORK_NAME}/config:/chainconfig
if (test ! -d ${CELOPATH}chainconfig) then {
  mkdir ${CELOPATH}chainconfig
  cp -rf envs/alfajores/config/* ${CELOPATH}chainconfig/
} fi;
# - ./scripts/:/scripts
# - shared:/shared
if (test ! -d ${CELOPATH}shared) then {
  mkdir ${CELOPATH}shared
} fi;
# - ${DATADIR_PATH}:/geth alfajores.env includes DATADIR_PATH=./envs/${NETWORK_NAME}/datadir
if (test ! -d ${CELOPATH}geth) then {
  mkdir ${CELOPATH}geth
} fi;

# env_file:
# - ./envs/${NETWORK_NAME}/op-geth.env
sed -e "s/\/geth/.\/geth/g" envs/alfajores/op-geth.env > ${CELOPATH}.env
# - .env
cat alfajores.env >> ${CELOPATH}.env

GETH=${CELOPATH}op-geth/build/bin/geth

env `grep "^[^#]" .env | tr  "\n" " "` GETH=$GET CELOPATH=$CELOPATH PATH=$PATH ${CELOPATH}scripts/start-op-geth.sh 
