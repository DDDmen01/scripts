#!/bin/bash

export LANG=en_US.UTF-8
set -e
sDate=`date "+%Y.%m.%d-%H.%M.%S"`

while [[ $# > 1 ]]
do
	sKey="$1"
	case $sKey in
		-v | --version)
			sVersion="$2"
			shift
			;;
		-p | --project)
			sProject="$2"
			shift
			;;
		-dt | --deploy-timeout)
			nSecondsWait="$2"
			shift
			;;
		-ju | --jenkins-user)
			sJenkinsUser="$2"
			shift
			;;
		-ja | --jenkins-api)
			sJenkinsAPI="$2"
			shift
			;;
		*)
			echo "deploy_main.sh bad option: "$2
			exit 1
			;;
	esac
shift
done

deploy_central_front () {
	echo "Deploy central front to host: $sHost"
	cd central-js
	rsync -az --delete -e 'ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no' dist/ sybase@$sHost:/sybase/.upload/central-js/
	return
}

deploy_region_front () {
	echo "Deploy region front to host: $sHost"
	cd dashboard-js
	rsync -az --delete -e 'ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no' dist/ sybase@$sHost:/sybase/.upload/dashboard-js/
	return
}

deploy_central_back () {
	echo "Deploy central back"
	cd wf-central
	if [ ! -f target/wf-central.war ]; then
		echo "File not found! Need to rebuild application..."
		exit 1
	fi
	rsync -az -e 'ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no' target/wf-central.war sybase@$sHost:/sybase/.upload/
	return
}

deploy_region_back () {
	echo "Deploy region back"
	cd wf-region
	if [ ! -f target/wf-region.war ]; then
		echo "File not found! Need to rebuild application..."
		exit 1
	fi
	rsync -az -e 'ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no' target/wf-region.war sybase@$sHost:/sybase/.upload/
	return
}

if [ -z $nSecondsWait ]; then
	nSecondsWait=185
fi
if [ -z $sJenkinsUser ]; then
	echo "Please provide Jenkins access credentials!"
	exit 1
fi
if [ -z $sJenkinsAPI ]; then
	echo "Please provide Jenkins access credentials!"
	exit 1
fi
if curl --silent --show-error http://$sJenkinsUser:$sJenkinsAPI@localhost:8080/ | grep "HTTP ERROR"; then
	echo "Failed to connect to Jenkins with current credentials!"
	exit 1
fi

#Определяем сервер для установки
if [[ $sVersion == "alpha" && $sProject == "central-js" ]] || [[ $sVersion == "alpha" && $sProject == "wf-central" ]]; then
		sHost="test.igov.org.ua"
		export PATH=/usr/local/bin:$PATH
fi
if [[ $sVersion == "beta" && $sProject == "central-js" ]] || [[ $sVersion == "beta" && $sProject == "wf-central" ]]; then
		sHost="test-version.igov.org.ua"
		export PATH=/usr/local/bin:$PATH
fi
#if [[ $sVersion == "prod" && $sProject == "central-js" ]] || [[ $sVersion == "alpha" && $sProject == "wf-central" ]]; then
#		sHost="igov.org.ua"
#fi

if [[ $sVersion == "alpha" && $sProject == "dashboard-js" ]] || [[ $sVersion == "alpha" && $sProject == "wf-region" ]]; then
		sHost="test.region.igov.org.ua"
		export PATH=/usr/local/bin:$PATH
fi
if [[ $sVersion == "beta" && $sProject == "dashboard-js" ]] || [[ $sVersion == "beta" && $sProject == "wf-region" ]]; then
		sHost="test-version.region.igov.org.ua"
		export PATH=/usr/local/bin:$PATH
fi
#if [[ $sVersion == "prod" && $sProject == "dashboard-js" ]] || [[ $sVersion == "alpha" && $sProject == "wf-region" ]]; then
#		sHost="region.igov.org.ua"
#fi
if [ $sVersion == "delta" ]; then
	sHost="none"
fi
if [ $sVersion == "omega" ]; then
	sHost="none"
fi

if [ -z $sHost ]; then
	echo "Cloud not select host for deploy. Wrong version or project."
	exit 1
else
	echo "Host $sHost will be a target server for deploy...."
fi

if [[ $sProject ]]; then
	if [ -d /tmp/$sProject ]; then
		rm -rf /tmp/$sProject
	fi
	mkdir /tmp/$sProject
	export TMPDIR=/tmp/$sProject
	export TEMP=/tmp/$sProject
	export TMP=/tmp/$sProject
fi

if [ $sProject == "wf-central" ]; then
	sleep 15
	if curl --silent --show-error http://$sJenkinsUser:$sJenkinsAPI@localhost:8080/job/alpha_Back/lastBuild/api/json | grep -q result\":null; then
		echo "Building of alpha_Back project is running. Compilation of wf-central will start automatically."
		exit 0
	else
		echo "Building of alpha_Back project is not running."
		deploy_central_back
	fi
fi

if [ $sProject == "wf-region" ]; then
	sleep 15
	if curl --silent --show-error http://$sJenkinsUser:$sJenkinsAPI@localhost:8080/job/alpha_Back/lastBuild/api/json | grep -q result\":null; then
		echo "Building of alpha_Back project is running. Compilation of wf-region will start automatically."
		exit 0
	else
		echo "Building of alpha_Back project is not running."
		deploy_region_back
	fi
fi

if [ $sProject == "central-js" ]; then
	touch /tmp/$sProject/build.lock
	if [ -f /tmp/dashboard-js/build.lock ]; then
		if ps ax | grep -v grep | grep -q dashboard-js; then
			while [ -f /tmp/dashboard-js/build.lock ]; do
				if ps ax | grep -v grep | grep -q dashboard-js; then
					sleep 10
					echo "dashboard-js compilation is still running. we will wait until it finish."
				else
					break
				fi
			done
		else
			echo "dashboard-js compilation script is not running but lock file exist. removing lock file and starting compilation"
			rm -f /tmp/dashboard-js/build.lock
		fi
	fi
	deploy_central_front
fi

if [ $sProject == "dashboard-js" ]; then
	sleep 10
	touch /tmp/$sProject/build.lock
	if [ -f /tmp/central-js/build.lock ]; then
		if ps ax | grep -v grep | grep -q central-js; then
			while [ -f /tmp/central-js/build.lock ]; do
				if ps ax | grep -v grep | grep -q central-js; then
					sleep 10
					echo "central-js compilation is still running. we will wait until it finish."
				else
					break
				fi
			done
		else
			echo "central-js compilation script is not running but lock file exist. removing lock file and starting compilation"
			rm -f /tmp/central-js/build.lock
		fi
	fi
	deploy_region_front
fi

echo "Compilation finished removing lock file"
rm -f /tmp/$sProject/build.lock
	

echo "Connecting to remote host $sHost"
cd $WORKSPACE
rsync -az -e 'ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no' scripts/deploy_remote.sh sybase@$sHost:/sybase/
ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no $sHost << EOF
chmod +x /sybase/deploy_remote.sh
/sybase/deploy_remote.sh $sProject $sDate $nSecondsWait $sVersion
EOF
