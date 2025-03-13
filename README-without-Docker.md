# 1. Introduction

If you want to understand more about the L2 migration of CELO and how a node works on the testnets during the period of migration from L1 to L2, this tutorial might be for you.

This tutorial will help you test a CELO node with Alfajores or Baklava as L2, Holesky as L1 and without Docker. Keep in mind that the node you run will not be production ready because it has no metrics, no health check, and no historical data.

# 2. Concepts

A blockchain (like Bitcoin) is a public ledger where transaction history (states) are maintained in blocks, linking one block to the next with cryptographic functions to ensure their validity and security. The state includes the balance of each wallet/address and is public and available with a blockchain explorer.

In practice this allows for example Alice to send 5 coins from her wallet (using her private key) with balance 10 to Bob's wallet (knowing his public key/address) with initial balance 3, and that after the transaction, it will be verifiable that Alice's wallet ends up with 5 coins and Bob's wallet ends up with 8 coins minus transaction fees (assuming no one else interacted with Alice's and Bob's wallets), and the transaction will be visible with a blockchain explorer as well as their balances and transaction history.

In Ethereum and blockchains that work with Proof-of-Stake, the validity of the sequence of blocks and transactions is certified by several validators/computers that execute each transaction independently to ensure that they all obtain the same state. In addition, as described in the [Ethereum Yellow Paper](https://ethereum.github.io/yellowpaper/paper.pdf), as part of the Ethereum state, there are contracts/programs that can be called by transactions and are executed by the EVM (Ethereum Virtual Machine) every time a new state must be calculated and these programs can modify the state.  We find helpful the following diagram from [Armstrong](https://www.scss.tcd.ie/Donal.OMahony/bfg/202021/TCD-SCSS-FYP-2021-008.pdf)

![image](https://github.com/user-attachments/assets/cb68ec2d-1e83-4179-8862-9f4d04da6d61)

In practice, this allows Alice, for example, to interact with Uniswap contracts to invest part of her coins in a liquidity pool, and then to be able to withdraw her liquidity with interest.

The popularity of these tools has brought slow transactions and increased transaction costs. The op-stack is a proposal to solve these two problems with an optimistic rollup protocol and an open source software stack used by several blockchains (including CELO, Base, Optimism among others) to run their own blockchain with their own governance as quasi-ethereums (called L2s) but connected to Ethereum (called L1) to use its consesus mechanism and allowing cheaper and safer bridging between the L1 and the L2. According to [Optimism Docs](https://docs.optimism.io/stack/rollup/overview) any blockchain based on the op-stack includes these components:
* `op-geth` based on Ethereum's `geth` tool, which is the execution engine (EVM to calculate the state and make consensus between validators of the L2) but which runs independently of Ethereum at the speed of its validators and for exampl charging the fees/gas that its governance decides.
* `op-node`, the rollup node that sends blocks to `op-geth` and derives L2 (Celo) blocks from the L1 (Etherum).
* The sequencer that produces and executes L2 blocks and submits users transactions to L1 as blobs that are in a compressed format and directed to a non-contract address to minimize gas.

According to [The EigenDA Overview](https://docs.eigenda.xyz/overview) The EigenDA Proxy sits between the sequencer and Etherum distributing the storage of the blobs cryptographically among its own network of validators to reduce costs and to give faster availability of the L2's data to the L2, as the followin diagram from the same site shows.

![image](https://github.com/user-attachments/assets/a63fc92d-d65c-4ab9-888e-bb9b39bbf752)

The CELO blockchain as L2 uses EigenDA Proxy and uses a modified `op-geth` and a modified `op-node`. At the moment of this writing during the transition to L2, as described at [Overview of CELO L1 to Ethereum L2](https://docs.celo.org/cel2.html), the validators behave just like RPC nodes, `op-node` helps in the consesus of the validators and there is one sequencer, however the plan in the future is to implement the sequencer with a new consensus protocol between validators.

The modifications of `op-geth` consist of changes in 122 source files allowing:
* Token duality of CELO as native token and as ERC-20 Token
* Alternative fee currencies that are implemented specially in go with several modifications along the sources and also a small part as smartcontracts.

The modifications of `op-node` consist of changes to 220 source files that include:
* Migration of old data of L1 to L2
* Usage of alternative fee currencies


# 3. Our modification to the `celo-l2-node-docker-composer` repository

Of the 8 Docker components in the original `celo-l2-node-docker-compose` repository, we "undockerized" 3 in our branch:

| Docker component | Undockerized | Why |
|---|---|---|
| op-geth | Yes | L2 execution |
| op-node | Yes | L1 to L2 rollup and consensus |
| eigenda-proxy | Yes | Data availability store of L2 |
| healthcheck | No | Docker-specific, not needed for testing |
| prometheus | No | Metrics only, not needed for testing |
| grafana | No | Metrics only, not needed for testing |
| influxdb | No | Metrics only, not needed for testing |
| historical-rpc-node | No | Not needed for new nodes or testing |

We slightly modified some existing scripts of the [scripts directory](https://github.com/celo-org/celo-l2-node-docker-compose/tree/main/scripts) to have more generic main directory, binaries locations and host names and added 3 scripts to emulate the corresponding sections of `docker-compose.yml`: `scripts/prepare-and-run-op-geth.sh`, `scripts/prepare-and-run-op-node.sh`, `scripts/prepare-and-run-eigenda-proxy.sh`

In order to compile `op-node` in our platform we also ported the `just` tool to adJ/OpenBSD (see [PR 2497](https://github.com/casey/just/pull/2497) and [PR 2659](https://github.com/casey/just/pull/2659) ).

We also proposed 2 small pull requests (see [24](https://github.com/celo-org/celo-l2-node-docker-compose/pull/24) and [33](https://github.com/celo-org/celo-l2-node-docker-compose/pull/33)) for `celo-l2-node-docker` to make it more portable and that have been merged.


# 4. Requirements and initial setup

As the original repo explains the hardware requirements are:
* 16 GB+ RAM
* 500 GB SSD (NVME recommended)
* 100 MB/s+ Download

And for software:
* go 1.23,
* a shell (`zsh` and `bash` tested) and
* either some terminals or `tmux` with several panels (to run `op-geth`, `op-node` and maybe `htop`).

The following screenshots show two platforms we used for testing:

1. Ubuntu 20.04.6 on a Github CodeSpace with 2 terminals (although the reduced disk space doesn't allow a full synchronization in a codespace)
![image](https://github.com/user-attachments/assets/d9ba501c-adac-4fd2-9e0a-d69ae69b57b8)

2. Our main platform, OpenBSD/adJ 7.6 with `tmux`
![image](https://github.com/user-attachments/assets/c777ba12-7ed7-448c-8588-5273f002326b)

Clone the `outside-docker` branch from this repository:

```
git clone --branch outside-docker git@github.com:vtamara/celo-l2-node-docker-compose
cd celo-l2-node-docker-compose
```

And prepare the `.env` file either with:

```
cp alfajores.env .env
```

or

```
cp baklava.env .env
```
according with the testnet you want to use (alfajores for contracts and baklava for validators).

# 5. Prepare and run `op-geth`

Run the script
```
./scripts/prepare-and-run-op-geth.sh
```

This script will do the following:

1. If necessary, clone and compile `op-geth` into `$CELO_PATH` (`./` by default). The version it runs matches the one in `docker-compose.yml` which references an image on Google Cloud, by browsing that image you can see the tag or commit of the source in the repository.
2. In `$CELO_PATH` create the necessary directories (i.e. `chainconfig`, `scripts`, `shared`, and `geth`)
3. Prepare the environment variable stream using the `config/alfajores/op-geth.env` and `.env` files
4. Run `scripts/start-op-geth.sh` with `env` to pass the environment variable stream

After this, if you used the default `$CELO_PATH` as `./` your `celo-l2-node-docker-compose` directory will have several new directories and files, including:

```
$CELO_PATH
...
|-- chainconfig
| |-- genesis.json
| `-- rollup.json
...
|-- geth
| |-- geth
| | |-- LOCK
| | |-- chaindata
| | | |-- 000012.sst
...
| |-- geth.ipc
| `-- keystore
...
|-- op-geth
...
| |-- build
| | |-- bin
| | | `-- geth
...
`-- shared
|-- jwt.txt
`-- op-node_p2p_priv.txt
```

And the `op-geth` terminal will have a lot of messages trying to sync with other nodes running on Alfajores, one important message you should see to make sure everything is going well is:
```
...
INFO [02-13|04:01:42.257] Chain ID: 44787 (unknown)
```

Because 44787 is the Alfajores network ID.

# 6. Prepare and run `op-node`

Run the script
```
./scripts/prepare-and-run-op-node.sh
```

After that `$CELO_PATH` will have new directories including:

```
$CELO_PATH
...
|-- opnode_discovery_db
| |-- 000002.ldb
...
|-- opnode_peerstore_db
| |-- 000004.log
...
|-- optimism
...
| |-- op-node
...
| | |-- bin
| | | `-- op-node
...
```

And the abundant output will show that it is synchronizing.

# 7. Prepare and run `eigenda-proxy`

Run the script
```
./scripts/prepare-and-run-eigenda-proxy.sh
```

After `$CELO_PATH` will have new directories and files:

```
$CELO_PATH
...
|-- eigenda-data
|-- eigenda-proxy
...
| | |-- bin
| | | `-- eigenda-proxxy
```

# 8. Synchronization with testnet

We noticed that `op-node` doesn't require much memory but `op-geth` does, in fact, for us it stopped with a `fatal error: out of memory` error that we solved by running before `op-geth`:

```sh
ulimit -d 127000000
ulimit -s 10000
ulimit -l 120000
ulimit -m 12000000
```
In our tests we noticed that it required less than 5G of RAM.

The synchrontization requires both `op-geth` and `op-node` running and cooperating.   `op-geth` should start first but if it starts after `op-node` (or if it is stopped and restarted) they will wait for the other and continue.

During synchronization, `op-node` will log several messages like:

```
INFO [03-10|09:02:37.670] Received signed execution payload from p2p id=753c2e..412225:40656437 peer=16Uiu2HAmAko2Kr3eAjM7tnshtEhYrxQYfKUvN2kwiygeFoBAoi8S txs=1
INFO [03-10|09:02:37.670] Optimistically inserting unsafe L2 execution payload to drive EL sync id=753c2e..412225:40656437
```
followed by `op-geth` message with the same hash:
```
INFO [03-10|09:02:37.673] Forkchoice requested sync to new head    number=40,656,437 hash=753c2e..412225
```
and then again by `op-node` with the same hash:
```
INFO [03-10|09:02:37.674] Inserted new L2 unsafe block (synchronous) hash=753c2e..412225 number=40,656,437 newpayload_time=2.692ms   fcu2_time=1.053ms     total_time=3.746ms   mgas=0.044 mgasps=11.684
INFO [03-10|09:02:37.674] Sync progress                            reason="new chain head block" l2_finalized=000000..000000:0 l2_safe=000000..000000:0 l2_pending_safe=000000..000000:0 l2_unsafe=753c2e..412225:40656437 l2_backup_unsafe=000000..000000:0 l2_time=1,741,611,757
```

In the `op-geth` log you will see the percentage completed on messages like:
```
INFO [03-10|12:07:17.304] Syncing: chain download in progress      synced=5.10%  chain=1014.46MiB headers=2,118,027@763.07MiB bodies=2,076,121@51.49MiB receipts=2,076,121@199.90MiB eta=5h22m40.755s
...
INFO [03-10|12:07:23.016] Syncing: state download in progress      synced=85.02% state=4.48GiB    accounts=4,338,603@162.72MiB slots=17,019,849@3.60GiB  codes=87590@740.34MiB eta=3m0.488s
...
INFO [03-10|12:07:24.668] Syncing beacon headers                   downloaded=40,775,977 left=2,090,097  eta=3m9.168s
```

And then when it syncs fully, requiring more than 4 hours, new messages with a common hash will be produced, first by `op-node`:

```
INFO [03-10|11:42:50.894] Received signed execution payload from p2p id=8c2226..b8d887:40665562 peer=16Uiu2HAmQEdyLRSAVZDr5SqbJ1RnKmNDhtQJcEKmemrVxe4FxKwR txs=1
...
INFO [03-10|11:42:51.127] Optimistically queueing unsafe L2 execution payload id=8c2226..b8d887:40665562
```

Then by `op-geth`
```
INFO [03-10|11:43:00.745] Imported new potential chain segment     number=40,665,562 hash=8c2226..b8d887 blocks=1 txs=1 mgas=0.044 elapsed=4.706ms     mgasps=9.303  age=8m18s    snapdiffs=710.44KiB triediffs=1.47MiB triedirty=1.88MiB
INFO [03-10|11:43:00.746] Chain head was updated                   number=40,665,562 hash=8c2226..b8d887 root=dde12e..723922 elapsed="235.521µs" age=8m18s
```
And again by `op-node`
```
INFO [03-10|11:43:00.746] Inserted new L2 unsafe block (synchronous) hash=8c2226..b8d887 number=40,665,562 newpayload_time=6.186ms  fcu2_time=1.046ms     total_time=7.234ms  mgas=0.044 mgasps=6.052
INFO [03-10|11:43:00.746] Sync progress                            reason="new chain head block" l2_finalized=3b702b..23d252:40660848 l2_safe=5e8677..20b2b2:40664898 l2_pending_safe=5e8677..20b2b2:40664898 l2_unsafe=8c2226..b8d887:40665562 l2_backup_unsafe=000000..000000:0 l2_time=1,741,620,882
INFO [03-10|11:43:00.746] successfully processed payload           ref=8c2226..b8d887:40665562 txs=1
```

The log of `eigenda-proxy` is silent during synchronization.  After `op-node` sporadically log some requests to `eigenda-proxy`

```
INFO [03-10|11:48:25.526] Expiring commitment                      comm=010000f90197f853f842a02b7e0c84dcc14b349c8809207a0ba8d48ea40b019ecba0e1d343fbe80616cb6da003a6b73146238fab56d5fd86d9e2838d31148832b5c5e09d4800708981d4857a821000cbc480213710c50121378180f9013f83026f5f21f873eba05fd1cc4a6ea3844a6d0cbb39564d4ae748b67a9fe7c1ffc75a05022b1d949b8882000182515a8334e812a09e3744a94438ed022e0f6c2c1504b6856f7928ed86ffed3db358da58fd1438d0008334e863a04b84346a406213b552f8e038e163874e877fa8350f98b26c7ddc902d439f5003b8c00e570f55425816fb92b86d814d5016b823ffcfea9056e4d8663c0bf294b725af3283f08069c4684ae48695b477ca479ad9e79891dc098d6c81442d277d3886841eac1e68fd6be9fc1ea23d1ba07aefbf309ddff348f97719edd4d39e9f7217a2ebc1360bd650b98807fc8759b3c3b36bdb3beb05fd7b1fb511e5d667023cd4ea1c69b2089569f8b8746c630ca76d551ad3c42070242a10f0b64e3ad90ec8f9d94644e5245b26882a62e868cf113b25577887b92b1ab2b469d77ba48d01cc829c820001 commInclusionBlockNumber=3,467,372 origin=3d7b4c..d8dce7:3467373 challenged=false
...
INFO [03-10|11:48:49.213] getting input                            comm=010000f90197f853f842a00ee10d67d4a81fa96b37b608e4b6cca5d211aa3f7559d45937c5efe9d8f50e6fa02f04f3cf4bef3972e8f07ed26c26d730233abead512689e15b3c56d31a7dda4f821000cbc480213710c50121378180f9013f83026f7e1cf873eba0cf26c35dadc9699e08d25fb5b0fd2825857696e2b286b08a1178129d2369614282000182465a8334e908a019d28e0e5aade7f99b41a9e038daa87876b9a10cd53e4e35aa05476db3f37ebf008334e95da097980f0f59dde49db7b509ab81a7a8ad71d13eba5c95a7ae726aeec2bda6eb6eb8c09ce6c8d5715553355d4cc1a110754052b4f44f5c838c92a900cc21e299179131818a1c42946028d1f510882b054449b5680ce32f07ed4c5f174064053c022c050df49bafeae89fc73194c91eec70b99f7e5833c17d66d5cf7e648ce083e5dcc693d7dba57bcb28d770d7471f88c1375fb91567dacc06e860ebd060b23dd5bde81a284231adc5be4251053519affffaf6ed0f1cdb3cb13ec46d3eacd78aff968766f36e58a3d561f19e5c127d67027e4ade5b3a2d68a4b9cc36ff4e9d971c6829820001 status=0
```
that `eigenda-proxy` answers with:
```
Mar 10 11:48:49.213 INF server/handlers.go:103 Processing GET request commitment=f90197f853f842a00ee10d67d4a81fa96b37b608e4b6cca5d211aa3f7559d45937c5efe9d8f50e6fa02f04f3cf4bef3972e8f07ed26c26d730233abead512689e15b3c56d31a7dda4f821000cbc480213710c50121378180f9013f83026f7e1cf873eba0cf26c35dadc9699e08d25fb5b0fd2825857696e2b286b08a1178129d2369614282000182465a8334e908a019d28e0e5aade7f99b41a9e038daa87876b9a10cd53e4e35aa05476db3f37ebf008334e95da097980f0f59dde49db7b509ab81a7a8ad71d13eba5c95a7ae726aeec2bda6eb6eb8c09ce6c8d5715553355d4cc1a110754052b4f44f5c838c92a900cc21e299179131818a1c42946028d1f510882b054449b5680ce32f07ed4c5f174064053c022c050df49bafeae89fc73194c91eec70b99f7e5833c17d66d5cf7e648ce083e5dcc693d7dba57bcb28d770d7471f88c1375fb91567dacc06e860ebd060b23dd5bde81a284231adc5be4251053519affffaf6ed0f1cdb3cb13ec46d3eacd78aff968766f36e58a3d561f19e5c127d67027e4ade5b3a2d68a4b9cc36ff4e9d971c6829820001 commitmentMeta="{Mode:optimism_generic CertVersion:0}"
Mar 10 11:48:49.798 INF server/middleware.go:96 request method=GET url=/get/0x010000f90197f853f842a00ee10d67d4a81fa96b37b608e4b6cca5d211aa3f7559d45937c5efe9d8f50e6fa02f04f3cf4bef3972e8f07ed26c26d730233abead512689e15b3c56d31a7dda4f821000cbc480213710c50121378180f9013f83026f7e1cf873eba0cf26c35dadc9699e08d25fb5b0fd2825857696e2b286b08a1178129d2369614282000182465a8334e908a019d28e0e5aade7f99b41a9e038daa87876b9a10cd53e4e35aa05476db3f37ebf008334e95da097980f0f59dde49db7b509ab81a7a8ad71d13eba5c95a7ae726aeec2bda6eb6eb8c09ce6c8d5715553355d4cc1a110754052b4f44f5c838c92a900cc21e299179131818a1c42946028d1f510882b054449b5680ce32f07ed4c5f174064053c022c050df49bafeae89fc73194c91eec70b99f7e5833c17d66d5cf7e648ce083e5dcc693d7dba57bcb28d770d7471f88c1375fb91567dacc06e860ebd060b23dd5bde81a284231adc5be4251053519affffaf6ed0f1cdb3cb13ec46d3eacd78aff968766f36e58a3d561f19e5c127d67027e4ade5b3a2d68a4b9cc36ff4e9d971c6829820001 status=200 duration=585.135633ms
```

# 9. Running the regression tests from OpenBSD/adJ

## 9.1 op-geth

We run them from the `op-geth` source directory with `gmake test`. All 117 file tests passed, except for the following 9:
```
--- FAIL: TestWalletImportBadPassword (0.15 s)
--- FAIL: TestAccountNewBadRepeat (0.26 s)
--- FAIL: TestUnlockFlagAmbiguousWrongPassword (0.51 s)
--- FAIL: TestUnlockFlagPasswordFileWrongPassword (0.33 s)
--- FAIL: TestUnlockFlagWrongPassword (0.51 s)
--- FAIL: TestAccountImport (0.00 s)
--- FAIL: TestCustomBackend (3.00 s)
--- FAIL: TestIncompleteStateSync (0.31 s)
--- FAIL: TestExecutionSpecState (1.31 s)
```

We also compared by running the `eth-optimism/op-geth` and `ethereum/go-etehereum` tests:
* With `eth-optimism/op-geth`, all 121 file tests pass, but the following 5 fail:
    ```
    --- FAIL: TestWalletImportBadPassword (0.18 s)
    --- FAIL: TestAccountNewBadRepeat (0.17 s)
    --- FAIL: TestAccountImport (0.00 s)
    --- FAIL: TestCustomBackend (1.75 s)
    --- FAIL: TestIncompleteStateSync (0.23 s)
    ```
* With `ethereum/go-ethereum`, all 117 file tests pass, but the following 6 fail:
    ```
    --- FAIL: TestAccountNewBadRepeat (0.14s)
    --- FAIL: TestWalletImportBadPassword (0.11s)
    --- FAIL: TestAccountImport (0.00s)
    --- FAIL: TestCustomBackend (1.86s)
    --- FAIL: TestIncompleteStateSync (0.27s)
    --- FAIL: TestSimulatedBeaconSendWithdrawals (12.04s)
    ```

We already reported it in [go-etherum#30961](https://github.com/ethereum/go-ethereum/issues/30961) and are helping to resolve it.

## 9.2 op-node

We ran it from the `optimism/op-node` source directory with `/usr/local/bin/just test`. 1299 tests passed.

## 9.3 eigenda-proxy

We ran it from the `eigenda-proxy` source directory with `gmake test`. All the tests in six files passed, except for one that failed because it requires Docker:
```
panic: failed to start MinIO container: create container: unable to connect to Docker daemon at unix:///var/run/docker.sock. Is the Docker daemon running?
```

# 10. Conclusions

* We hope that, like us, you've learned a little more about CELO's new L2 infrastructure, based on Ethereum,  op-stack, eigenda-proxy, and CELO's unique modifications.
* Thanks to God, with minimal modifications and the help of some Celo blockchain developers on [Discord](https://discord.gg/celo) (particularly karlb and palango), we were able to test nodes and sync with the Alfajores and Baklava L2s:
  * Without Docker
  * On OpenBSD/adJ 7.6
  * With less than 5GB of RAM
  * With low CPU usage
  * With less than 50GB (mostly in the `geth` directory, which should correspond to the L2 state history).
    ![image](https://github.com/user-attachments/assets/6c6210a0-f7bf-4b85-bbd6-6b493b3ab2e5)
* In the process, we made some contributions:
  * We ported the `just` tool to adJ/OpenBSD (see [PR 2497](https://github.com/casey/just/pull/2497) and [PR 2659](https://github.com/casey/just/pull/2659) )
  * We slightly modified the <https://github.com/celo-org/celo-l2-node-docker-compose> repository on my [oustide-docker](https://github.com/vtamara/celo-l2-node-docker-compose/tree/outside-docker) branch to run without Docker.
  * We proposed 2 small pull requests for `celo-l2-node-docker` that have been merged:
    * https://github.com/celo-org/celo-l2-node-docker-compose/pull/24
    * https://github.com/celo-org/celo-l2-node-docker-compose/pull/33
* We found some issues with `op-geth` regression testing on OpenBSD/adJ that go back to the `go-ethereum` repository and plan to help resolve them.
