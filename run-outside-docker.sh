#/bin/sh
# Prepares binaries and environment to run op-geth based on 
# section op-geth: of docker-composer.yml and variables of alfajores.env

# image: us-west1-docker.pkg.dev/devopsre/celo-blockchain-public/op-geth:celo-v2.0.0-rc3
cd ..
git clone https://github.com/celo-org/op-geth.git
cd  op-geth
git checkout celo-v2.0.0-rc3
make
export PATH="$PATH:`pwd`/build/bin"
cd ../celo-l2-node-docker-compose/

# env_file:
# - ./envs/${NETWORK_NAME}/op-geth.env
cp envs/alfajores/op-geth.env .env
# - .env

# volumes:
# - ./envs/${NETWORK_NAME}/config:/chainconfig
sudo mkdir /chainconfig
sudo chown $(whoami):$(whoami) /chainconfig
cp -rf envs/alfajores/config/* /chainconfig/
# - ./scripts/:/scripts
sudo mkdir /scripts
sudo chown $(whoami):$(whoami) /scripts
cp -rf scripts/* /scripts/
# - shared:/shared
sudo mkdir /shared
sudo chown $(whoami):$(whoami) /shared
# - ${DATADIR_PATH}:/geth alfajores.env includes DATADIR_PATH=./envs/${NETWORK_NAME}/datadir
sudo mkdir /geth
sudo chown $(whoami):$(whoami) /geth

# entrypoint: /scripts/start-op-geth.sh
/scripts/start-op-geth.sh


