#!/usr/bin/env python3
# coding=utf-8
#
# Copyright (c) 2021-2023 Huawei Device Co., Ltd.
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import argparse
import json
import logging
import os
import platform
import re
import shutil
import subprocess
import sys
import zipfile
from datetime import datetime

SUPPORT_BUILD_NAMES = ("clean", "config", "har", "compile", "zip", "zip2")
SUPPORT_BUILD_TYPES = ("debug", "profile", "release")
DIR_ROOT = os.path.abspath(os.path.join(sys.argv[0], os.pardir))
OS_NAME = platform.system().lower()
IS_WINDOWS = OS_NAME.startswith("win")
PATH_SEP = ";" if IS_WINDOWS else ":"
logging.basicConfig(
    format="%(levelname)s:%(asctime)s: %(message)s",
    datefmt="%Y-%d-%m %H:%M:%S",
    level=logging.DEBUG,
)


def safeGetPath(filePath, isDirectory=True):
    createPath = (
        filePath if isDirectory else os.path.abspath(os.path.join(filePath, os.pardir))
    )
    if not os.path.exists(createPath):
        os.makedirs(createPath)
    return os.path.abspath(filePath)


TIME_STR = datetime.now().strftime("%Y%m%d-%H%M")
DIR_OUTPUTS = safeGetPath(
    "%s/outputs/%s" % (DIR_ROOT, datetime.now().strftime("%Y%m%d"))
)
DIR_LOG = safeGetPath("%s/logs" % DIR_OUTPUTS)


class BuildInfo:
    def __init__(
        self,
        buildType="release",
        targetOS="ohos",
        targetArch="arm64",
        targetTriple="arm64-%s-ohos" % OS_NAME,
    ):
        self.buildType = buildType
        self.targetOS = targetOS
        self.targetArch = targetArch
        self.targetTriple = targetTriple

    def __repr__(self):
        return "BuildInfo(buildType=%s)" % (self.buildType)


# 执行命令
def runCommand(command, checkCode=True, timeout=None):
    logging.info("runCommand start, command = %s" % (command))
    code = subprocess.Popen(command, shell=True).wait(timeout)

    if code != 0:
        logging.error("runCommand error, code = %s, command = %s" % (code, command))
        if checkCode:
            exit(code)
    else:
        logging.info("runCommand finish, code = %s, command = %s" % (code, command))


def getOutput(buildInfo):
    buildType = buildInfo.buildType
    outputName = "%s_%s%s_%s" % (
        buildInfo.targetOS,
        buildType,
        "_unopt" if buildType == "debug" else "",
        buildInfo.targetArch,
    )
    return outputName


# 清理engine产物
def engineClean(buildInfo):
    target = os.path.join("src", "out", getOutput(buildInfo))
    logging.info("Remove directory %s" % target)
    if os.path.exists(target):
        shutil.rmtree(target, ignore_errors=True)


def findFile(path, search, results):
    if not os.path.exists(path):
        return
    for item in os.listdir(path):
        cur_path = os.path.join(path, item)
        if os.path.isdir(cur_path):
            if cur_path.endswith(search):
                results.append(os.path.abspath(cur_path))
            findFile(cur_path, search, results)


def findNativeInCurrentDir():
    os_dir = "mac" if OS_NAME == "darwin" else OS_NAME
    dirs = []
    findFile(os.path.join("ndk", os_dir), "native", dirs)
    return dirs[0] if len(dirs) != 0 else ""


def getNdkHome():
    OHOS_NDK_HOME = os.getenv("OHOS_NDK_HOME")
    if not OHOS_NDK_HOME:
        OHOS_NDK_HOME = findNativeInCurrentDir()
    if not OHOS_NDK_HOME:
        OHOS_SDK_HOME = os.getenv("OHOS_SDK_HOME")
        sdkInt = 0
        if ('openharmony' in os.getenv("HOS_SDK_HOME")):
            print('dddd')
            OHOS_SDK_HOME = "%s/openharmony" % os.getenv("HOS_SDK_HOME")
            if os.path.exists(OHOS_SDK_HOME):
                for dir in os.listdir(OHOS_SDK_HOME):
                    try:
                        tmpInt = int(dir)
                        sdkInt = max(sdkInt, tmpInt)
                    except:
                        logging.warning("Parse int error, dir=%s" % dir)
            if sdkInt == 0:
                logging.error(
                    "Ohos sdkInt parse failed, please config the correct environment variable."
                    " Such as: 'export OHOS_SDK_HOME=~/ohos/sdk/openharmony'."
                )
                exit(20)
            OHOS_NDK_HOME = os.path.join(OHOS_SDK_HOME, str(sdkInt), "native")
        else:
            print('go here')
            OHOS_NDK_HOME = "%s/HarmonyOS-NEXT-DP1/base/native" % os.getenv("HOS_SDK_HOME")
    logging.info("OHOS_NDK_HOME = %s" % OHOS_NDK_HOME)
    if (
        (not os.path.exists(OHOS_NDK_HOME))
        or (not os.path.exists(OHOS_NDK_HOME + "/sysroot"))
        or (not os.path.exists(OHOS_NDK_HOME + "/llvm/bin"))
        or (not os.path.exists(OHOS_NDK_HOME + "/build-tools/cmake/bin"))
    ):
        logging.error(
            """
    Please set the environment variables for HarmonyOS SDK to "HOS_SDK_HOME" or "OHOS_SDK_HOME".
    We will use both native/llvm and native/sysroot.
    Please ensure that the file "native/llvm/bin/clang" exists and is executable."""
        )
        exit(10)
    return OHOS_NDK_HOME


