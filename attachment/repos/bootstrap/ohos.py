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

SUPPORT_BUILD_NAMES = ("clean", "config", "har", "compile", "zip")
SUPPORT_BUILD_TYPES = ("debug", "profile", "release")
DIR_ROOT = os.path.abspath(os.path.join(sys.argv[0], os.pardir))
OS_NAME = platform.system().lower().replace("darwin", "mac")
PATH_SEP = ";" if "win" in OS_NAME else ":"
OHOS_SDK_HOME = os.getenv("OHOS_SDK_HOME")
if not OHOS_SDK_HOME:
    OHOS_SDK_HOME = "%s/openharmony" % os.getenv("HOS_SDK_HOME")

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
        targetTriple="aarch64-linux-ohos",
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


# 指定engine编译的配置参数
def engineConfig(buildInfo, extraParam=""):
    sdkInt = 9
    for dir in os.listdir(OHOS_SDK_HOME):
        try:
            tmpInt = int(dir)
            sdkInt = max(sdkInt, tmpInt)
        except:
            logging.warning("Parse int error, dir=%s" % dir)
    OHOS_NDK_HOME = os.path.join(OHOS_SDK_HOME, str(sdkInt), "native")
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
    Please ensure that the file "llvm/bin/lang" exists and is executable."""
        )
        exit(10)

    # export PATH=$OHOS_NDK_HOME/build-tools/cmake/bin:$OHOS_NDK_HOME/llvm/bin:$PATH
    lastPath = os.getenv("PATH")
    os.environ["PATH"] = (
        "%s%s" % (os.path.join(OHOS_NDK_HOME, "build-tools", "cmake", "bin"), PATH_SEP)
        + "%s%s" % (os.path.join(OHOS_NDK_HOME, "build-tools", "llvm", "bin"), PATH_SEP)
        + lastPath
    )

    OPT = "--unoptimized --no-lto " if buildInfo.buildType == "debug" else ""
    runCommand(
        "%s " % os.path.join("src", "flutter", "tools", "gn")
        + "--target-sysroot %s " % os.path.join(OHOS_NDK_HOME, "sysroot")
        + "--target-toolchain %s " % os.path.join(OHOS_NDK_HOME, "llvm")
        + "--target-triple %s " % buildInfo.targetTriple
        + "--ohos "
        + "--ohos-cpu %s " % buildInfo.targetArch
        + "--runtime-mode %s " % buildInfo.buildType
        + OPT
        + "--no-goma "
        + "--no-prebuilt-dart-sdk "
        + "--embedder-for-target "
        + "--disable-desktop-embeddings "
        + "--no-build-embedder-examples "
        + "--enable-unittests "
        + "--verbose "
        + extraParam,
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


def isPathValid(filepath, filename, includeDir, excludeDir):
    for dir in includeDir:
        if dir in filepath:
            return True
    if includeDir != []:
        return False
    for dir in excludeDir:
        if dir in filepath:
            return False
    return True


def zipFileDir(fileIn, fileName, prefixInZip="", includeDir=[], excludeDir=[]):
    logging.info(
        "fileIn= %s, fileName= %s, prefixInZip= %s, includeDir= %s, excludeDir= %s"
        % (fileIn, fileName, prefixInZip, includeDir, excludeDir)
    )
    fileOut1 = os.path.abspath("%s/%s.zip" % (DIR_OUTPUTS, fileName))
    fileOut2 = os.path.abspath("%s/%s-unstripped.zip" % (DIR_OUTPUTS, fileName))
    with zipfile.ZipFile(fileOut1, "w", zipfile.ZIP_DEFLATED) as zip1:
        with zipfile.ZipFile(fileOut2, "w", zipfile.ZIP_DEFLATED) as zip2:
            for path, dirnames, filenames in os.walk(fileIn):
                fpath = path.replace(fileIn, "")[1:]
                pPath = prefixInZip + os.sep + fpath
                for filename in filenames:
                    if isPathValid(fpath, filename, includeDir, excludeDir):
                        zip1.write(
                            os.path.join(path, filename), os.path.join(pPath, filename)
                        )
                    else:
                        zip2.write(
                            os.path.join(path, filename), os.path.join(pPath, filename)
                        )


def zipFiles(buildInfo):
    logging.info("zipFiles buildInfo=%s" % buildInfo)
    outputName = getOutput(buildInfo)
    fileIn = os.path.abspath("%s/src/out/%s" % (DIR_ROOT, outputName))
    fileName = "%s-%s-%s-%s" % (
        outputName,
        datetime.now().strftime("%H%M"),
        OS_NAME,
        platform.machine(),
    )
    prefixInZip = os.path.join("src", "out", outputName)
    dirArray = ["obj", "exe.unstripped", "so.unstripped"]
    zipFileDir(fileIn, fileName, prefixInZip, excludeDir=dirArray)


def stashChanges():
    dir_root = "src/flutter/attachment"
    config_file = "%s/scripts/config.json" % dir_root
    cache = []
    with open(config_file) as json_file:
        data = json.load(json_file)
        for task in data:
            dir = os.path.join(task["target"])
            if task["type"] == "patch" and not dir in cache:
                cache.append(dir)
                runCommand("git -C %s add -A" % dir)
                runCommand("git -C %s stash save 'Auto stash save'" % dir)


def addParseParam(parser):
    parser.add_argument(
        "-n",
        "--name",
        nargs="+",
        default=["config", "compile", "har"],
        choices=SUPPORT_BUILD_NAMES,
        help="Provide build names in %s." % str(SUPPORT_BUILD_NAMES),
    )
    parser.add_argument(
        "-t",
        "--type",
        nargs="+",
        default=SUPPORT_BUILD_TYPES,
        choices=SUPPORT_BUILD_TYPES,
        help="Provide build types in %s." % str(SUPPORT_BUILD_TYPES),
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
        help="Pass extra param to src/flutter/tools/gn.",
    )


def updateCode(args):
    if args.branch:
        stashChanges()
        dir = os.path.join("src", "flutter")
        runCommand("git -C %s add -A" % dir)
        runCommand("git -C %s stash save 'Auto stash save.'" % dir)
        runCommand("git -C %s checkout %s" % (dir, args.branch))
        runCommand("git -C %s pull --rebase" % dir)
        runCommand("git -C %s stash pop" % dir)
        runCommand("gclient sync --force")


def checkEnvironment():
    if not os.path.exists("src/flutter"):
        logging.error(
            "You should place the current file 'ohos.py'"
            + " in the root directory of the 'engine' compilation."
        )
        exit(1)


def buildByNameAndType(args):
    buildNames = args.name if not args.branch else []
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
            else:
                logging.warning("Other name=%s" % buildName)


def main():
    checkEnvironment()
    parser = argparse.ArgumentParser()
    addParseParam(parser)
    args = parser.parse_args()
    updateCode(args)
    buildByNameAndType(args)
    logging.info("main() finish.")
    return 0


exit(main())
