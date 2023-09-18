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
#! /bin/sh

chmod -R +w  .vpython*
#cp -a  .vpython*  ~/

cp -a .vpython-root  .vpython-root-new
find .vpython-root-new/ -type l -exec ls -l {} \; | awk '{
	    D = ENVIRON["PWD"];
	    TARGET = $9;
	    s = index($11, "depot");
	    T = D "/" substr($11, s);
	   #print $9 "->" T;
	   cmd = "rm -f " TARGET;
	   system(cmd);
	   cmd = "ln -sf " T " " TARGET;
	   system(cmd);
}'

rm -rf ~/.vpython-root
cp -a .vpython-root-new   ~/.vpython-root&&  rm -rf .vpython-root-new
cp -a  .vpython_cipd_cache  ~/

chmod -R +w  ~/.vpython*
