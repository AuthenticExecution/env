# Build and Run TrustZone Event Manager

## Build OP-TEE for QEMUv7

This has to be done on the host OS. The root of the OP-TEE installation will then mounted as a volume on the container.

- First, follow the first two steps [here](https://optee.readthedocs.io/en/latest/building/gits/build.html#get-and-build-the-solution)

```bash
# create a root folder
mkdir optee
cd optee

# get the repositories
repo init -u https://github.com/AuthenticExecution/optee_os.git -m manifest.xml
repo sync -j4 --no-clone-bundle

# get the event manager and put under `optee_examples`
git clone https://github.com/sepidehpouyan/Authentic-Execution.git
cp -r Authentic-Execution/Event optee_examples/

# build OPTEE
cd build
make -j2 toolchains
make -j `nproc`
```

## Run a OPTEE instance using Docker

```bash
### <volume>: absolute path of the root folder created in the previous phase (default: /opt/optee)
make event_manager_trustzone PORT=<port> TZ_VOLUME=<volume>
```

The container automatically runs the Event Manager at startup.