# 指定engine编译的配置参数
def engineConfig(buildInfo, extraParam=""):
    OHOS_NDK_HOME = getNdkHome()
    # export PATH=$OHOS_NDK_HOME/build-tools/cmake/bin:$OHOS_NDK_HOME/llvm/bin:$PATH
    lastPath = os.getenv("PATH")
    os.environ["PATH"] = (
        "%s%s" % (os.path.join(OHOS_NDK_HOME, "build-tools", "cmake", "bin"), PATH_SEP)
        + "%s%s" % (os.path.join(OHOS_NDK_HOME, "build-tools", "llvm", "bin"), PATH_SEP)
        + "%s%s" % (os.path.abspath("depot_tools"), PATH_SEP)
        + lastPath
    )
    unixCommand = ""
    if not IS_WINDOWS:
        unixCommand = (
            "--target-sysroot %s " % os.path.join(OHOS_NDK_HOME, "sysroot")
            + "--target-toolchain %s " % os.path.join(OHOS_NDK_HOME, "llvm")
            + "--target-triple %s " % buildInfo.targetTriple
        )
    OPT = "--unoptimized --no-lto " if buildInfo.buildType == "debug" else ""
    runCommand(
        "%s " % os.path.join("src", "flutter", "tools", "gn")
        + "--ohos "
        + "--ohos-cpu %s " % buildInfo.targetArch
        + "--runtime-mode %s " % buildInfo.buildType
        + OPT
        + unixCommand
        + "--no-goma "
        + "--no-prebuilt-dart-sdk "
        + "--embedder-for-target "
        + "--disable-desktop-embeddings "
        + "--no-build-embedder-examples "
        + "--verbose "
        + extraParam.replace("\\", ""),
        checkCode=False,
        timeout=600,
    )


# 执行engine编译操作
def engineCompile(buildInfo):
    runCommand("ninja -C %s" % os.path.join("src", "out", getOutput(buildInfo)))


# 替换文件中的字符串
def replaceStr(file, regex, newstr):
    with open(file, "r", encoding="utf-8") as f1:
        lines = f1.readlines()
    with open(file, "w+", encoding="utf-8") as f2:
        for line in lines:
            a = re.sub(regex, newstr, line)
            f2.writelines(a)


# 编译har文件
def harBuild(buildInfo):
    buildType = buildInfo.buildType
    isDebug = "true" if buildType == "debug" else "false"
    isProfile = "true" if buildType == "profile" else "false"
    dirEmbedding = os.path.abspath(
        "%s/src/flutter/shell/platform/ohos/flutter_embedding" % DIR_ROOT
    )
    targetFile = os.path.abspath(
        "%s/flutter/src/main/ets/embedding/engine/loader/FlutterApplicationInfo.ets"
        % dirEmbedding
    )
    logging.info("isDebugMode=%s, isProfile=%s" % (isDebug, isProfile))
    replaceStr(targetFile, "isDebugMode = .*", "isDebugMode = %s;" % isDebug)
    replaceStr(targetFile, "isProfile = .*", "isProfile = %s;" % isProfile)
    runCommand(
        ("cd %s && " % dirEmbedding)
        + (".%s" % os.sep)
        + "hvigorw --mode module -p module=flutter@default -p product=default assembleHar --no-daemon"
        + " && cd %s" % DIR_ROOT
    )
    fileSrc = os.path.abspath(
        "%s/flutter/build/default/outputs/default/flutter.har" % (dirEmbedding)
    )
    fileDest = safeGetPath(
        "%s/src/out/%s/ohos/flutter_embedding.har" % (DIR_ROOT, getOutput(buildInfo)),
        isDirectory=False,
    )
    shutil.copy(fileSrc, fileDest)
    logging.info(
        "Copy result is %s, from %s to %s"
        % (os.path.exists(fileDest), fileSrc, fileDest)
    )


def isPathValid(filepath, filename, includes, excludes):
    fileOrigin = filepath + os.path.sep + filename
    for regex in includes:
        if re.search(regex, fileOrigin):
            return True
    if includes != []:
        return False
    for regex in excludes:
        if re.search(regex, fileOrigin):
            return False
    return True


