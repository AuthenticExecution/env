SGX_IMAGE        = gianlu33/reactive-event-manager:latest
SANCUS_IMAGE     = gianlu33/reactive-uart2ip:latest
TRUSTZONE_IMAGE  = gianlu33/optee-deps:latest

SANCUS_EM       ?= $(shell realpath sancus/reactive.elf)
SGX_DEVICE      ?= /dev/isgx
AESM_CLIENT     ?= gianlu33/aesm-client:latest
TZ_VOLUME       ?= /opt/optee

UART_IP_DEV     ?= $(shell echo $(DEVICE) | perl -pe 's/(\d+)(?!.*\d+)/$$1+1/e')

event_manager_native: check_port
	docker run --rm --network=host -e EM_PORT=$(PORT) -e EM_LOG=info -e EM_THREADS=16 -e EM_PERIODIC_TASKS=false -e EM_SGX=false --name event-manager-$(PORT) $(SGX_IMAGE)

event_manager_sgx: check_port
	docker run --rm --network=host --device $(SGX_DEVICE) -v /var/run/aesmd/:/var/run/aesmd/ -e EM_PORT=$(PORT) -e EM_LOG=info -e EM_THREADS=16 -e EM_PERIODIC_TASKS=false -e EM_SGX=true --name event-manager-$(PORT) $(SGX_IMAGE)

event_manager_trustzone: check_port
	docker run --rm -it -v $(TZ_VOLUME):/opt/optee -e PORT=$(PORT) -p $(PORT):1236 --name event-manager-$(PORT) $(TRUSTZONE_IMAGE)

event_manager_sancus: check_port check_device
	docker run --rm -d -p $(PORT):$(PORT) --device=$(UART_IP_DEV) --name event-manager-$(PORT) $(SANCUS_IMAGE) reactive-uart2ip -p $(PORT) -d $(UART_IP_DEV)
	(cd /tmp && sancus-loader -device $(DEVICE) $(SANCUS_EM))
	screen -S sancus $(DEVICE) 57600
	docker stop event-manager-$(PORT) 2> /dev/null || true

clean:
	docker stop $(shell docker ps -q --filter name=event-manager-*) 2> /dev/null || true
	screen -X -S sancus quit > /dev/null 2> /dev/null || true

install:
	sudo cp REACTIVE-TOOLS /bin

check_port:
	@test $(PORT) || (echo "PORT variable not defined. Run make <target> PORT=<port>" && return 1)

check_device:
	@test $(DEVICE) || (echo "DEVICE variable not defined. Run make <target> DEVICE=<device>" && return 1)
