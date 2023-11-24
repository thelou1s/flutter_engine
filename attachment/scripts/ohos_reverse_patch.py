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
import excute_util
from operator import itemgetter

"""
在gclient中pre_deps_hooks中配置执行,用于在sync前回滚patch
职责如下：
1.解析config.json,并按顺序倒序排序
2.回滚目录下的patch
"""
ROOT = './src/flutter/attachment'

def apply_reverse_patch(task, log=False):
    file_path = task['file_path']
    target_path = task['target']
    excute_util.excuteArr(['git', 'apply', '-R', '--ignore-whitespace', file_path], target_path, log)
    pass

def apply_reverse_check(task, log=False):
    file_path = task['file_path']
    target_path = task['target']
    result = excute_util.excuteArr(
        ['git', 'apply', '-R', '--check', '--ignore-whitespace', file_path], target_path, log)
    return result != '-1' and 'error' not in result

def doTask(task, log=False):
    if (task['type'] == 'patch'):
        if (apply_reverse_check(task, False)):
            apply_reverse_patch(task, log)

def parse_config(config_file="{}/scripts/config.json".format(ROOT)):
    log = False
    if (len(sys.argv) > 1): 
      if(sys.argv[1] == '-v'):
        log = True
    with open(config_file) as json_file:
        data = json.load(json_file)
        data = sorted(data, key=itemgetter('name'), reverse=True)
        for task in data:
            doTask(task, log)

if __name__ == "__main__":
    parse_config()
    