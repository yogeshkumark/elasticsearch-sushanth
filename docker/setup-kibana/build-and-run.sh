
#!/usr/bin/env bash
# cat /home/hl/docker/setup-kibana/build-and-run.sh
set -v

# vars
NAME='hlog-kibana'
PORT='30001:5601'
HOST=$(hostname | cut -d. -f1)
NETWORK='elastic'
DEVE_DB='elasticsearch.hosts: "http://esdb:9200"'
TEST_DB='elasticsearch.hosts: "http://esdb:9200"'
PROD_DB='elasticsearch.hosts: ["http://kfdcel02.hlcl.com:9200", "http://kfdcel03.hlcl.com:9200", "http://kfdcel04.hlcl.com:9200", "http://kfdcel05.hlcl.com:9200"]'
CERT_CONF="req-deve.conf"

# building and running kibana
function setupKibana() {

  # generate fresh https certificates
  sed -i "s/ENVHOST/${HOST}/g" req.conf
  rm -f "${PWD}"/kibana.crt "${PWD}"/kibana.key > /dev/null 2>&1 || true
  openssl genrsa 4096 > "${PWD}"/kibana.key
  openssl req -new -x509 -nodes -sha256 -days 3650 -key "${PWD}"/kibana.key -out "${PWD}"/kibana.crt -config "${CERT_CONF}"
  chmod 400 "${PWD}"/kibana.key

  # add database depending on environment
  echo "${db}" >> kibana.yml

  # build Docker image
  docker build -t ${NAME} .
  docker rm -f ${NAME} > /dev/null 2>&1 || true
  docker network create ${NETWORK} > /dev/null 2>&1 || true
  docker run -d --name=${NAME} --network ${NETWORK} -p ${PORT} ${NAME}

  # remove artifacts
  rm -f "${PWD}"/kibana.key "${PWD}"/kibana.key

}

# update kibana.yml depending on env (DEVE|TEST|PROD)
[[ ${HOST} == 'kfdct069' ]] && db="${DEVE_DB}"
[[ ${HOST} == 'kfdct070' ]] && db="${TEST_DB}"
[[ ${HOST} == 'kfdcel01' ]] && db="${PROD_DB}"
setupKibana
[docker@kfdct069 ~]$
