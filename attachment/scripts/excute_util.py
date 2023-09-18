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
        # 逐行读取输出结果
        for line in proc.stdout:
            if line == b'' and proc.poll() is not None:
                break
            data = line.strip()
            if log:
                print(data)
            result += data
        error_output = proc.stderr.read().strip()
        if error_output:
            if log:
                print("错误输出:", error_output)
            err = True
        if err:
            result = '-1'
            if log:
                print("执行失败", proc.returncode)
        else:
            if log:
                print("执行成功")
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


def excuteArr(cmdArr, path="."):
    str = ' '.join(cmdArr)
    return excute(str, path)


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
