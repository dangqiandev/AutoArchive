#!/bin/sh

# 只负责打当前包，不负责切换分支，拉取代码
#

help_info(){
	description="\n	sh archive.sh [-e][-c][-h]
\n	-e [environment][test|prerelease|release]
\n	-c [channel][enterprise|appstore]
\n	-h [help]

\n	example:
\n	1、sh archive.sh -e test
\n 	2、sh archive.sh -e test -c enterprise"
    echo ${description} 
}

while getopts "e:c:h" arg #选项后面的冒号表示该选项需要参数
do
    case $arg in
        e)
			echo "e's arg:$OPTARG" #参数存在$OPTARG中
			environment=$OPTARG
			;;
        c)
			echo "c's arg:$OPTARG"
			channel=$OPTARG
			;;
		h)
			echo "h's arg:$OPTARG"
			help_info
			exit 1
			;;
        ?)  #当有不认识的选项的时候arg为?
			echo "unkonw argument"
			exit 0
		;;
    esac
done

if [ x${environment} == x ]; then
    environment=test
fi

if [ x${channel} == x ]; then
    channel=appstore
fi

# 切换目录,如果在 scrips 目录下执行，则 cd 到上一级目录
echo "当前目录："
pwd
echo

if [[ -f ./archive.sh ]]; then
	#statements
	cd ../
	echo "当前目录："
	pwd
	echo
fi


# 分支
branchNameOri=`git symbolic-ref --short -q HEAD`
branchName="${branchNameOri//\//_}"

KEY_release="iPhone Distribution: Shanghai 100 meters  Network Technology Co., Ltd. (4PE8GWH9XQ)"
KEY_enterprise="iPhone Distribution: Shanghai Yaya information technology co., LTD"
infoPath="./neighborhood/Support Files/neighborhood-Info.plist"


# 转义 infoPath 中的空格
#infoPathFormat="${infoPath// /\\ }"

version=`/usr/libexec/PlistBuddy -c "print :CFBundleShortVersionString" "${infoPath}"`
tembundleDisplayName=`/usr/libexec/PlistBuddy -c "print :CFBundleDisplayName" "${infoPath}"`

buildNumberInfo=`git log -a |wc -l | sed 's/^[ \t]*//g'`
buildNumber=`git log -1 --pretty=format:%h`_`git log -a |wc -l | sed 's/^[ \t]*//g'`

echo "version: ${version}"
echo "info.plist: ${infoPath}"

serverEnvironment=DDXQ_BUILD_FOR_TEST

# archive path
archivePath=build/DerivedData/neighborhood.xcarchive

configWay=Adhoc
configInfo=ADHOC=1

if [[ ${channel} == "enterprise" ]]; then
	#statements
	echo '企业证书 打包，重命名'
    developmentTeam="NM9VP4YSNU"
	productBundleIdentifier="com.mmbang.neighborhoodenterprise"
	bundleDisplayName="${tembundleDisplayName}-e"
	profileName=mmbang_wildcard_can_push
	#profileID=aa64f6e9-4156-45b3-ae33-718ca2b24593
	signKey=${KEY_enterprise}
else
	echo 'release 证书打包，不需要重命名'
	developmentTeam="4PE8GWH9XQ"
	productBundleIdentifier="com.mmbang.neighborhood"
	bundleDisplayName="${tembundleDisplayName}"
	profileName=100me_AdHoc_Profile_20141107
	#profileID=88756127-241b-47e2-a63f-8e87a93cc654
	signKey=${KEY_release}
fi

profileID=`/usr/libexec/PlistBuddy -c "Print UUID" /dev/stdin <<< $(/usr/bin/security cms -D -i "ProvisionProfile/${profileName}.mobileprovision")`
echo "profileUUID: ${profileID}"

if [ ${environment} == "test" ]; then
    serverEnvironment=DDXQ_BUILD_FOR_TEST 
elif [[ ${environment} == "prerelease" ]]; then
	#statements
	serverEnvironment=DDXQ_BUILD_FOR_PRERELEASE 
elif [[ ${environment} == "release" ]]; then
	#statements
	serverEnvironment=DDXQ_BUILD_FOR_RELEASE  
elif [[ ${environment} == "develop" ]]; then
	#statements
	serverEnvironment=DDXQ_BUILD_FOR_DEVELOP
else
	echo "未知 环境，退出"
	help_info
	exit;
fi

build_type=adhoc

dateStr=`date "+%Y%m%d_%H%M"`
out_path=${PWD}/build
# ddxq_ipaName=neighborhood_${branchName}_${version}_${buildNumber}_${build_type}_${dateStr}.ipa
ddxq_ipaName="neighborhood_${branchName}_${version}_${buildNumber}_${serverEnvironment}_${configInfo}_${profileName}.ipa"
save_path=~/DDXQAutoArchive/ddxq/save/ios
upload_path=~/DDXQAutoArchive/ddxq/upload

