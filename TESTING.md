### Starting a localnet with an external validator node

**Note**: Unless otherwise specified all commands are ran from the root of a
checkout of the harmony repo.

First we need to create a BLS key that will be used by our validator node. The
following command produces a key that will be assigned to shard 0. When the key
is assigned to shard 1 it doesn't seem to work for me. It's unclear why.

```bash
hmy keys save-bls-key 0x2a7441120df631549771776ab1e1347aaad3f64581e9b5ee1d58fd09d7fb0c73
```

Its public key is `4f41a37a3a8d0695dd6edcc58142c6b7d98e74da5c90e79b587b3b960b6a4f5e048e6d8b8a000d77a478d44cd640270c`.

Take note of the public key (here on referred as `<bls_pub>`). The private key
will be saved at the root of the repo as `<bls_pub>.key` encrypted with an
empty passphrase.

Then we need to add a line to the localnet configuration used by `make debug`
so that an external validator node is started as well as the internal ones. Add
the following line at the end of `test/configs/local-resharding.txt`:

```
127.0.0.1 9012 external  ./<bls_pub>.key
```

Now start your localnet with `make debug`.

The localnet configuration will spend its first two epochs in the
`FiveSecondEpoch` mode which gives a reward of 17.5 ONE tokens per block. Then
at epoch 2 it switches to `TwoSecondEpoch` mode which gives a reward of 7 ONE
tokens per block.

Run the following command and wait until the chain reaches epoch 2.

```bash
watch hmy blockchain latest-header
```

### Creating a validator ONE address and funding it

Each validator has one or more BLS keys (in our case just one) and one ONE
address. Generate a new ONE address for the validator to use like so:

```bash
hmy keys add validator
```

The validator address must be funded and Harmony's documentation recommends
that a validator needs at least 10001 ONE tokens. Let's give it 200000.

There is one account specified in the genesis block of the localnet that comes
prefunded with 10.000.000.000 (ten billion) ONE tokens. Load its private key
into your `hmy` keystore like so in order to get control of these funds:

```bash
hmy keys import-private-key 1f84c95ac16e6a50f08d44c7bde7aff8742212fda6e4321fde48bf83bef266dc genesis
```

Finally, let's transfer 200000 ONE tokens to our validator address.

```bash
hmy transfer \
    --from one155jp2y76nazx8uw5sa94fr0m4s5aj8e5xm6fu3 \
    --to <validator_addr> \
    --from-shard 0 \
    --to-shard 0 \
    --amount 200000
```

### Start the validation process

In order to start bidding stake and validate blocks we need to send a
`CreateValidator` transaction to the beacon shard that is signed by both the
BLS private key and the validator address private key. This is accomplished
with the following command:

```bash
hmy staking create-validator \
    --amount 100000 \
    --name foobar \
    --details foobar \
    --identity foobar \
    --security-contact foobar@example.com \
    --website example.com \
    --max-change-rate 0.1 \
    --max-rate 0.1 \
    --rate 0.1 \
    --max-total-delegation 100000000 \
    --min-self-delegation 100000 \
    --validator-addr <validator_addr> \
    --bls-pubkeys <bls_pub>
```

**Note:** When prompted for a BLS password just press enter, it's empty.

After this transaction goes through the validator node will notice it and
automatically start bidding and attempt to get elected. The following command
will eventually print the `<validator_addr>` selected above once an election
happens and the validator wins a bid. It usually takes a few seconds.

```bash
hmy blockchain validator elected | jq .result
```

### Inspecting rewards

At this point the validator node will be signing blocks and accumulating
rewards. In order to inspect the rewards collected by our validator we can use
either the `hmy blockchain validator information <addr>` command to get the
latest state or the `hmy blockchain validator information-by-block-number
<addr> <block>` to get the state at a particular point in time.

```bash
hmy blockchain validator information <validator_addr> | jq .result
```

