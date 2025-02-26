#!/bin/bash

ORIGINAL_ARGS=${@:1}

set -e

#
bench_run_ts=$(date +%s)
log_file="bench_log_$bench_run_ts.txt"
build_root="$PWD/build/${bench_run_ts}"

function ts() {
  echo $(date +%s%N | cut -b1-13)
}

function log() {
  line="$(ts) $@"
  echo $line
  echo $line >> $log_file
}

rm -rf $build_root

# hack, get tipi tools on PATH
PATH=$(tipi run 'echo $PATH' | tail -n +2)

tipi connect

function bench_run() {

  local cmake_bin=${1}
  local title=${2}
  local build_folder=${3}
  local hfc_on_flag=${4}
  local hfc_source_cache_flag=${5}
  local use_install_cache=${6}
  local cmake_re_flags=${7}
  
  local bench_start=`ts`
  log "[$title] bench start"

  if [[ "$use_install_cache" == "true" ]]; then
    local install_cache_flag_debug="-DBENCH_HFC_LOCAL_INSTALL_CACHE=$build_root/$build_folder/deps_debug"
    local install_cache_flag_release="-DBENCH_HFC_LOCAL_INSTALL_CACHE=$build_root/$build_folder/deps_release"
  else
    local install_cache_flag_debug=""
    local install_cache_flag_release=""
  fi

  mkdir -p $build_root/$build_folder

  for i in $(seq 1 5);
  do
    log "[$title] run started $i"
    local run_start=`ts`

    # release build boost 1.84
    log "[$title] - Release configure start (-DBENCH_BOOST_VERSION=1.84 $hfc_on_flag $install_cache_flag_release $hfc_source_cache_flag)"
    local configure_start=`ts`
    $cmake_bin -GNinja -S . -B $build_root/$build_folder/release $cmake_re_flags -DCMAKE_TOOLCHAIN_FILE=environments/host.cmake -DBENCH_BOOST_VERSION=1.84 -DCMAKE_BUILD_TYPE=Release $hfc_on_flag $install_cache_flag_release $hfc_source_cache_flag
    log "[$title] - Release configure took $(($(ts) - $configure_start))ms"
    
    local build_start=`ts`
    log "[$title] - Release build start (-DBENCH_BOOST_VERSION=1.84)"
    $cmake_bin --build $build_root/$build_folder/release $cmake_re_flags
    log "[$title] - Release build took $(($(ts) - $build_start))ms"

    # debug build boost 1.84
    local configure_start=`ts`
    log "[$title] - Debug configure start (-DBENCH_BOOST_VERSION=1.84 $hfc_on_flag $install_cache_flag_debug $hfc_source_cache_flag)"
    $cmake_bin -GNinja -S . -B $build_root/$build_folder/debug $cmake_re_flags -DCMAKE_TOOLCHAIN_FILE=environments/host.cmake -DBENCH_BOOST_VERSION=1.84 -DCMAKE_BUILD_TYPE=Debug $hfc_on_flag $install_cache_flag_debug $hfc_source_cache_flag
    log "[$title] - Debug configure took $(($(ts) - $configure_start))ms"

    local build_start=`ts`
    log "[$title] - Debug build start (-DBENCH_BOOST_VERSION=1.84)"
    $cmake_bin --build $build_root/$build_folder/debug $cmake_re_flags
    log "[$title] - Debug build took $(($(ts) - $build_start))ms"

    log "[$title] - cleaning up"
    set +e
    rm -rf $build_root/$build_folder/release/* $build_root/$build_folder/release/.*
    rm -rf $build_root/$build_folder/debug/* $build_root/$build_folder/debug/.*
    set -e

    # release build boost 1.85
    log "[$title] - Release configure start (-DBENCH_BOOST_VERSION=1.85 $hfc_on_flag $install_cache_flag_release $hfc_source_cache_flag)"
    local configure_start=`ts`
    $cmake_bin -GNinja -S . -B $build_root/$build_folder/release $cmake_re_flags -DCMAKE_TOOLCHAIN_FILE=environments/host.cmake -DBENCH_BOOST_VERSION=1.85 -DCMAKE_BUILD_TYPE=Release $hfc_on_flag $install_cache_flag_release $hfc_source_cache_flag
    log "[$title] - Release configure took $(($(ts) - $configure_start))ms"
    
    local  build_start=`ts`
    log "[$title] - Release build start (-DBENCH_BOOST_VERSION=1.85)"
    $cmake_bin --build $build_root/$build_folder/release $cmake_re_flags
    log "[$title] - Release build took $(($(ts) - $build_start))ms"

    # debug build boost 1.85
    local configure_start=`ts`
    log "[$title] - Debug configure start (-DBENCH_BOOST_VERSION=1.85 $hfc_on_flag $install_cache_flag_debug $hfc_source_cache_flag)"
    $cmake_bin -GNinja -S . -B $build_root/$build_folder/debug $cmake_re_flags -DCMAKE_TOOLCHAIN_FILE=environments/host.cmake -DBENCH_BOOST_VERSION=1.85 -DCMAKE_BUILD_TYPE=Debug $hfc_on_flag $install_cache_flag_debug $hfc_source_cache_flag
    log "[$title] - Debug configure took $(($(ts) - $configure_start))ms"

    local build_start=`ts`
    log "[$title] - Debug build start (-DBENCH_BOOST_VERSION=1.85)"
    $cmake_bin --build $build_root/$build_folder/debug $cmake_re_flags
    log "[$title] - Debug build took $(($(ts) - $build_start))ms"  

    # overall run time
    log "[$title] - run took $(($(ts) - $run_start))ms"

    log "[$title] - cleaning up"
    set +e
    rm -rf $build_root/$build_folder/release/* $build_root/$build_folder/release/.*
    rm -rf $build_root/$build_folder/debug/* $build_root/$build_folder/debug/.*
    set -e
  done;

  log "[$title] bench end - took $(($(ts) - $bench_start))ms"
}


# make sure we have a unique toolchain...
echo "# appened by run_bench.sh / $(od -x /dev/urandom | head -1 | awk '{OFS="-"; print $2$3,$4,$5,$6,$7$8$9}')" >> environments/host.cmake

# the actual benchmark runs... some of those take a good while... as in I'm expecting hours for all of this to run through .... ordered by quickest to slowest (based on expectations)
#         $cmake_bin    $title                $build_folder           $hfc_on_flag        $hfc_source_cache_flag                                          $use_install_cache      $cmake_re_flags
#bench_run "cmake-re"    "cmake-re+HFC"        "cmake_re_hfc"          "-DBENCH_HFC=ON"    "-DBENCH_HFC_LOCAL_SOURCE_CACHE=/tmp/hfc_cmake_re_cache"        "false"                 "--host";
#bench_run "cmake"       "cmake+HFC"           "hfc"                   "-DBENCH_HFC=ON"    "-DBENCH_HFC_LOCAL_SOURCE_CACHE=/tmp/hfc_cmake_cache"           "false"                 "";
bench_run "cmake"       "cmake+fetchcontent"  "classic_fetchContent"  "-DBENCH_HFC=OFF"   ""                                                              "false"                 "";
