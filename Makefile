SGX_IMAGE           = authexec/event-manager-sgx:latest
SANCUS_IMAGE        = authexec/event-manager-sancus:latest
TRUSTZONE_IMAGE     = authexec/event-manager-trustzone:latest
AESM_CLIENT_IMAGE   = authexec/aesm-client:latest
MANAGER_IMAGE       = authexec/attestation-manager
ADMIN_IMAGE         = authexec/reactive-tools:latest

SGX_DEVICE         ?= /dev/isgx
OPTEE_DIR          ?= /opt/optee
SANCUS_ELF         ?= reactive.elf
UART_DEVICE        ?= $(shell echo $(DEVICE) | perl -pe 's/(\d+)(?!.*\d+)/$$1+1/e')
VOLUME             ?= $(shell pwd)

reactive_tools:
	docker run --rm --network=host -v $(VOLUME):/usr/src/app/ -v /usr/local/cargo/git:/usr/local/cargo/git -v /usr/local/cargo/registry:/usr/local/cargo/registry $(ADMIN_IMAGE)

event_manager_native: check_port
	docker run --rm --network=host -e EM_PORT=$(PORT) -e EM_LOG=info -e EM_THREADS=16 -e EM_PERIODIC_TASKS=false -e EM_SGX=false --name event-manager-$(PORT) $(SGX_IMAGE)

event_manager_sgx: check_port
	docker run --rm --network=host --device $(SGX_DEVICE) -v /var/run/aesmd/:/var/run/aesmd/ -e EM_PORT=$(PORT) -e EM_LOG=info -e EM_THREADS=16 -e EM_PERIODIC_TASKS=false -e EM_SGX=true --name event-manager-$(PORT) $(SGX_IMAGE)

event_manager_trustzone: check_port
	docker run --rm -v $(OPTEE_DIR):/opt/optee -e PORT=$(PORT) -p $(PORT):1236 --name event-manager-$(PORT) $(TRUSTZONE_IMAGE)

event_manager_sancus: check_port check_device
	docker run -it -p $(PORT):$(PORT) -e PORT=$(PORT) -e ELF=$(SANCUS_ELF) --device=$(DEVICE):/dev/RIOT --device=$(UART_DEVICE):/dev/UART --rm --name event-manager-$(PORT) $(SANCUS_IMAGE)

aesm_client:
	docker run --rm --detach --network=host -v /var/run/aesmd/:/var/run/aesmd --name aesm-client $(AESM_CLIENT_IMAGE) >/dev/null 2>&1 || true

pull_images:
	docker pull $(ADMIN_IMAGE)
	docker pull $(SGX_IMAGE)
	docker pull $(SANCUS_IMAGE)
	docker pull $(TRUSTZONE_IMAGE)
	docker pull $(AESM_CLIENT_IMAGE)
	docker pull $(MANAGER_IMAGE):sgx
	docker pull $(MANAGER_IMAGE):native

clean:
	docker stop $(shell docker ps -q --filter name=event-manager-*) 2> /dev/null || true

install:
	sudo cp REACTIVE-TOOLS /bin

check_port:
	@test $(PORT) || (echo "PORT variable not defined. This is the TCP/IP port the Event Manager listens on. Run make <target> PORT=<port>" && return 1)

check_device:
	@test $(DEVICE) || (echo "DEVICE variable not defined. Run make <target> DEVICE=<device>" && return 1)
