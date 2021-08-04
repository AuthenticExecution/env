import subprocess
import sys
import yaml

ATTESTER = "sgx-attester"

enclave_host = sys.argv[1] if len(sys.argv) > 1 else "localhost"
enclave_port = sys.argv[2] if len(sys.argv) > 2 else "1234"

def attest():
    env = {
        "AESM_PORT" : "13741",
        "ENCLAVE_HOST" : enclave_host,
        "ENCLAVE_PORT" : enclave_port,
        "SP_PRIVKEY" : "manager/keys/manager_privkey.pem",
        "ENCLAVE_SIG" : "manager/enclave.sig",
        "IAS_CERT" : "sgx/ias_root_ca.pem",
        "ENCLAVE_SETTINGS" : "sgx/settings.json",
    }

    try:
        res = subprocess.run([ATTESTER], env=env, stdout=subprocess.PIPE)
        res.check_returncode()
    except Exception as e:
        print(e)
        sys.exit(1)

    return eval(res.stdout)


def update_config(key):
    conf = {
        "host": enclave_host,
        "port": int(enclave_port),
        "key": key
    }

    with open("manager/config.yaml", "w") as f:
        yaml.dump(conf, f)


if __name__ == "__main__":
    key = attest()
    update_config(key)
