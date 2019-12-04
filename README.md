# kubessl
An Alpine based docker image that includes Cloudflare's cfssl and Kubernetes' kubectl CLI tools. 
It also includes a few shell scripts that ease the task of:
1. Creating a PKI (Root CA, Intermediate CA and client/server/peer certificates);
2. Store the generated certificates as kubernetes TLS secrets.

# Documentation

To run the included scripts, you must provide a valid kubeconfig file, otherwise the scripts will fail to store the certificates as kubernetes secrets with the following error message:
```
The connection to the server localhost:8080 was refused - did you specify the right host or port?
```
If running inside a pod, you just have to run the script `genkubecfg`
to generate a kubeconfig file with the service account credentials.

If running locally, you can, for instance, mount your kubeconfig file inside the container. The local examples follow this approach.

## gencertca
```bash
$ gencertca -h
This script combines Cloudflare's cfssl CLI tool with kubectl to:
1. Generate a self-signed root CA certificate;
2. Store the resulting certificate as a kubernetes TLS secret.

Usage: gencertca [-f] [-h] [-n NAMESPACE] [-o PREFIX] [-r CSR] [-s SECRET]

Options:
    -f  Force the creation of the kubernetes secret (default is 'no').
        If this option is present and the secret already exists, it will be deleted first.
    -h  Prints this message and exits.
    -n  Kubernetes namespace where the resulting secret will be stored.
    -o  Name prefix for the resulting certificate files (default is 'ca').
        By default, it generates 3 files named: ca.pem, ca-key.pem and ca.csr
    -r  Path to the Certificate Signing Request (CSR) file.
    -s  Kubernetes secret name.
```
### gencertca command line example (local)
```bash
# Generates a Root CA certificate based on the CSR file found on example 
# directory and stores it in the kube-system namespace as a secret named 
# 'ca-tls'.
$ docker run -it --rm --user $(id -u):$(id -g) \
    -v $(pwd)/example:/mnt:Z \
    -v ${HOME}/.kube/config:/home/$(whoami)/.kube/config:Z \
    cjmach/kubessl gencertca \
        -r ca-csr.json \
        -n kube-system -s ca-tls
```

## gencertintca
```bash
$ gencertintca -h
This script combines Cloudflare's cfssl CLI tool with kubectl to:
1. Generate an intermediate CA certificate;
2. Store the resulting certificate as a kubernetes TLS secret.

Usage: gencertintca [-c CACERT] [-f] [-h] [-i CONFIG] [-k CAKEY] [-n NAMESPACE] [-o PREFIX] [-p PROFILE] [-r CSR] [-s SECRET]

Options:
    -c  Path to the CA certificate file.
    -f  Force the creation of the kubernetes secret (default is 'no').
        If this option is present and the secret already exists, it will be deleted first.
    -h  Prints this message and exits.
    -i  Path to the cfssl configuration file.
    -k  Path to the CA private key file.
    -n  Kubernetes namespace where the resulting secret will be stored.
    -o  Name prefix for the resulting certificate files (default is 'cert').
        By default, it generates 3 files named: cert.pem, cert-key.pem and cert.csr
    -r  Path to the Certificate Signing Request (CSR) file.
    -s  Kubernetes secret name.
```
### gencertintca command line example (local)
```bash
# Generates an Intermediate CA certificate based on files found on the 
# example directory and stores it in the kube-system namespace as a secret 
# named 'intca-tls'. It also requires a Root CA certificate to sign the
# intermediate CA.
$ docker run -it --rm --user $(id -u):$(id -g) \
    -v $(pwd)/example:/mnt:Z \
    -v ${HOME}/.kube/config:/home/$(whoami)/.kube/config:Z 
    cjmach/kubessl gencertintca \
        -c ca.pem -k ca-key.pem \
        -i intca-config.json -r intca-csr.json \
        -n kube-system -s intca-tls
```

## gencert
```bash
$ gencert -h
This script combines Cloudflare's cfssl CLI tool with kubectl to:
1. Generate a certificate signed by a Certificate Authority (CA);
2. Store the resulting certificate as a kubernetes TLS secret.

Usage: gencert [-c CACERT] [-f] [-h] [-i CONFIG] [-k CAKEY] [-n NAMESPACE] [-o PREFIX] [-p PROFILE] [-r CSR] [-s SECRET]

Options:
    -c  Path to the CA certificate file.
    -f  Force the creation of the kubernetes secret (default is 'no').
        If this option is present and the secret already exists, it will be deleted first.
    -h  Prints this message and exits.
    -i  Path to the cfssl configuration file.
    -k  Path to the CA private key file.
    -n  Kubernetes namespace where the resulting secret will be stored.
    -o  Name prefix for the resulting certificate files (default is 'cert').
        By default, it generates 3 files named: cert.pem, cert-key.pem and cert.csr
    -p  Profile to use to issue the certificate.
        The supported profiles are specified in the cfssl configuration file.
    -r  Path to the Certificate Signing Request (CSR) file.
    -s  Kubernetes secret name.
```
### gencert command line example (local)
```bash
# Generates a server certificate based on files found on the example 
# directory and stores it in the kube-system namespace as a secret 
# named 'server-tls'. It also requires an Intermediate CA certificate 
# to sign the server certificate.
$ docker run -it --rm --user $(id -u):$(id -g) \
    -v $(pwd)/example:/mnt:Z \
    -v ${HOME}/.kube/config:/home/$(whoami)/.kube/config:Z \
    cjmach/kubessl gencert \
        -c intca.pem -i ca-config.json \
        -k intca-key.pem -o server \
        -p server -r server-csr.json \
        -n kube-system -s server-tls
```
## genkubecfg
```bash
$ genkubecfg -h
Generates a default kubeconfig file, specially tailored for accessing a kubernetes cluster inside a pod.

Usage: genkubecfg [-a URL] [-b TOKEN] [-c CACERT] [-h]

Options:
    -a  The URL for the apiserver (default is 'https://kubernetes.default')
    -b  Path to the file containing the bearer token (default is '/var/run/secrets/kubernetes.io/serviceaccount/token').
    -c  Path to the CA certificate file (default is '/var/run/secrets/kubernetes.io/serviceaccount/ca.crt').
    -h  Prints this message and exits.
```

# License
The project is licensed under the Apache 2 license.