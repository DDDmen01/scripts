#!/bin/bash

export LANG=en_US.UTF-8
set -e

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
		-sd | --skip-deploy)
			bSkipDeploy="$2"
			shift
			;;
		-sb | --skip-build)
			bSkipBuild="$2"
			shift
			;;
		-st | --skip-test)
			bSkipTest="$2"
			shift
			;;
		-sdoc | --skip-doc)
			bSkipDoc="$2"
			shift
			;;
		--deploy-timeout)
			nSecondsWait="$2"
			shift
			;;
		--compile)
			IFS=',' read -r -a saCompile <<< "$2"
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
		-d | --docker)
			bDocker="$2"
			shift
			;;
		--dockerOnly)
			bDockerOnly="$2"
			shift
			;;
		-gc | --gitCommit)
			sGitCommit="$2"
			shift
			;;
		*)
			echo "main.sh bad option: "$sKey
			exit 1
			;;
	esac
shift
done

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

if [ "$bSkipBuild" == "false" ]; then
	echo "Starting build..."
	sh scripts/build.sh  --version $sVersion  --project $sProject --jenkins-user $sJenkinsUser --jenkins-api $sJenkinsAPI --skip-test $bSkipTest --skip-build $bSkipBuild --skip-doc $bSkipDoc
else
    echo "Build disabled. Going to the next step."
fi

if [ "$bSkipDeploy" == "false" ]; then
	echo "Starting deploy..."
	sh scripts/deploy_main.sh --version $sVersion  --project $sProject --jenkins-user $sJenkinsUser --jenkins-api $sJenkinsAPI
else
        echo "Deploy disabled. Going to the next step."
fi

if [ "$bDocker" == "true" ]; then
	echo "Starting deploy container..."
	python scripts/deploy_container.py --project $sProject --version $sVersion --gitCommit $sGitCommit
fi
