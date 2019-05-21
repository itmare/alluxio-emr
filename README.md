Alluxio on EMR
==============

##### 1. bootstrap.sh로 각 서버(master/core)에 설치

##### 2. EMR configuration 추가

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

<br>

##### 3. alluxio 설치 경로: /opt/alluxio-1.x.x-hadoop-2.x

##### 4. Alluxio UI: <MASTER_PUBLIC_DNS>:19999
