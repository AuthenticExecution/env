# SGX vendor information

To run the demos with SGX nodes and modules, you need to provide:
  - A private key used to sign the modules
  - A configuration JSON file used during the Remote Attestation process, for the authentication with the Intel Attestation Server (IAS).

## Private key

- Generate the private key with `openssl` and store it in this folder
  - Example command: `openssl genrsa -3 3072 > private_key.pem`

## SGX Remote Attestation settings

[Remote Attestation SGX library](https://github.com/AuthenticExecution/rust-sgx-remote-attestation)

- Sign up for a Development Access account at https://api.portal.trustedservices.intel.com/EPID-attestation. Make sure that the Name Base Mode is Linkable Quote (this is all the framework supports now). Take note of "SPID", "Primary key", and "Secondary key".

- Copy the template provided here called `settings_template.json` to `settings.json` on this same folder.

- Replace the fields `spid`, `primary_subscription_key` and `secondary_subscription_key` with the values retrieved previously.

- Do **not** modify any other fields in the template.
