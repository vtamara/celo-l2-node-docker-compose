#/bin/sh
# Prepares binaries and environment and runs op-geth based on 
# section op-geth: of docker-composer.yml and variables of alfajores.env

# image: us-west1-docker.pkg.dev/devopsre/celo-blockchain-public/op-geth:celo-v2.0.0-rc3
if (test ! -f ./op-geth/build/bin/geth) then {
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
if (test ! -d ./chainconfig) then {
  mkdir ./chainconfig
  cp -rf envs/alfajores/config/* ./chainconfig
} fi;
# - ./scripts/:/scripts
# - shared:/shared
if (test ! -d ./shared) then {
  mkdir ./shared
} fi;
# - ${DATADIR_PATH}:/geth alfajores.env includes DATADIR_PATH=./envs/${NETWORK_NAME}/datadir
if (test ! -d ./geth) then {
  mkdir ./geth
} fi;

# env_file:
# - ./envs/${NETWORK_NAME}/op-geth.env
sed -e "s/\/geth/.\/geth/g" envs/alfajores/op-geth.env > .env
# - .env
cat alfajores.env >> .env


env `grep "^[^#]" .env | tr  "\n" " "` PATH=$PATH scripts/start-op-geth-cwd.sh 