**Note:** In order to use the point-in-time query
(`information-by-block-number`) you must manually set the target of the RPC
call to be the explorer node like so:

```bash
hmy --node localhost:9598 blockchain validator information <validator_addr> | jq .result
```

The response will look some like this:

```json
{
  "active-status": "inactive",
  "booted-status": null,
  "current-epoch-performance": {
    "block": 1620,
    "current-epoch-signing-percent": {
      "current-epoch-signed": 0,
      "current-epoch-signing-percentage": "0.000000000000000000",
      "current-epoch-to-sign": 0
    },
    "epoch": 163
  },
  "currently-in-committee": true,
  "epos-status": "currently elected",
  "epos-winning-stake": "10000000000000000000000.000000000000000000",
  "lifetime": {
    "apr": "0.000000000000000000",
    "blocks": {
      "signed": 879,
      "to-sign": 879
    },
    "epoch-apr": [
      {
        "apr": "0.000000000000000000",
        "epoch": 133
      }
    ],
    "epoch-blocks": [
      {
        "blocks": {
          "signed": 0,
          "to-sign": 0
        },
        "epoch": 133
      }
    ],
    "reward-accumulated": 6.153e+21
  },
  "metrics": {
    "by-bls-key": [
      {
        "earned-reward": 0,
        "key": {
          "bls-public-key": "4f41a37a3a8d0695dd6edcc58142c6b7d98e74da5c90e79b587b3b960b6a4f5e048e6d8b8a000d77a478d44cd640270c",
          "earning-account": "<validator_addr>",
          "effective-stake": "10000000000000000000000.000000000000000000",
          "group-percent": "1.000000000000000000",
          "overall-percent": "0.320000000000000002",
          "raw-stake": "10000000000000000000000.000000000000000000",
          "shard-id": 0
        }
      }
    ]
  },
  "total-delegation": 1e+22,
  "validator": {
    "address": "<validator_addr>",
    "bls-public-keys": [
      "4f41a37a3a8d0695dd6edcc58142c6b7d98e74da5c90e79b587b3b960b6a4f5e048e6d8b8a000d77a478d44cd640270c"
    ],
    "creation-height": 717,
    "delegations": [
      {
        "amount": 1e+22,
        "delegator-address": "<validator_addr>",
        "reward": 5.376e+21,
        "undelegations": []
      }
    ],
    "details": "foobar",
    "identity": "foobar",
    "last-epoch-in-committee": 163,
    "max-change-rate": "0.100000000000000000",
    "max-rate": "0.100000000000000000",
    "max-total-delegation": 1e+26,
    "min-self-delegation": 1e+22,
    "name": "foobar",
    "rate": "0.100000000000000000",
    "security-contact": "foobar@example.com",
    "update-height": 717,
    "website": "example.com"
  }
}
```

The most interesting field to inspect is the `"lifetime"` field which contains
information about how many blocks have been signed so far and the amount of
accumulated reward in the `"lifetime"."reward-accumulated"` field.

**Note**: It takes a couple of minutes before blocks start being signed (probably waiting for an epoch?).

In an unmodified harmony network it should be true that
`.result.lifetime.blocks.signed / .result.lifetime.reward-accumulated == 7`.

**Note**: Harmony produces JSON objects that contain raw big integer number
that when parsed by `jq` are converted to float64, losing precision. Use the
raw responses if you want to get precise numbers.

### Collecting rewards

The rewards seen with the method described above are not automatically transfer
to the delegators. In order to do so we can use the following command:

```bash
hmy staking collect-rewards --delegator-addr <validator_addr>
```

**Note**: The command line argument is about delegators because even the
address of the validator itself is considered a delegator. You can also see
that in the list of delegators in the information JSON object. Sincce it's the
only one then the funds are split between 1 address and it works out the same
as if it was handled specially.

This will move the currently accumulated rewards for that address to its wallet
and after it completes you should be able to observe a higher balance like so:

```bash
hmy balances <validator_addr>
```
