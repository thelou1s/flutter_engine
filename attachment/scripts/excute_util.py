# Copyright (c) 2023 Hunan OpenValley Digital Industry Development Co., Ltd.
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

#!/usr/bin/python
import subprocess
from datetime import datetime

# 执行字符串命令行


def excute(cmdStr, path=".", log=True):
    if path != "." and log:
        print("下个指令执行目录："+path)
    start_time = datetime.now()
    result = ""
    err = False
    if log:
        print("开始执行命令：{} ，开始时间：{}".format(cmdStr, getDateStr(start_time)))
    try:
        proc = subprocess.Popen(cmdStr, cwd=path, shell=True,
                                stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        out, err = proc.communicate()
        if proc.returncode != 0:
            result = '-1'
            if (log):
                print("Executing: %s failed. Exit code: %s" % (cmdStr, proc.returncode))

    except subprocess.CalledProcessError as e:
        if log:
            print("命令执行错误:", str(e))
        result = '-1'
    except Exception as e:
        if log:
            print("其他异常:", str(e))
        result = '-1'
     # 等待子进程结束
    proc.wait()
    end_time = datetime.now()
    if log:
        print("执行命令结束：{} ，结束时间：{} ，任务耗时: {}".format(
            cmdStr, getDateStr(end_time), end_time - start_time))
    return result

# 执行数组命令
def excuteArr(cmdArr, path=".", log = True):
    str = ' '.join(cmdArr)
    return excute(str, path, log)

def getDateStr(date):
    hour = date.hour
    minute = date.minute
    second = date.second
    return "{}时{}分{}秒".format(hour, minute, second)


# 测试代码
def testExcuteStr():
    cmdStr = "ls"
    excute(cmdStr, path="/")


def testExcuteArr():
    cmdArr = ["ping", "baidu.com"]
    excuteArr(cmdArr)

# testExcuteStr()
# testExcuteArr()