make_dir() {
	if [ -d ${upload_path} ]; then echo "upload_path exit";else echo "make upload dir";mkdir -p ${upload_path}; fi;
	if [ -d ${out_path} ]; then echo "out_path exit";else echo "make build dir";mkdir -p ${out_path}; fi;
	if [ -d ${save_path} ]; then echo "save_path exit";else echo "make build dir";mkdir -p ${save_path}; fi;		
	echo "执行 makeDir"
}

make_dir

echo "branchName: ${branchName} buildNumber：${buildNumber} profileName：${profileName} configWay：${configWay}"
echo "configInfo: ${configInfo}"
echo "out_path : ${out_path}"
echo "ipaName : ${ddxq_ipaName}"

#rm -fr "build/*"
rm -fr ${upload_path}/*

# 安装 profile
if [[ ! -f "~/Library/MobileDevice/Provisioning\ Profiles/${profileID}.mobileprovision" ]]; then
	#statements
	cp -Rf ProvisionProfile/${profileName}.mobileprovision ~/Library/MobileDevice/Provisioning\ Profiles/${profileID}.mobileprovision
fi


/usr/libexec/PlistBuddy -c "Set :CFBundleVersion ${buildNumberInfo}" "${infoPath}"
/usr/libexec/PlistBuddy -c "Set :CFBundleDisplayName ${bundleDisplayName}" "${infoPath}"

echo "执行 build"
# clean 
xcodebuild -workspace neighborhood.xcworkspace -scheme neighborhood -configuration ${configWay} clean
# build pods
xcodebuild -workspace neighborhood.xcworkspace -scheme Pods-neighborhood -derivedDataPath build/DerivedData OBJROOT=${PWD}/build SYMROOT=${PWD}/build -configuration ${configWay}
#xcodebuild -workspace neighborhood.xcworkspace -scheme neighborhood -derivedDataPath build/DerivedData OBJROOT=${PWD}/build SYMROOT=${PWD}/build -configuration ${configWay} PRODUCT_BUNDLE_IDENTIFIER="com.mmbang.neighborhoodenterprise" CODE_SIGN_IDENTITY="${signKey}" PROVISIONING_PROFILE="${profileName}" build GCC_PREPROCESSOR_DEFINITIONS='${GCC_PREPROCESSOR_DEFINITIONS} ${serverEnvironment} ${configInfo}'
#xcodebuild -workspace neighborhood.xcworkspace -scheme neighborhood -configuration ${configWay} -derivedDataPath build/DerivedData OBJROOT=${PWD}/build SYMROOT=${PWD}/build DEVELOPMENT_TEAM="${developmentTeam}" PRODUCT_BUNDLE_IDENTIFIER="${productBundleIdentifier}" CODE_SIGN_IDENTITY="${signKey}" PROVISIONING_PROFILE="${profileName}" PROVISIONING_PROFILE_SPECIFIER="mmbang_wildcard_can_push" IPHONEOS_DEPLOYMENT_TARGET="7.0" build GCC_PREPROCESSOR_DEFINITIONS='${GCC_PREPROCESSOR_DEFINITIONS} ${serverEnvironment} ${configInfo}'

# change to use archive
xcodebuild -workspace neighborhood.xcworkspace -scheme neighborhood -configuration ${configWay} -derivedDataPath build/DerivedData -archivePath "${archivePath}" DEVELOPMENT_TEAM="${developmentTeam}" PRODUCT_BUNDLE_IDENTIFIER="${productBundleIdentifier}" CODE_SIGN_IDENTITY="${signKey}" PROVISIONING_PROFILE="${profileID}" PROVISIONING_PROFILE_SPECIFIER="${profileName}" IPHONEOS_DEPLOYMENT_TARGET="7.0" archive GCC_PREPROCESSOR_DEFINITIONS='${GCC_PREPROCESSOR_DEFINITIONS} ${serverEnvironment} ${configInfo}'

# PackageApplication is deprecated, use `xcodebuild -exportArchive` instead.
#xcrun -sdk iphoneos PackageApplication build/${configWay}-iphoneos/neighborhood.app -o ${out_path}/${ddxq_ipaName} --sign "${signKey}" --embed ProvisionProfile/mmbang_wildcard_can_push.mobileprovision
xcodebuild -exportArchive -exportFormat IPA -archivePath "${archivePath}" -exportPath ${out_path}/${ddxq_ipaName} -exportProvisioningProfile "${profileName}"

# move ipa file
cp -rf ${out_path}/${ddxq_ipaName} ${save_path}/${ddxq_ipaName}
cp -rf build/DerivedData/Build/Intermediates/ArchiveIntermediates/neighborhood/BuildProductsPath/${configWay}-iphoneos/neighborhood.app.dSYM ${save_path}/${ddxq_ipaName}.dSYM

cp -rf ${save_path}/${ddxq_ipaName} ${upload_path}/${ddxq_ipaName}
cp -rf ${save_path}/${ddxq_ipaName}.dSYM ${upload_path}/${ddxq_ipaName}.dSYM

fir publish ${upload_path}/${ddxq_ipaName} -T d9454fd7efa8f288e8f1ab27c8627d51 -c build/log.txt
