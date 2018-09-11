#!/bin/bash
set -e 
#
# Génère une clef et un certificat SSL auto-signé
#
# Constantes :
VERSION="0.0.1"
# Variables globales :
unset show
unset days
unset domain
unset country
unset state
unset locality
unset organization
unset organizationalUnit
unset commonName
unset email
unset password
#
# Exécute ou affiche une commande
# $1 : code de sortie en erreur
# $2 : commande à exécuter
run () {
  local code="${1}"
  local cmd="${2}"
  if [ -n "${show}" ] ; then
    echo "cmd: ${cmd}"
  else
    eval ${cmd}
  fi
  [ $? -ne 0 ] && {
    echo "Oops #################"
    exit ${code}
  }
  return 0
}
#
# Affichage d'erreur
# $1 : code de sortie
# $@ : message
echoerr () {
    local code="${1}"
    shift
    echo "$@" 1>&2
    usage ${code}
}
#
# Usage du shell :
# $1 : code de sortie
usage () {
  cat >&2 <<EOF
usage: `basename $0` [--help -h] | [--show -s] [--days=N, -dN] [domain]

    --help, -h  : prints this help and exits
    --show, -s  : do not execute commands, just list them
    --days, -d  : number of days to make a certificate valid for. Defaults to 30 days.
                   365 : one year
                  1825 : five years
                  3650 : ten years

    domain : common domain. Defaults to 'localhost' when no given
EOF
exit $1
}
#
# main
#
while [ $# -gt 0 ]; do
  case $1 in
  --help|-h)
    usage 0
    ;;
  --show|-s)
    show=true
    ;;
  --days=*)
    days="${1##--days=}"
    ;;
  -d*)
    days="${1##-d}"
    ;;
  *)
    if [ "z${domain}" = "z" ] ; then
        domain="${1}"
    fi
    ;;
  esac
  shift
done

[ ! -n "${days}" ] && {
    days=30
}
[ ! -n "${domain}" ] && {
    domain="localhost"
}

# Change to your details
country="FR"
state="France"
locality="Paris"
organization="localhost.localdomain"
organizationalUnit="IT"
commonName="${domain}"
email="admin@localhost.localdomain"
 
password="dummypassword"
 
# Generate a key :
echo "Generating private key for $domain"
cmdToExec="openssl genrsa -des3 -passout pass:${password} -out ${domain}.key 2048"
run 100 "${cmdToExec}"
 
# Remove passphrase from the key (usefull for service !) :
echo "Removing passphrase from key"
cmdToExec="cp ${domain}.key ${domain}.key.orig"
run 201 "${cmdToExec}"
cmdToExec="openssl rsa -in ${domain}.key.orig -passin pass:${password} -out ${domain}.key"
run 202 "${cmdToExec}"
cmdToExec="rm -f ${domain}.key.orig"
run 203 "${cmdToExec}"
 
# Create the request :
echo "Creating CSR (Certificate Signing Request)"
# No need to have in command now : -passin pass:${password}"
cmdToExec="openssl req -new -key ${domain}.key -out ${domain}.csr"
cmdToExec="${cmdToExec} -subj \"/emailAddress=${email}"
cmdToExec="${cmdToExec}/C=${country}"
cmdToExec="${cmdToExec}/ST=${state}"
cmdToExec="${cmdToExec}/L=${locality}"
cmdToExec="${cmdToExec}/O=${organization}"
cmdToExec="${cmdToExec}/OU=${organizationalUnit}"
cmdToExec="${cmdToExec}/CN=${commonName}\""
run 300 "${cmdToExec}"
 
# Create a self-signed certificate valid for the duration in days :
cmdToExec="openssl x509 -req -days ${days} -in ${domain}.csr -signkey ${domain}.key -out ${domain}.crt"
run 400 "${cmdToExec}"

printf "\n\n\
---------------------------\n\
-----Below is your Crt-----\n\
---------------------------\n\n\
"
cmdToExec="cat ${domain}.crt"
run 401 "${cmdToExec}"
 
printf "\n\n\
---------------------------\n\
-----Below is your Key-----\n\
---------------------------\n\n\
"
cmdToExec="cat ${domain}.key"
run 402 "${cmdToExec}"

exit 0

