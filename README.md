# env
Makefile &amp; docs to run basic AuthenticExecution components (reactive-tools, event managers, etc.)

## Prerequisites

- `Docker` is an essential requirement to run the event managers and the deployer tools.

### Sancus

- A Sancus board must be connected to the machine through UART
- The correct [Sancus image](sancus/sancus128.mcs) must be flashed in the board in advance
- How to close the `screen` session of the Sancus Event Manager: press `CTRL-A`, then `\`, then `y`
  - Do **not** stop the loading process of the EM with CTRL-C, otherwise the board would need a manual reset.

### SGX

- The machine in which the SGX Event Manager runs must support SGX, and the SGX driver and PSW must be installed, and the AESM service running
- EPID API keys for the attestation must be created and placed in a `settings.json` file. [More info](sgx/README.md)

### TrustZone

- Our modified OPTEE OS must be installed on the machine. [More info](trustzone/README.md)
- The docker container of the Event Manager prints on the same terminal both the outputs of the normal and the secure world. In addition, to stop the container one must enter the escape sequence `qqqq`
  - It is not possible to stop the container using CTRL-C

## Event managers

The Makefile contains targets to run the event managers of different types (SGX, native, Sancus, TrustZone)
- Essentially, each target runs a different Docker container.
- run `make event_manager_{sgx,native,sancus,trustzone}` to run the event manager of a specific type. Arguments:
  - `PORT=<port>` for all the targets, to specify the port the event manager listens to (e.g., `5000`)
  - `DEVICE=<device>` only for Sancus, to specify the UART device (e.g., `/dev/ttyUSB8`)
  - `TZ_VOLUME=<volume>` only for TrustZone, to specify the path of the OPTEE installation

## Attestation Manager

The Attestation Manager can be optionally integrated in an Authentic Execution deployment. It is a component (SGX or native) responsible for the attestation of all the other modules
  - If the AM is running, it can be used by specifying the flag `--manager` in a `reactive-tools` command

[More info](manager/README.md)

## Reactive-tools

The container for `reactive-tools` can be launched with `make reactive-tools`
  - Argument `VOLUME=<volume>` can be specified to change the volume mounted to the container (by the fault, the current working directory)
  - Alternatively, the `REACTIVE-TOOLS` script can be used to automatically run the container and execute the `reactive-tools` script. The current working directory is automatically mounted to the container. Usage:
  ```bash
  # install the script
  sudo cp exec/REACTIVE-TOOLS /bin

  # run reactive-tools directly (i.e., "hiding" the fact that a new container is launched)
  REACTIVE-TOOLS --verbose deploy <descriptor>
  ```

## Run demos

- Run a terminal for each event manager, plus an additional terminal for `reactive-tools`.

### Commands

```bash
### deploy a configuration ###
# Make sure you are under the project folder, and all the elements are on the same folder (JSON descriptor + modules)
REACTIVE-TOOLS --verbose deploy <in_descr> --result <out_descr>

# From now on, we will use the <out_descr> file generated during deployment.
# It will be updated automatically after each command

### attest the modules ###
REACTIVE-TOOLS --verbose attest <out_descr>

### create connections between the modules ###
REACTIVE-TOOLS --verbose connect <out_descr>

# Now the deployment is complete. We can call entry points, or trigger output or request events
# Of course according to the implementation of the modules and the deployment descriptor

### call an entry point ###
REACTIVE-TOOLS --verbose call <out_descr> --module <module> --entry <entry_name_or_id> [--arg <arg_hex>]

### trigger an `output` event ###
# only for `direct` connections
REACTIVE-TOOLS --verbose output <out_descr> --connection <conn_name_or_id> [--arg <arg_hex>]

### trigger a `request` event ###
# only for `direct` connections, and for supported modules (native or SGX)
REACTIVE-TOOLS --verbose request <out_descr> --connection <conn_name_or_id> [--arg <arg_hex>]
```
