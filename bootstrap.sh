allu_ver=$1
hadoop_ver=$2
[[ -z $allu_ver ]] && allu_ver=1.8.1
[[ -z $hadoop_ver ]] && hadoop_ver=2.9


# prepare
sudo wget https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64 -O /usr/local/bin/jq
sudo chmod 755 /usr/local/bin/jq

ismaster=`cat /mnt/var/lib/info/instance.json | jq -r '.isMaster'`
masterdns=`cat /mnt/var/lib/info/job-flow.json | jq -r '.masterPrivateDnsName'`

cd /opt

echo "Master web UI: " ${masterdns}

exit -1

sudo wget http://downloads.alluxio.org/downloads/files/${allu_ver}/alluxio-${allu_ver}-hadoop-${hadoop_ver}-bin.tar.gz
if [ $? -ne 0 ]
then
  echo "Error: Check the Alluxio or Hadoop Version"
  exit -1
else
  echo "OK"
fi

sudo tar -zxf alluxio-${allu_ver}-hadoop-${hadoop_ver}-bin.tar.gz
sudo chown -R hadoop:hadoop alluxio-${allu_ver}-hadoop-${hadoop_ver}


initialize_alluxio () {
  cd alluxio-${allu_ver}-hadoop-${hadoop_ver}
  sudo chown -R hadoop:hadoop .

  cp conf/alluxio-site.properties.template conf/alluxio-site.properties
  echo "alluxio.master.security.impersonation.root.users=*" >> ./conf/alluxio-site.properties
  echo "alluxio.master.security.impersonation.root.groups=*" >> ./conf/alluxio-site.properties
  echo "alluxio.master.security.impersonation.client.users=*" >> ./conf/alluxio-site.properties
  echo "alluxio.master.security.impersonation.client.groups=*" >> ./conf/alluxio-site.properties
  echo "alluxio.security.login.impersonation.username=none" >> ./conf/alluxio-site.properties
  echo "alluxio.security.authorization.permission.enabled=false" >> ./conf/alluxio-site.properties
  echo "alluxio.user.block.size.bytes.default=128MB" >> ./conf/alluxio-site.properties
}



cd alluxio-${allu_ver}-hadoop-${hadoop_ver}

if [[ ${ismaster} == "true" ]]; then
  # sudo cp ./conf/alluxio-site.properties.template ./conf/alluxio-site.properties
  # sudo echo "alluxio.master.hostname=localhost" >> ./conf/alluxio-site.properties
  # bootstrap
  sudo ./bin/alluxio bootstrapConf ${masterdns}

  # Add configure on alluxio-site.properties
  initialize_alluxio
  # Format
  sudo ./bin/alluxio format
  # Start master
  sudo ./bin/alluxio-start.sh master
  echo "Master web UI: ${masterdns}"

else
  # bootstrap
  sudo ./bin/alluxio bootstrapConf ${masterdns}

  # Add configure on alluxio-site.properties
  initialize_alluxio

  # Format
  sudo ./bin/alluxio format
  # Start worker
  sudo ./bin/alluxio-start.sh worker Mount
fi
