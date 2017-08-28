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
		-ju | --jenkins-user)
			sJenkinsUser="$2"
			shift
			;;
		-ja | --jenkins-api)
			sJenkinsAPI="$2"
			shift
			;;
		*)
			echo "build.sh bad option: "$2
			exit 1
			;;
	esac
shift
done

if [ "$bSkipTest" ==  "true" ]; then
    sBuildArg="-DskipTests=true"
fi

build_central_front () {
	echo "Build central front"
	cd central-js
	npm cache clean
	npm install
	bower install
	npm install grunt-contrib-imagemin
	grunt build
	cd dist
	npm install --production
	cd ..
	rm -rf /tmp/$sProject
	cd ..
	return
}

build_region_front () {
	echo "Build region front"
	cd dashboard-js
	npm install
	npm list grunt
	npm list grunt-google-cdn
	bower install
	npm install grunt-contrib-imagemin
	grunt build
	cd dist
	npm install --production
	cd ..
	rm -rf /tmp/$sProject
	cd ..
	return
}

build_base () {
	echo "Build all base modules"
	cd storage-static
	mvn -P $sVersion clean install $sBuildArg
	cd ..
	cd storage-temp
	mvn -P $sVersion clean install $sBuildArg
	cd ..
	cd wf-base
	mvn -P $sVersion clean install $sBuildDoc $sBuildArg -Ddependency.locations.enabled=false
	cd ..
}

build_central_back () {
	echo "Build central back"
	cd wf-central
	mvn -P $sVersion clean install $sBuildDoc $sBuildArg -Ddependency.locations.enabled=false
	rm -rf /tmp/$sProject
	cd ..
	return
}

build_region_back () {
	echo "Build region back"
	cd wf-region
	mvn -P $sVersion clean install $sBuildDoc $sBuildArg -Ddependency.locations.enabled=false
	rm -rf /tmp/$sProject
	cd ..
	return
}


if [ -d /tmp/$sProject ]; then
	rm -rf /tmp/$sProject
fi

mkdir /tmp/$sProject
export TMPDIR=/tmp/$sProject
export TEMP=/tmp/$sProject
export TMP=/tmp/$sProject


if [ $sProject == "base" ]; then
    build_base
fi

if [ $sProject == "wf-central" ]; then
	sleep 15
	if curl --silent --show-error http://$sJenkinsUser:$sJenkinsAPI@localhost:8080/job/alpha_Back/lastBuild/api/json | grep -q result\":null; then
		echo "Building of alpha_Back project is running. Compilation of wf-central will start automatically."
		exit 0
	else
		echo "Building of alpha_Back project is not running."
		build_central_back
	fi
fi

if [ $sProject == "wf-region" ]; then
	sleep 15
	if curl --silent --show-error http://$sJenkinsUser:$sJenkinsAPI@localhost:8080/job/alpha_Back/lastBuild/api/json | grep -q result\":null; then
		echo "Building of alpha_Back project is running. Compilation of wf-region will start automatically."
		exit 0
	else
		echo "Building of alpha_Back project is not running."
		build_region_back
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
	build_central_front
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
	build_region_front
fi

	echo "Compilation finished removing lock file"
	rm -f /tmp/$sProject/build.lock
