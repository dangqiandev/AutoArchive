#!/bin/sh

#	sh autoArchive.sh [-e [test|prerelease|release]]	[-b branchName]	[-t tagName]	[-c enterprise|appstore]
#	-e [environment][test|prerelease|release]
#	-b [branch][develop|feature/***|master]
#	-t [tag][5.6.2...]
#	-c [channel][enterprise|appstore]
#	-h [help]

#	test，prerelease，release：打包哪个环境。
#	branch：打包分支，default=develop
#	tag：	打包 tag
#	enterprise：	是否用企业证书。default 不使用
#	example:
# 	1、sh autoArchive.sh -e test -b develop -c enterprise
# 	2、sh autoArchive.sh -e test -b feature/https -c enterprise

help_info(){
	description="\n	sh autoArchive.sh [-e][-b][-t][-c]
\n	-e environment [test|prerelease|release]
\n	-b branch [develop|feature/***|master]
\n	-t tag [tagName:5.6.2  ...]
\n	-c channel [adhoc|enterprise|appstore]
\n	-h help

\n	example:
\n	1、sh autoArchive.sh -e test -b develop -c enterprise
\n 	2、sh autoArchive.sh -e test -b feature/https -c enterprise"
    echo ${description} 
}



while getopts "e:b:t:c:h" arg #选项后面的冒号表示该选项需要参数
do
    case $arg in
        e)
			echo "e's arg:$OPTARG" #参数存在$OPTARG中
			environment=$OPTARG
			;;
        b)
			echo "b's arg:$OPTARG"
			branch=$OPTARG
			;;
        c)
			echo "c's arg:$OPTARG"
			channel=$OPTARG
			;;
		t)
			echo "t's arg:$OPTARG"
			tag=$OPTARG
			;;
		h)
			echo "t's arg:$OPTARG"
			help_info
			exit 1
			;;
        ?)  #当有不认识的选项的时候arg为?
			echo "unkonw argument"
			exit 1
		;;
    esac
done

if [ x${branch} == x ]; then
    branch=develop
fi

if [ x${environment} == x ]; then
    environment=test
fi

if [ x${channel} == x ]; then
    channel=appstore
fi

#1、clone 代码
git_file_path=~/DDXQAutoArchive/ddxq/ios
if [ -d $git_file_path ]; then
	#statements
	echo "git文件夹存在！"
else
	echo "git文件夹不存在！"
	mkdir ${git_file_path}
	git clone git@git.ddxq.mobi:ddxq-app/ddxq-ios.git ${git_file_path}
fi

if [ ! -d $git_file_path ]; then
	#statements
	echo "git 拉取失败"
	exit 0
fi

#2 切换到 ios 目录
cd ${git_file_path}

#3. 重置
rm -fr ${git_file_path}/neighborhood/build/*
git reset --hard
git clean -fd

#4 当前 commit hash
#beforeCimmitHash=`git log --pretty=format:"%h" -1`

# 当前分支
currentBranch=`git symbolic-ref --short -q HEAD`

echo "当前分支：${currentBranch}"
if [[ x${branch} != x${currentBranch} ]]; then
	echo "切换分支"
	if [ x${tag} != x ]; then
	    # tag 不为空，从 tag 开一个分支出来
	    branch=tag/${tag}
	    git checkout -b ${branch} ${tag}
	else
		git checkout -b ${branch} origin/${branch}
	fi
fi

git pull

# 最新的 commit hash
afterCommitHash=`git log --pretty=format:"%h" -1`

if [[ ! -d neighborhood/build ]]; then
	#statements
	echo "创建 build 目录"
	mkdir neighborhood/build
fi

echo "----- afterCommitHash: ${afterCommitHash}"

#5 写入 log
echo "environment:${environment};\nbranch:${branch};\ntag:${tag};\n" > neighborhood/build/log.txt
if [ x != x${afterCommitHash} ]; then
	echo "最近10条日志"
	git log --pretty=format:"%h - %an, %ar : %s" -n 10 >> neighborhood/build/log.txt
else
	#git log ${afterCommitHash}..${beforeCimmitHash} --pretty=format:"%h - %an, %ar : %s" > neighborhood/build/log.txt
	"${git_file_path}:没有读取到日志，^_^" > neighborhood/build/log.txt
fi

echo "current hash log:"
git log --pretty=format:"%h - %an, %ar : %s" -n 1
echo "\n\n"

#6. Makefile 里面有用到相对目录，所以要切换到 Makefile 目录里面
cd ./neighborhood

# if [[ ${channel} == "enterprise" ]]; then
# 	#statements
# 	`sh ./scripts/archive.sh -e ${environment} -c ${channel}`
# else
# 	`sh ./scripts/archive.sh -e ${environment} -c ${channel}`
# fi

sh ./scripts/archive.sh -e ${environment} -c ${channel}

currentPath=`pwd`
if [[ "${git_file_path}/neighborhood" != "${currentPath}" ]]; then
	#statements
	echo "路径不对"
	exit 0
else
	echo "路径正确"
fi

# 重置
git reset --hard
git clean -fd
#7 删除 本地分支
if [ ${branch} != "master" ]; then
	#删除 本地分支
	git checkout master
	git branch -D ${branch}
fi
