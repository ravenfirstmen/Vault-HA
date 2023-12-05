#!/bin/bash

CA_FILE_NAME="vault-ca"
DOMAIN="vault"
CA_CN="ca.${DOMAIN}"

# CA
if [ ! -f "${CA_FILE_NAME}-key.pem" ]
then
  openssl genrsa -out ${CA_FILE_NAME}-key.pem 4096
  openssl req -x509 -new -nodes -key ${CA_FILE_NAME}-key.pem -sha256 -days 1826 -out ${CA_FILE_NAME}.pem -subj "/CN=${CA_CN}/C=PT/ST=Braga/L=Famalicao/O=Casa"
fi


# Certificado
openssl genrsa -out ${DOMAIN}-key.pem 4096
openssl req -new -key ${DOMAIN}-key.pem -out ${DOMAIN}-cert.csr -subj "/CN=${DOMAIN}/C=PT/ST=Braga/L=Famalicao/O=Casa"

cat > ${DOMAIN}-cert.ext <<- EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names
[alt_names]
IP.1 = 127.0.0.1
DNS.1 = localhost
DNS.2 = ${DOMAIN}
DNS.3 = vault-0
EOF

openssl x509 -req -in ${DOMAIN}-cert.csr -CA ${CA_FILE_NAME}.pem -CAkey ${CA_FILE_NAME}-key.pem -CAcreateserial -out ${DOMAIN}-cert.pem -days 825 -sha256 -extfile ${DOMAIN}-cert.ext 
