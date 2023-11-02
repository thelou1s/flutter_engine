@rem Copyright (c) 2021-2023 Huawei Device Co., Ltd.
@rem Licensed under the Apache License, Version 2.0 (the "License");
@rem you may not use this file except in compliance with the License.
@rem You may obtain a copy of the License at
@rem
@rem     http://www.apache.org/licenses/LICENSE-2.0
@rem
@rem Unless required by applicable law or agreed to in writing, software
@rem distributed under the License is distributed on an "AS IS" BASIS,
@rem WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
@rem See the License for the specific language governing permissions and
@rem limitations under the License.

@echo off
setlocal EnableDelayedExpansion

:config_debug_env
call python .\src\flutter\tools\gn --unoptimized --runtime-mode=debug --ohos --ohos-cpu=arm64
EXIT /B 0



:config_release_env
call python .\src\flutter\tools\gn --runtime-mode=release --ohos --unoptimized --ohos-cpu=arm64
EXIT /B 0

:config_host_debug_env
src/flutter/tools/gn "!HOST_OPT!" "--runtime-mode" "!RT_MODE!" "--no-dart-version-git-info" "--full-dart-sdk" "--no-build-web-sdk" "--disable-desktop-embeddings" "--no-build-embedder-examples" "--verbose" "--trace-gn"
EXIT /B 0

:config
CALL :config_debug_env
@REM CALL :config_release_env
EXIT /B 0

:compile
REM UNKNOWN: {"type":"Pipeline","commands":[{"type":"Command","name":{"text":"find","type":"Word"},"suffix":[{"text":"src/out","type":"Word"},{"text":"-mindepth","type":"Word"},{"text":"1","type":"Word"},{"text":"-maxdepth","type":"Word"},{"text":"1","type":"Word"},{"text":"-type","type":"Word"},{"text":"d","type":"Word"}]},{"type":"Command","name":{"text":"xargs","type":"Word"},"suffix":[{"text":"-n","type":"Word"},{"text":"1","type":"Word"},{"text":"sh","type":"Word"},{"text":"-c","type":"Word"},{"text":"ninja -C $0 || exit 255","type":"Word"}]}]}
EXIT /B 0
