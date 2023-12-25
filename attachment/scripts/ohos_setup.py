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
import sys
import json
import file_util
import sub_process_with_timeout
import os

"""
在gclient中hook中配置执行
职责如下：
1.解析config.json
2.拷贝repos下文件，覆盖执行路径目录
3.修改DEPS,忽视dart、angle、skia的同步
"""

ROOT = './src/flutter/attachment'
REPOS_ROOT = ROOT + '/repos'

def apply_patch(task, log=False):
    file_path = task['file_path']
    target_path = task['target']
    retcode,stdout,stderr = sub_process_with_timeout.excuteArr(
        ['git', 'apply', '--ignore-whitespace', '--whitespace=nowarn', file_path], target_path, log, timeout=20)
    if retcode == 0 and log:
        print("Apply succeded. file path:" + file_path)
    if log:
        print(str(stdout))
        print(str(stderr))
    if retcode != 0:
        print("Apply failed. file path:" + file_path + " Error:" + str(stderr))
    pass


def stashChanges(task, log):
    if task['type'] != 'patch':
        return
    target_path = task['target']
    sub_process_with_timeout.excuteArr([
        'git', 'add', '-A'
    ], target_path, log)
    sub_process_with_timeout.excuteArr([
        'git', 'stash', 'save', 'Auto stash by ohos_setup.py'
    ], target_path, log)


def apply_check(task, log=False):
    file_path = task['file_path']
    target_path = task['target']
    retcode,stdout,stderr = sub_process_with_timeout.excuteArr(
        ['git', 'apply', '--check', '--ignore-whitespace', file_path], target_path, log, timeout=20)
    if log:
        print("retcode:" + str(retcode))
        print(str(stdout))
        print(str(stderr))
    if retcode != 0:
        print("Apply check failed. file path:" + file_path + " Error:" + str(stderr))
    return retcode != -1 and 'error' not in str(stderr)


def doTask(task, log=False):
    sourceFile = "{}/repos/{}".format(ROOT, task['name'])
    targetFile = task['target']
    if (task['type'] == 'dir'):
        file_util.copy_dir(sourceFile, targetFile, log)
    elif (task['type'] == 'files'):
        file_util.copy_files(sourceFile, targetFile, log)
    elif (task['type'] == 'file'):
        file_util.copy_file(sourceFile, targetFile, log)
    elif (task['type'] == 'patch'):
        if apply_check(task, log):
            apply_patch(task, log)
        pass


def parse_config(config_file="{}/scripts/config.json".format(ROOT)):
    log = False
    if (len(sys.argv) > 1): 
      if(sys.argv[1] == '-v'):
        log = True
    with open(config_file) as json_file:
        data = json.load(json_file)
        for task in data:
            stashChanges(task, log)
        for task in data:
            doTask(task, log)

if __name__ == "__main__":
    parse_config()
