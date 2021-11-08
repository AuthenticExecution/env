# env
Makefile &amp; docs to run basic AuthenticExecution components (reactive-tools, event managers, etc.)

## Prerequisites

- `Docker` is an essential requirement to run the event managers and the deployer tools.

### Sancus

- A Sancus board must be connected to the machine through UART
- The correct [Sancus image](https://github.com/AuthenticExecution/event-manager-sancus) must be flashed in the board in advance ([tutorial](https://github.com/sancus-tee/sancus-main#xstools-installation)).
  - Currently, we only support the image with 128 bits of security.

### SGX

- SGX modules need a SGX-enabled machine and the AESM service up and running.
- For the attestation of an SGX module, two steps are needed:
  - Create a private key used to sign modules
  - Generate EPID API keys and place them in a `settings.json` file. 
  - [More info](sgx/README.md)

### TrustZone

- Our modified OPTEE OS must be installed on the machine. [More info](https://github.com/AuthenticExecution/event-manager-trustzone)

### Native

This is a "native" Event Manager running as a Linux process without TEE
protection. No requirements are needed.

## Getting started

Our [examples](https://github.com/AuthenticExecution/examples) are a good way to understand how the various components work together. Thanks to `docker` and `docker-compose`, it is very easy to deploy a new application locally.
  - There are also _native_ examples that can be run on a normal Linux machine without any TEEs involved.

## Components

### Event managers

The Makefile contains targets to run the event managers of different types (SGX, native, Sancus, TrustZone)
- Essentially, each target runs a different Docker container.
- run `make event_manager_{sgx,native,sancus,trustzone}` to run the event manager of a specific type. Arguments:
  - `PORT=<port>` for all the targets, to specify the port the event manager listens to (e.g., `5000`)
  - `DEVICE=<device>` only for Sancus, to specify the device used for loading the binary (e.g., `/dev/ttyUSB8`)
    - the device for the serial communication is by default the subsequent that the one specified, but it can be manually specified by setting the `UART_DEVICE` parameter.
  - `OPTEE_DIR=<volume>` only for TrustZone, to specify the path of the OPTEE installation

### Attestation Manager

The Attestation Manager is a component that can be optionally integrated in an Authentic Execution deployment. It is responsible for the attestation of all the other modules.

To see how it works, you can take a look at our [examples](https://github.com/AuthenticExecution/examples)

### Admin console (reactive-tools)

The container for `reactive-tools` can be launched with `make reactive-tools`
  - Argument `VOLUME=<volume>` can be specified to change the volume mounted to the container (by the fault, the current working directory)
  - Alternatively, the `REACTIVE-TOOLS` script can be used to automatically run the container and execute the `reactive-tools` script. The current working directory is automatically mounted to the container. Usage:
  ```bash
  # install the script
  sudo cp exec/REACTIVE-TOOLS /bin

  # run reactive-tools directly (i.e., "hiding" the fact that a new container is launched)
  REACTIVE-TOOLS --verbose deploy <descriptor>
  ```

## Run examples manually

- First, launch an Event Manager for each node of the application
  - according to the type of the node, run `make event_manager_{sgx,native,sancus,trustzone}`
- Second, launch a new terminal for the admin console (see below)

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
