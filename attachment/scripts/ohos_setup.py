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
import json
import file_util
import excute_util
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


def apply_patch(task):
    file_path = task['file_path']
    target_path = task['target']
    excute_util.excuteArr(['git', 'apply', file_path], target_path)
    pass


def apply_check(task):
    file_path = task['file_path']
    target_path = task['target']
    result = excute_util.excuteArr(
        ['git', 'apply', '--check', file_path], target_path)
    return result != '-1' and 'error' not in result


def doTask(task):
    sourceFile = "{}/repos/{}".format(ROOT, task['name'])
    targetFile = task['target']
    if (task['type'] == 'dir'):
        file_util.copy_dir(sourceFile, targetFile)
    elif (task['type'] == 'files'):
        file_util.copy_files(sourceFile, targetFile)
    elif (task['type'] == 'file'):
        file_util.copy_file(sourceFile, targetFile)
    elif (task['type'] == 'patch'):
        if apply_check(task):
            apply_patch(task)


def parse_config(config_file="{}/scripts/config.json".format(ROOT)):
    with open(config_file) as json_file:
        data = json.load(json_file)
        for task in data:
            doTask(task)


if __name__ == "__main__":
    parse_config()
