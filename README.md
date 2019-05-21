Alluxio on EMR
==============

-	bootstrap.sh로 각 서버(master/core)에 설치

```shell
#!/bin/bash

version=$1
[[ -z $version ]] && version=1.8.1

# prepare
sudo wget https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64 -O /usr/local/bin/jq
sudo chmod 755 /usr/local/bin/jq

ismaster=`cat /mnt/var/lib/info/instance.json | jq -r '.isMaster'`
masterdns=`cat /mnt/var/lib/info/job-flow.json | jq -r '.masterPrivateDnsName'`

cd /opt

# Download alluxio
sudo wget http://downloads.alluxio.org/downloads/files/${version}/alluxio-${version}-hadoop-2.8-bin.tar.gz
sudo tar -zxf alluxio-${version}-hadoop-2.8-bin.tar.gz
sudo chown -R hadoop:hadoop alluxio-${version}-hadoop-2.8


initialize_alluxio () {
  cd alluxio-${version}-hadoop-2.8
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

cd alluxio-${version}-hadoop-2.8

if [[ ${ismaster} == "true" ]]; then
  # sudo cp ./conf/alluxio-site.properties.template ./conf/alluxio-site.properties
  # sudo echo "alluxio.master.hostname=localhost" >> ./conf/alluxio-site.properties
  # bootstrap
  sudo ./bin/alluxio bootstrapConf ${masterdns}

  initialize_alluxio
  # Format
  sudo ./bin/alluxio format
  # Start master
  sudo ./bin/alluxio-start.sh master

else
  # bootstrap
  sudo ./bin/alluxio bootstrapConf ${masterdns}

  initialize_alluxio

    # Format
  sudo ./bin/alluxio format
  # Start worker
  sudo ./bin/alluxio-start.sh worker Mount
fi
```

-	EMR configuration 추가

	1.	Go to configurations
	2.	filter에서 "cluster configurations" drop-down box 클릭
	3.	master instance 선택
	4.	"Reconfigure" 클릭
	5.	Json 으로 다음 configure 추가 (table로도 추가 가능)

		```json
		[
		  {
		    "Classification": "core-site",
		    "Properties": {
		      "fs.alluxio.impl": "alluxio.hadoop.FileSystem",
		      "fs.AbstractFileSystem.alluxio.impl": "alluxio.hadoop.AlluxioFileSystem"
		    }
		  },
		  {
		    "Classification": "spark-defaults",
		    "Properties": {
		          "spark.driver.extraClassPath": ":/usr/lib/hadoop-lzo/lib/*:/usr/lib/hadoop/hadoop-aws.jar:/usr/share/aws/aws-java-sdk/*:/usr/share/aws/emr/emrfs/conf:/usr/share/aws/emr/emrfs/lib/*:/usr/share/aws/emr/emrfs/auxlib/*:/usr/share/aws/emr/security/conf:/usr/share/aws/emr/security/lib/*:/opt/alluxio-1.8.1-hadoop-2.8/client/alluxio-1.8.1-client.jar",
		          "spark.executor.extraClassPath": ":/opt/alluxio-1.8.1-hadoop-2.8/client/alluxio-1.8.1-client.jar"
		     }
		  }
		]
		```

	6.	"Apply this configuration to all active instance groups" 체크

	7.	"Save changes" 클릭

	8.	cluster 자동으로 reconfiguring

-	alluxio 설치 경로: /opt/alluxio-1.x.x-hadoop-2.x

-	Alluxio UI: <MASTER_PUBLIC_DNS>:19999
