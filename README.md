Flutter Engine
==============

原始仓来源：https://github.com/flutter/engine

## 仓库说明：
本仓库是基于flutter官方engine仓库拓展，可构建支持在OpenHarmony设备上运行的flutter engine程序。

## 构建说明：

* 构建环境：
1. 目前支持在Linux与Mac中构建，Window环境中支持构建gen_snapshot;
2. 请确保当前构建环境可以访问DEPS文件中配置的字段allowed_hosts列表。

* 构建步骤：
1. 构建基础环境：可参照[官网](https://github.com/flutter/flutter/wiki/Setting-up-the-Engine-development-environment)；

   需要安装的基础库：

   ```
   sudo apt install python3
   sudo apt install pkg-config
   sudo apt install ninja-build
   ```

   配置node：下载 `node` 并解压，且配置到环境变量中：

   ```
   # nodejs
   export NODE_HOME=/home/<user>/env/node-v14.19.1-linux-x64
   export PATH=$NODE_HOME/bin:$PATH
   ```

   Windows构建环境：
   可参考[官网](https://github.com/flutter/flutter/wiki/Compiling-the-engine#compiling-for-windows) 
   "Compiling for Windows" 章节搭建Windows构建环境


2. 配置文件：创建空文件夹engine，engine内新建.gclient文件，编辑文件：

   ```
   solutions = [
     {
       "managed": False,
       "name": "src/flutter",
       "url": "git@gitee.com:openharmony-sig/flutter_engine.git",
       "custom_deps": {},
       "deps_file": "DEPS",
       "safesync_url": "",
     },
   ]
   ```

3. 同步代码：在engine目录，执行`gclient sync`；这里会同步engine源码、官方packages仓，还有执行ohos_setup任务；

4. 下载sdk： 在[每日构建](http://ci.openharmony.cn/workbench/cicd/dailybuild/dailylist)下载ohos-sdk-full，配置以下环境变量:

```sh
export OHOS_SDK_HOME=<ohos-sdk-full>
```

5. 开始构建：在engine目录，执行`./ohos`，即可开始构建支持ohos设备的flutter engine。
   
6. 更新代码：在engine目录，执行`./ohos -b master`

## Engine构建产物

  [构建产物](https://docs.qq.com/sheet/DUnljRVBYUWZKZEtF?tab=BB08J2)

## FAQ
1. 运行项目工程报Member notfound:'isOhos'的错误：请确保src/third_party/dart目录下应用了所有的dart patch（补丁位于src/flutter/attachment/repos目录，可使用git apply应用patch）应用patch后重新编译engine

2. 提示Permission denied: 执行chmod +x <脚本文件> 添加执行权限

3. 单独编译debug/release/profile模式的engine：`./ohos -t debug|release|profile`

4. 查看帮助：`./ohos -h`

## embedding层代码构建指导

1. 编辑shell/platform/ohos/flutter_embedding/local.properties：

    ```
    sdk.dir=<OpenHarmony的sdk目录>
    nodejs.dir=<nodejs的sdk目录>
    ```

2. 在shell/platform/ohos/flutter_embedding目录下，执行 

    ```
    ./hvigorw --mode module -p module=flutter@default -p product=default assembleHar --no-daemon
    ```

3. har文件输出路径为：shell/platform/ohos/flutter_embedding/flutter/build

ps:如果你使用的是DevEco Studio的Beta版本，编译工程时遇到“must have required property 'compatibleSdkVersion', location: build-profile.json5:17:11"错误，请参考《DevEco Studio环境配置指导.docx》中的‘6 创建工程和运行Hello World’【配置插件】章节修改 shell/platform/ohos/flutter_embedding/hvigor/hvigor-config.json5文件。
