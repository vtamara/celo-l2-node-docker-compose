#/bin/sh
# Prepares binaries and environment and runs op-geth based on 
# section op-geth: of docker-composer.yml and variables of alfajores.env

# image: us-west1-docker.pkg.dev/devopsre/celo-blockchain-public/op-geth:celo-v2.0.0-rc3
if (test ! -f ../op-geth/build/bin/geth) then {
  cd ..
  git clone https://github.com/celo-org/op-geth.git
  cd  op-geth
  git checkout celo-v2.0.0-rc3
  make
  cd ../celo-l2-node-docker-compose
} fi;
echo $PATH | grep op-node > /dev/null
if (test "$?" != "0") then {
  cd ../op-geth
  export PATH="$PATH:$(pwd)/build/bin"
  cd ../celo-l2-node-docker-compose
} fi;

# volumes:
# - ./envs/${NETWORK_NAME}/config:/chainconfig
if (test ! -d /chainconfig) then {
  sudo mkdir /chainconfig
  sudo chown $(whoami):$(whoami) /chainconfig
  cp -rf envs/alfajores/config/* /chainconfing
} fi;
# - ./scripts/:/scripts
if (test ! -d /scripts) then {
  sudo mkdir /scripts
  sudo chown $(whoami):$(whoami) /scripts
  cp -rf scripts/* /scripts/
} fi;
# - shared:/shared
if (test ! -d /shared) then {
  sudo mkdir /shared
  sudo chown $(whoami):$(whoami) /shared
} fi;
# - ${DATADIR_PATH}:/geth alfajores.env includes DATADIR_PATH=./envs/${NETWORK_NAME}/datadir
if (test ! -d /geth) then {
  sudo mkdir /geth
  sudo chown $(whoami):$(whoami) /geth
} fi;

# env_file:
# - ./envs/${NETWORK_NAME}/op-geth.env
cat envs/alfajores/op-geth.env > .env
# - .env
cat alfajores.env >> .env

(source .env ; /scripts/start-op-geth.sh)


