allu_ver=$1
hadoop_ver=$2
[[ -z $allu_ver ]] && allu_ver=1.8.1
[[ -z $hadoop_ver ]] && hadoop_ver=2.9


# prepare
exist=`ls /usr/local/bin/jq | wc -l`
if [ ${exist} -ne 1 ]
then
  sudo wget https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64 -O /usr/local/bin/jq
else
  echo "Exist /usr/local/bin/jq"
fi
sudo chmod 755 /usr/local/bin/jq

is_master=`cat /mnt/var/lib/info/instance.json | jq -r '.isMaster'`
master_dns=`cat /mnt/var/lib/info/job-flow.json | jq -r '.masterPrivateDnsName'`

# get local ip address
ip_addr=`ifconfig | awk '/inet addr/{print substr($2,6)}' | head -1`
cd /opt

exist=`ls alluxio-${allu_ver}-hadoop-${hadoop_ver}-bin.tar.gz | wc -l`
if [ ${exist} -ne 1 ]
then
	sudo wget http://downloads.alluxio.org/downloads/files/${allu_ver}/alluxio-${allu_ver}-hadoop-${hadoop_ver}-bin.tar.gz
fi

if [ $? -ne 0 ]
then
  echo "Error: Check the Alluxio or Hadoop Version"
  exit -1
else
  echo "OK"
fi



sudo tar -zxf alluxio-${allu_ver}-hadoop-${hadoop_ver}-bin.tar.gz
sudo chown -R hadoop:hadoop alluxio-${allu_ver}-hadoop-${hadoop_ver}



# function to initialize alluxio config
initialize_alluxio () {
  cd alluxio-${allu_ver}-hadoop-${hadoop_ver}
  sudo chown -R hadoop:hadoop .

  cp conf/alluxio-site.properties.template conf/alluxio-site.properties
  echo "alluxio.master.security.impersonation.root.users=*" > ./conf/alluxio-site.properties
  echo "alluxio.master.security.impersonation.root.groups=*" >> ./conf/alluxio-site.properties
  echo "alluxio.master.security.impersonation.client.users=*" >> ./conf/alluxio-site.properties
  echo "alluxio.master.security.impersonation.client.groups=*" >> ./conf/alluxio-site.properties
  echo "alluxio.security.login.impersonation.username=none" >> ./conf/alluxio-site.properties
  echo "alluxio.security.authorization.permission.enabled=false" >> ./conf/alluxio-site.properties
  echo "alluxio.user.block.size.bytes.default=128MB" >> ./conf/alluxio-site.properties
  echo "alluxio.underfs.address=hdfs://${master_dns}:8020/alluxio" >> ./conf/alluxio-site.properties
  echo "alluxio.master.journal.folder=hdfs://${master_dns}:8020/alluxio/journal" >> ./conf/alluxio-site.properties
}




cd alluxio-${allu_ver}-hadoop-${hadoop_ver}
sudo cp ./conf/alluxio-site.properties.template ./conf/alluxio-site.properties

if [[ ${is_master} == "true" ]]; then
  # bootstrap
  master_dns=${ip_addr}
  sudo ./bin/alluxio bootstrapConf ${master_dns}
  hdfs dfs -mkdir /alluxio
  hdfs dfs -chown root:hadoop /alluxio

  initialize_alluxio
  # Format
  sudo ./bin/alluxio format
  # Start master
  sudo ./bin/alluxio-start.sh master

else
  # bootstrap
  sudo ./bin/alluxio bootstrapConf ${master_dns}

  initialize_alluxio

    # Format
  sudo ./bin/alluxio format
  # Start worker
  sudo ./bin/alluxio-start.sh worker Mount
fi
