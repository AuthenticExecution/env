SGX_IMAGE           = gianlu33/reactive-event-manager:latest
SANCUS_IMAGE        = gianlu33/event-manager-sancus:latest
TRUSTZONE_IMAGE     = gianlu33/optee-deps:latest
AESM_CLIENT_IMAGE   = gianlu33/aesm-client:latest
MANAGER_IMAGE       = gianlu33/attestation-manager

SGX_DEVICE         ?= /dev/isgx
TZ_VOLUME          ?= /opt/optee
UART_IP_DEV        ?= $(shell echo $(DEVICE) | perl -pe 's/(\d+)(?!.*\d+)/$$1+1/e')

TAG                ?= native
MANAGER_HOST       ?= localhost
MANAGER_PORT       ?= 1234

ifeq ($(TAG), sgx)
	MANAGER_FLAGS = -v /var/run/aesmd/:/var/run/aesmd --device $(SGX_DEVICE)
else
	MANAGER_FLAGS =
endif

event_manager_native: check_port
	docker run --rm --network=host -e EM_PORT=$(PORT) -e EM_LOG=info -e EM_THREADS=16 -e EM_PERIODIC_TASKS=false -e EM_SGX=false --name event-manager-$(PORT) $(SGX_IMAGE)

event_manager_sgx: check_port
	docker run --rm --network=host --device $(SGX_DEVICE) -v /var/run/aesmd/:/var/run/aesmd/ -e EM_PORT=$(PORT) -e EM_LOG=info -e EM_THREADS=16 -e EM_PERIODIC_TASKS=false -e EM_SGX=true --name event-manager-$(PORT) $(SGX_IMAGE)

event_manager_trustzone: check_port
	docker run --rm -v $(TZ_VOLUME):/opt/optee -e PORT=$(PORT) -p $(PORT):1236 --name event-manager-$(PORT) $(TRUSTZONE_IMAGE)

event_manager_sancus: check_port check_device
	docker run -it -p $(PORT):$(PORT) -e PORT=$(PORT) -e DEVICE=$(DEVICE) --device=$(DEVICE) --device=$(UART_IP_DEV) --rm --name event-manager-$(PORT) $(SANCUS_IMAGE)

attestation_manager:
	docker run --rm --detach -p $(MANAGER_PORT):1234 $(MANAGER_FLAGS) --name attestation-manager $(MANAGER_IMAGE):$(TAG)

get_manager_sig:
	@docker run --rm -it --detach --name tmp_container $(MANAGER_IMAGE):sgx bash
	@docker cp tmp_container:/home/enclave/enclave.sig manager/enclave.sig
	@docker stop tmp_container

reset_manager:
	attman-cli --config manager/config.yaml --request reset

attest_manager:
	python3 manager/run_attester.py $(MANAGER_HOST) $(MANAGER_PORT)

init_manager:
	attman-cli --config manager/config.yaml --request init-sgx --data manager/init_sgx.yaml

stop_manager:
	docker stop attestation-manager

aesm_client:
	docker run --rm --detach --network=host -v /var/run/aesmd/:/var/run/aesmd --name aesm-client $(AESM_CLIENT) >/dev/null 2>&1 || true

clean:
	docker stop $(shell docker ps -q --filter name=event-manager-*) 2> /dev/null || true
	docker stop attestation-manager 2> /dev/null || true
	screen -X -S sancus quit > /dev/null 2> /dev/null || true

install:
	sudo cp exec/* /bin

check_port:
	@test $(PORT) || (echo "PORT variable not defined. This is the TCP/IP port the Event Manager listens on. Run make <target> PORT=<port>" && return 1)

check_device:
	@test $(DEVICE) || (echo "DEVICE variable not defined. Run make <target> DEVICE=<device>" && return 1)
