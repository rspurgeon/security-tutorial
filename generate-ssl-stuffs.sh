#!/bin/bash
PASSWORD=${PASSWORD:-abc123}
VALIDITY=${VALIDITY:-365}
FQDN=${FQDN:-$(hostname)}
CN=$FQDN
OU=${OU:-DevX}
O=${O:-Confluent}
L=${L:-Chicago}
S=${S:-Illinois}
C=${C:-US}
DN="CN=${CN},OU=${OU},O=${O},L=${L},S=${S},C=${C}"
SUBJ="/C=${C}/ST=${S}/L=${L}/O=${O}/OU=${OU}/CN=${CN}"

rm -f ca-*
rm -f cert-*
rm -f kafka.*.jks

keytool -keystore kafka.server.keystore.jks -alias $FQDN -validity $VALIDITY -genkey -ext SAN=DNS:$FQDN -storepass $PASSWORD -keypass $PASSWORD -dname $DN
openssl req -new -x509 -keyout ca-key -out ca-cert -days $VALIDITY -passin pass:$PASSWORD -passout pass:$PASSWORD -subj $SUBJ
keytool -keystore kafka.server.truststore.jks -alias CARoot -import -file ca-cert -ext SAN=DNS:$FQDN -keypass $PASSWORD -storepass $PASSWORD -noprompt
keytool -keystore kafka.client.truststore.jks -alias CARoot -import -file ca-cert -ext SAN=DNS:$FQDN -storepass $PASSWORD -keypass $PASSWORD -noprompt
keytool -keystore kafka.server.keystore.jks -alias $FQDN -certreq -file cert-file -ext SAN=DNS:$FQDN -keypass $PASSWORD -storepass $PASSWORD
openssl x509 -req -CA ca-cert -CAkey ca-key -in cert-file -out cert-signed -days $VALIDITY -CAcreateserial -passin pass:$PASSWORD
keytool -keystore kafka.server.keystore.jks -alias CARoot -import -file ca-cert -ext SAN=DNS:$FQDN -keypass $PASSWORD -storepass $PASSWORD -noprompt
keytool -keystore kafka.server.keystore.jks -alias $FQDN -import -file cert-signed -ext SAN=DNS:$FQDN -keypass $PASSWORD -storepass $PASSWORD
keytool -keystore kafka.client.keystore.jks -alias $FQDN -validity $VALIDITY -genkey -ext SAN=DNS:$FQDN -keypass $PASSWORD -storepass $PASSWORD -dname $DN
keytool -keystore kafka.client.keystore.jks -alias $FQDN -certreq -file cert-file -ext SAN=DNS:$FQDN -storepass $PASSWORD -keypass $PASSWORD
openssl x509 -req -CA ca-cert -CAkey ca-key -in cert-file -out cert-signed -days $VALIDITY -CAcreateserial -passin pass:$PASSWORD
keytool -keystore kafka.client.keystore.jks -alias CARoot -import -file ca-cert -ext SAN=DNS:$FQDN -keypass $PASSWORD -storepass $PASSWORD -noprompt
keytool -keystore kafka.client.keystore.jks -alias $FQDN -import -file cert-signed -ext SAN=DNS:$FQDN -storepass $PASSWORD
