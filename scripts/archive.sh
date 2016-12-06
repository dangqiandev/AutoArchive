#!/bin/sh

# 只负责打当前包，不负责切换分支，拉取代码
#

help_info(){
	description="\n	sh archive.sh [-e][-c][-h]
\n	-e [environment][test|prerelease|release]
\n	-c [channel][enterprise|appstore]
\n 	-s [is use short name]
\n	-h [help]

\n	example:
\n	1、sh archive.sh -e test
\n 	2、sh archive.sh -e test -c enterprise"
    echo ${description} 
}

while getopts "e:c:hs" arg #选项后面的冒号表示该选项需要参数
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
		s)
			echo "s's arg:$OPTARG"
			isUseShortName=1
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
    channel=enterprise
fi

if [[ x${isUseShortName} == x ]]; then
	#statements
	isUseShortName=0
fi

# 环境
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


# 分支,需要把 “/” 去掉，否则造成命令错乱
branchNameOri=`git symbolic-ref --short -q HEAD`
branchName="${branchNameOri//\//}"

# 证书
KEY_release="iPhone Distribution: Shanghai 100 meters  Network Technology Co., Ltd. (4PE8GWH9XQ)"
KEY_enterprise="iPhone Distribution: Shanghai Yaya information technology co., LTD"
infoPath="./neighborhood/Support Files/neighborhood-Info.plist"


# 转义 infoPath 中的空格
#infoPathFormat="${infoPath// /\\ }"

# 版本号
version=`/usr/libexec/PlistBuddy -c "print :CFBundleShortVersionString" "${infoPath}"`
tembundleDisplayName=`/usr/libexec/PlistBuddy -c "print :CFBundleDisplayName" "${infoPath}"`

buildNumberInfo=`git log -a |wc -l | sed 's/^[ \t]*//g'`
buildNumber=`git log -1 --pretty=format:%h`_`git log -a |wc -l | sed 's/^[ \t]*//g'`

echo "version: ${version}"
echo "info.plist: ${infoPath}"
echo "tembundleDisplayName: ${tembundleDisplayName}"

# archive path
archivePath=build/DerivedData/neighborhood.xcarchive

#build_type=adhoc
configWay=Adhoc
configInfo=ADHOC=1
serverEnvironmentDefine=${serverEnvironment}=1
GCC_PREPROCESSOR_DEFINITIONS_Adhoc=(${serverEnvironmentDefine},${configInfo},"\$(inherited)")
echo "GCC_PREPROCESSOR_DEFINITIONS_Adhoc: ${GCC_PREPROCESSOR_DEFINITIONS_Adhoc}"


if [[ ${channel} == "enterprise" ]]; then
	#statements
	echo '企业证书 打包，重命名'
    developmentTeam="NM9VP4YSNU"
	productBundleIdentifier="com.mmbang.neighborhoodenterprise"
	if [[ ${tembundleDisplayName} != *-e ]]; then
		bundleDisplayName="${tembundleDisplayName}-e"
	else
		bundleDisplayName="${tembundleDisplayName}"
	fi
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

# dateStr=`date "+%Y%m%d_%H%M"`
# ddxq_ipaName=neighborhood_${branchName}_${version}_${buildNumber}_${build_type}_${dateStr}.ipa

echo "isUseShortName: " ${isUseShortName}
if [[ ${isUseShortName} == 1 ]]; then
	#statements
	# 缩短名称，名称规则：neighborhood_release6.0.0_6.0.0_test_adhoc_appstore，
	ddxq_ipaName="neighborhood_${branchName}_${version}_${environment}_${configWay}_${channel}.ipa"
else {
	ddxq_ipaName="neighborhood_${branchName}_${version}_${buildNumber}_${serverEnvironment}_${configInfo}_${profileName}.ipa"	
}
fi;

out_path=${PWD}/build
save_path=~/DDXQAutoArchive/ddxq/save/ios
upload_path=~/DDXQAutoArchive/ddxq/upload

make_dir() {
	if [ -d ${upload_path} ]; then echo "upload_path exit";else echo "make upload dir";mkdir -p ${upload_path}; fi;
	if [ -d ${out_path} ]; then echo "out_path exit";else echo "make build dir";mkdir -p ${out_path}; fi;
	if [ -d ${save_path} ]; then echo "save_path exit";else echo "make build dir";mkdir -p ${save_path}; fi;		
	echo "执行 makeDir"
}

make_dir

# 写入 log
if [ ! -f build/log.txt ]; then
	echo "API环境:${environment};\n分支:${branchName};\ntag:${tag};\n" > build/log.txt
	echo "最近10条日志"
	git log --pretty=format:"%h - %an, %aD : %s" -n 10 >> build/log.txt
fi

echo "branchName: ${branchName} buildNumber：${buildNumber} profileName：${profileName} configWay：${configWay}"
echo "configInfo: ${configInfo}"
echo "out_path : ${out_path}"
echo "ipaName : ${ddxq_ipaName}"
echo "bundleDisplayName : ${bundleDisplayName}"

rm -fr build/*.ipa
rm -fr buld/*.dSYM
rm -fr ${upload_path}/*
if [[ -f ${save_path}/${ddxq_ipaName} ]]; then
	#statements
	rm -fr ${save_path}/${ddxq_ipaName}
	rm -fr ${save_path}/${ddxq_ipaName}.dSYM
fi

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
xcodebuild -workspace neighborhood.xcworkspace -scheme neighborhood -configuration ${configWay} -derivedDataPath build/DerivedData -archivePath "${archivePath}" DEVELOPMENT_TEAM="${developmentTeam}" PRODUCT_BUNDLE_IDENTIFIER="${productBundleIdentifier}" CODE_SIGN_IDENTITY="${signKey}" PROVISIONING_PROFILE="${profileID}" PROVISIONING_PROFILE_SPECIFIER="${profileName}" IPHONEOS_DEPLOYMENT_TARGET="7.0" archive GCC_PREPROCESSOR_DEFINITIONS=${GCC_PREPROCESSOR_DEFINITIONS_Adhoc}

# PackageApplication is deprecated, use `xcodebuild -exportArchive` instead.
#xcrun -sdk iphoneos PackageApplication build/${configWay}-iphoneos/neighborhood.app -o ${out_path}/${ddxq_ipaName} --sign "${signKey}" --embed ProvisionProfile/mmbang_wildcard_can_push.mobileprovision
xcodebuild -exportArchive -exportFormat IPA -archivePath "${archivePath}" -exportPath ${out_path}/${ddxq_ipaName} -exportProvisioningProfile "${profileName}"

# move ipa file
cp -rf ${out_path}/${ddxq_ipaName} ${save_path}/${ddxq_ipaName}
cp -rf build/DerivedData/Build/Intermediates/ArchiveIntermediates/neighborhood/BuildProductsPath/${configWay}-iphoneos/neighborhood.app.dSYM ${save_path}/${ddxq_ipaName}.dSYM

cp -rf ${save_path}/${ddxq_ipaName} ${upload_path}/${ddxq_ipaName}
cp -rf ${save_path}/${ddxq_ipaName}.dSYM ${upload_path}/${ddxq_ipaName}.dSYM

fir publish ${upload_path}/${ddxq_ipaName} -T d9454fd7efa8f288e8f1ab27c8627d51 -c build/log.txt