def zipFileDir(
    fileIn,
    fileName,
    prefixInZip="",
    includes=[],
    excludes=[],
    useZip2=False,
):
    logging.info(
        "fileIn= %s, fileName= %s, prefixInZip= %s, includes= %s, excludes= %s"
        % (fileIn, fileName, prefixInZip, includes, excludes)
    )
    fileOut1 = os.path.abspath("%s/%s.zip" % (DIR_OUTPUTS, fileName))
    fileOut2 = os.path.abspath("%s/%s-unstripped.zip" % (DIR_OUTPUTS, fileName))
    with zipfile.ZipFile(fileOut1, "w", zipfile.ZIP_DEFLATED) as zip1:
        with zipfile.ZipFile(fileOut2, "w", zipfile.ZIP_DEFLATED) as zip2:
            for path, dirnames, filenames in os.walk(fileIn):
                fpath = path.replace(fileIn, "")[1:]
                pPath = prefixInZip + os.sep + fpath
                for filename in filenames:
                    path1 = os.path.join(path, filename)
                    path2 = os.path.join(pPath, filename)
                    if isPathValid(fpath, filename, includes, excludes):
                        zip1.write(path1, path2)
                    elif useZip2:
                        zip2.write(path1, path2)

    if not useZip2:
        os.remove(fileOut2)


def zipFiles(buildInfo, useZip2=False):
    logging.info("zipFiles buildInfo=%s" % buildInfo)
    sdkVer = ''
    if ('openharmony' in getNdkHome()):
        sdkVer = getNdkHome()[-9:-7]
    else:
        sdkVer = getNdkHome()[-30:-12]
    outputName = getOutput(buildInfo)
    fileIn = os.path.abspath("%s/src/out/%s" % (DIR_ROOT, outputName))
    fileName = "ohos_api%s_%s-%s-%s-%s" % (
        sdkVer,
        buildInfo.buildType,
        OS_NAME,
        platform.machine(),
        TIME_STR,
    )
    prefixInZip = os.path.join("src", "out", outputName)
    excludes = ["obj", "exe.unstripped", "so.unstripped"]
    if IS_WINDOWS:
        excludes.extend([".*\.ilk", ".*\.pdb"])
    zipFileDir(fileIn, fileName, prefixInZip, excludes=excludes, useZip2=useZip2)


def addParseParam(parser):
    parser.add_argument(
        "-n",
        "--name",
        nargs="+",
        default=[],
        choices=SUPPORT_BUILD_NAMES,
        help="Provide build names.",
    )
    parser.add_argument(
        "-t",
        "--type",
        nargs="+",
        default=SUPPORT_BUILD_TYPES,
        choices=SUPPORT_BUILD_TYPES,
        help="Provide build types.",
    )
    parser.add_argument(
        "-b",
        "--branch",
        help="Git branch name in src/flutter to update.",
    )
    parser.add_argument(
        "-g",
        "--gn-extra-param",
        nargs="?",
        default="",
        help='Extra param to src/flutter/tools/gn. Such as: -g "\\--enable-unittests"',
    )


def updateCode(args):
    if args.branch:
        dir = os.path.join("src", "flutter")
        runCommand("git -C %s add -A" % dir)
        runCommand("git -C %s stash save 'Auto stash save.'" % dir)
        runCommand("git -C %s checkout %s" % (dir, args.branch))
        runCommand("git -C %s pull --rebase" % dir, checkCode=False)
        runCommand("python3 src/flutter/attachment/scripts/ohos_setup.py")


def checkEnvironment():
    if not os.path.exists("src/flutter"):
        logging.error(
            "You should place the current file 'ohos.py'"
            + " in the root directory of the 'engine' compilation."
        )
        exit(1)


def buildByNameAndType(args):
    buildNames = args.name if args.branch or args.name else ["config", "compile"]
    buildTypes = args.type
    for buildType in SUPPORT_BUILD_TYPES:
        if not buildType in buildTypes:
            continue
        buildInfo = BuildInfo(buildType=buildType)
        for buildName in SUPPORT_BUILD_NAMES:
            if not buildName in buildNames:
                continue
            if "clean" == buildName:
                engineClean(buildInfo)
            elif "config" == buildName:
                engineConfig(buildInfo, args.gn_extra_param)
            elif "har" == buildName:
                harBuild(buildInfo)
            elif "compile" == buildName:
                engineCompile(buildInfo)
            elif "zip" == buildName:
                zipFiles(buildInfo)
            elif "zip2" == buildName:
                zipFiles(buildInfo, True)
            else:
                logging.warning("Other name=%s" % buildName)


def ohos_main():
    parser = argparse.ArgumentParser()
    addParseParam(parser)
    args = parser.parse_args()
    checkEnvironment()
    updateCode(args)
    buildByNameAndType(args)
    logging.info("ohos_main() finish.")
    return 0


if __name__ == "__main__":
    exit(ohos_main())
