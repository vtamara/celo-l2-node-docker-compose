#/bin/sh
# Prepares binaries and environment and runs op-geth based on 
# section op-geth: of docker-composer.yml and variables of alfajores.env

# image: us-west1-docker.pkg.dev/devopsre/celo-blockchain-public/op-geth:celo-v2.0.0-rc3
git clone https://github.com/celo-org/op-geth.git
cd  op-geth
make

# volumes:
# - ./envs/${NETWORK_NAME}/config:/chainconfig
mkdir /chainconfig
cp -rf envs/alfajores/config/* /chainconfing
# - ./scripts/:/scripts
mkdir /scripts
cp -rf scripts/* /scripts/
# - shared:/shared
mkdir /shared
# - ${DATADIR_PATH}:/geth alfajores.env includes DATADIR_PATH=./envs/${NETWORK_NAME}/datadir
mkdir /geth

# env_file:
# - ./envs/${NETWORK_NAME}/op-geth.env
cp envs/alfajores/op-geth.env .env
# - .env



