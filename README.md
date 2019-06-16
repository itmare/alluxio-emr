Alluxio on EMR
==============

#### 1. bootstrap.sh로 각 서버(master/core)에 설치

#### 2. EMR configuration 추가

-	configurations으로 이동
-	filter에서 "cluster configurations" drop-down box 클릭  
-	master instance 선택  
-	"Reconfigure" 클릭  
-	Json 으로 다음 configure 추가 (table로도 추가 가능)

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
	          "spark.driver.extraClassPath": ":/usr/lib/hadoop-lzo/lib/*:/usr/lib/hadoop/hadoop-aws.jar:/usr/share/aws/aws-java-sdk/*:/usr/share/aws/emr/emrfs/conf:/usr/share/aws/emr/emrfs/lib/*:/usr/share/aws/emr/emrfs/auxlib/*:/usr/share/aws/emr/security/conf:/usr/share/aws/emr/security/lib/*:/opt/alluxio-1.8.1-hadoop-2.9/client/alluxio-1.8.1-client.jar",
	          "spark.executor.extraClassPath": ":/opt/alluxio-1.8.1-hadoop-2.9/client/alluxio-1.8.1-client.jar"
	     }
	  }
	]
	```

-	"Apply this configuration to all active instance groups" 체크

-	"Save changes" 클릭

-	cluster 자동으로 reconfiguring

#### 3. alluxio 설치 경로: /opt/alluxio-1.x.x-hadoop-2.x

#### 4. Alluxio UI: <MASTER_PUBLIC_DNS>:19999

<br><br>

```shell
# alluxio client는 hadoop client user가 foo인것을 발견하고, foo 유저 역할을 하는 allu 유저로써 서버와 연결한다.
# 이 impersonation을 통해서, data interaction은 foo유저로써 가능하게 된다.
# client-side hadoop impersonation을 위한 alluxio 설정은 client와 master configuration이 반드시 필요하다.
alluxio.master.security.impersonation.root.users=*
alluxio.master.security.impersonation.root.groups=*
alluxio.master.security.impersonation.client.users=*
alluxio.master.security.impersonation.client.groups=*
alluxio.security.login.impersonation.username=none
alluxio.security.authorization.permission.enabled=false


# alluxio.master.security.impersonation.alluxio_user.users=user1, user2
# => alluxio client user인 alluxio_uesr는 user1과 user2 역할을 하는 것을 허락한다.
```
