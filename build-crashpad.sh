# 参考 https://github.com/google/gfbuild-angle/blob/master/build.sh

# 所有执行的命令都打印到终端
set -x
# 如果执行过程中有非0退出状态，则立即退出
set -e
# 引用未定义变量则立即退出
set -u

help | head

# 定义平台变量
uname
case "$(uname)" in
"Darwin")
  BUILD_PLATFORM="Mac"
  ;;

"MINGW"*|"MSYS_NT"*)
  BUILD_PLATFORM="Windows"
  ;;

*)
  echo "Unknown OS"
  exit 1
  ;;
esac

# 定义通用变量
TARGET_REPO_NAME="crashpad"

# 安装 depot_tools.
pushd "${HOME}"

# Needed for depot_tools on Windows.
export DEPOT_TOOLS_WIN_TOOLCHAIN=0
git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git
export PATH="${HOME}/depot_tools:${PATH}"
gclient

popd

# clone代码
fetch ${TARGET_REPO_NAME}
cd "${TARGET_REPO_NAME}"
# chromium中查看crashpad版本 https://source.chromium.org/chromium/chromium/src/+/refs/tags/101.0.4951.9:third_party/crashpad/README.chromium
# 查看chromium版本发布时间 https://zh.m.wikipedia.org/wiki/Google_Chrome%E7%89%88%E6%9C%AC%E5%8E%86%E5%8F%B2
# chromium 2020年12月2日版本 87.0.4280.9 crashpad Revision 36d4bb
git checkout 36d4bb
gclient sync

# 编译
RELEASE_GEN_ARGS_x64="target_cpu=\"x64\" is_debug=false"
RELEASE_CONFIG_x64="Release-x64"

RELEASE_GEN_ARGS_x86="target_cpu=\"x86\" is_debug=false"
RELEASE_CONFIG_x86="Release-x86"

DEBUG_GEN_ARGS_x64="target_cpu=\"x64\" is_debug=true"
DEBUG_CONFIG_x64="Debug-x64"

DEBUG_GEN_ARGS_x86="target_cpu=\"x86\" is_debug=true"
DEBUG_CONFIG_x86="Debug-x86"

build_crashpad() {
    gn gen "out/${1}" --args="${2}"
    cat "out/${1}/args.gn"
    autoninja -C "out/${1}"

    # ls -l -R "out/${1}"
}

case "$(uname)" in
"Darwin")
  build_crashpad ${RELEASE_CONFIG_x64} "${RELEASE_GEN_ARGS_x64}"
  build_crashpad ${DEBUG_CONFIG_x64} "${DEBUG_GEN_ARGS_x64}"
  ;;

"MINGW"*|"MSYS_NT"*)
  # /GL-选项大大降低了lib库的大小
  RELEASE_GEN_ARGS_x64=$RELEASE_GEN_ARGS_x64" extra_cflags=\"/MD /GL-\""
  RELEASE_GEN_ARGS_x86=$RELEASE_GEN_ARGS_x86" extra_cflags=\"/MD /GL-\""
  DEBUG_GEN_ARGS_x64=$DEBUG_GEN_ARGS_x64" extra_cflags=\"/MDd /GL-\""
  DEBUG_GEN_ARGS_x86=$DEBUG_GEN_ARGS_x86" extra_cflags=\"/MDd /GL-\""

  build_crashpad ${RELEASE_CONFIG_x64} "${RELEASE_GEN_ARGS_x64}"
  build_crashpad ${DEBUG_CONFIG_x64} "${DEBUG_GEN_ARGS_x64}"
  build_crashpad ${RELEASE_CONFIG_x86} "${RELEASE_GEN_ARGS_x86}"
  build_crashpad ${DEBUG_CONFIG_x86} "${DEBUG_GEN_ARGS_x86}"
  ;;

*)
  echo "Unknown OS"
  exit 1
  ;;
esac

case "$(uname)" in
"Darwin")
  copy_artifacts_mac() {
    # 提取
    ROOT_DIR=$1
    mkdir $ROOT_DIR

    # include
    INCLUDE_DIR=$ROOT_DIR/include
    mkdir $INCLUDE_DIR
    rsync -R $(find ./client -name '*.h') $INCLUDE_DIR
    rsync -R $(find ./third_party/mini_chromium/mini_chromium -name '*.h') $INCLUDE_DIR
    rsync -R $(find ./util -name '*.h') $INCLUDE_DIR

    # lib
    LIB_DIR=$ROOT_DIR/lib
    mkdir $LIB_DIR
    # 旧版crashpad没有common
    # cp out/$2/obj/client/libcommon.a $LIB_DIR
    cp out/$2/obj/client/libclient.a $LIB_DIR
    cp out/$2/obj/util/libutil.a $LIB_DIR
    cp out/$2/obj/third_party/mini_chromium/mini_chromium/base/libbase.a $LIB_DIR

    # bin
    BIN_DIR=$ROOT_DIR/bin
    mkdir $BIN_DIR
    cp out/$2/crashpad_handler $BIN_DIR
  }

  copy_artifacts_mac $BUILD_PLATFORM-$RELEASE_CONFIG_x64 $RELEASE_CONFIG_x64
  copy_artifacts_mac $BUILD_PLATFORM-$DEBUG_CONFIG_x64 $DEBUG_CONFIG_x64
  ;;

"MINGW"*|"MSYS_NT"*)
  copy_artifacts_win() {
    # 提取
    ROOT_DIR=$1
    mkdir $ROOT_DIR

    # include
    INCLUDE_DIR=$ROOT_DIR/include
    mkdir $INCLUDE_DIR
    cp --parent $(find ./client -name '*.h') $INCLUDE_DIR
    cp --parent $(find ./third_party/mini_chromium/mini_chromium -name '*.h') $INCLUDE_DIR
    cp --parent $(find ./util -name '*.h') $INCLUDE_DIR

    # lib
    LIB_DIR=$ROOT_DIR/lib
    mkdir $LIB_DIR
    # 旧版crashpad没有common
    # cp out/$2/obj/client/common.lib $LIB_DIR
    cp out/$2/obj/client/client.lib $LIB_DIR
    cp out/$2/obj/util/util.lib $LIB_DIR
    cp out/$2/obj/third_party/mini_chromium/mini_chromium/base/base.lib $LIB_DIR

    # bin
    BIN_DIR=$ROOT_DIR/bin
    mkdir $BIN_DIR
    cp out/$2/crashpad_handler.exe $BIN_DIR
  }

  copy_artifacts_win $BUILD_PLATFORM-$RELEASE_CONFIG_x64 $RELEASE_CONFIG_x64
  copy_artifacts_win $BUILD_PLATFORM-$DEBUG_CONFIG_x64 $DEBUG_CONFIG_x64
  copy_artifacts_win $BUILD_PLATFORM-$RELEASE_CONFIG_x86 $RELEASE_CONFIG_x86
  copy_artifacts_win $BUILD_PLATFORM-$DEBUG_CONFIG_x86 $DEBUG_CONFIG_x86
  ;;

*)
  echo "Unknown OS"
  exit 1
  ;;
esac

