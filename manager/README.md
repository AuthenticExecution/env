# Attestation Manager

## Prerequisites for AM's attestation (only in SGX mode)

### Keys

To attest the AM, we need a specific keypair. The public key is embedded in the AM at compile time. The private key is used by the attester to decrypt sensitive information during the attestation process.

- under the `keys/` folder there are *sample* keypairs. The keys for the AM attestation are `manager_{privkey,pubkey}.pem`
- the key embedded in `gianlu33/attestation-manager:sgx` is `manager_pubkey.pem`
  - therefore, this docker image can only be used for testing purposes!

### Enclave signature

The attestation requires the signature of the AM enclave. It can be retrieved it from the `gianlu33/attestation-manager:sgx` image

- again, this is fine only for testing purposes!
- the signature is located under `/home/enclave/enclave.sig` and has to be placed under `manager/`
  - it can be retrieved automatically using `make get_manager_sig`

### settings.json configuration file

This is exactly the same as for the attestation of other SGX enclaves. [More info](../sgx/README.md)
- the file must be placed under `sgx/`

## Executables to install

The target `make install` installs `sgx-attester` and `attman-cli`

- The former is used to attest the AM
- The latter is used to communicate with the AM
  - the communication channel is protected with TLS-PSK, using the symmetric key established during the AM attestation
  - the TLS channel guarantees mutual attestation, because only the AM and the deployer know the attestation key

## SGX attestation of other modules

To attest SGX modules, we need to pass some data to the AM in advance.

The target `make init_manager` does the job using `attman-cli` under the hood
- We pass a keypair which is used in the same way as `manager_xxx.pem` (see [above](#keys))
  - the public key is embedded in the SGX modules
  - the private key is used to establish trust from an SGX module to the AM
- We also pass the IAS root certificate

## Run

All `make` commands should be run from the root of the repository.

```bash
# Run the Attestation Manager container in detached mode
### <tag>: between `native` (default) and `sgx`
### <port>: port exposed by the container (default: 1234)
make attestation_manager TAG=<tag> MANAGER_PORT=<port>

# Attest the AM (only in SGX mode, in native mode there is no actual attestation)
# this command updates `manager/config.yaml`
### <host>: host or IP address where the AM is running
### <port>: port the AM is listening to
make attest_manager MANAGER_HOST=<host> MANAGER_PORT=<port>

# Initialize SGX (only needed if we have SGX modules in our deployment)
# this target uses the `manager/init_sgx.yaml` file. Check above for more info
make init_manager

# Now the AM is up and running, waiting for commands.
```

## Integration in reactive-tools

### Deployment descriptor

The deployment descriptor should contain an additional `manager` section, used to specify the AM's information:

```json
"manager": {
  "host": "localhost",
  "port": 1234,
  "key": [1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16]
}
```

### Execute commands

All the relevant commands must be preceded by the `--manager` flag.

Example:

```bash
# the --manager flag in `deploy` is only needed if we deploy SGX modules
REACTIVE-TOOLS --verbose --manager deploy config.json --result res.json

# the --manager flag in `attest` is always required, otherwise the attestation is performed by the deployer
REACTIVE-TOOLS --verbose --manager attest res.json

# currently, the manager does not establish connections between modules. Hence the flag is useless in `connect`
REACTIVE-TOOLS --verbose --manager connect res.json
```
