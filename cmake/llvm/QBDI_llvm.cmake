if(__add_qbdi_llvm)
  return()
endif()
set(__add_qbdi_llvm ON)

include(FetchContent)

# configure FetchContent
set(QBDI_LLVM_MAJOR_VERSION 19)
set(QBDI_LLVM_VERSION 19.1.5)

# download and include llvm cmake module
option(QBDI_INCLUDE_LLVM_CMAKE_MODUKE "Include llvm cmake module" ON)
if(QBDI_INCLUDE_LLVM_CMAKE_MODUKE)
  FetchContent_Populate(
    llvm_cmake
    URL "https://github.com/llvm/llvm-project/releases/download/llvmorg-${QBDI_LLVM_VERSION}/cmake-${QBDI_LLVM_VERSION}.src.tar.xz"
    URL_HASH
      "SHA256=a08ae477571fd5e929c27d3d0d28c6168d58dd00b6354c2de3266ae0d86ad44f"
    DOWNLOAD_DIR "${QBDI_THIRD_PARTY_DIRECTORY}/llvm-cmake-download"
    SOURCE_DIR "${FETCHCONTENT_BASE_DIR}/qbdi_llvm/cmake"
    BINARY_DIR "${FETCHCONTENT_BASE_DIR}/llvm_cmake-build"
    SUBBUILD_DIR "${FETCHCONTENT_BASE_DIR}/llvm_cmake-subbuild"
    QUIET)
endif()

# Variable also use in QBDI_llvm_tblgen
set(QBDI_LLVM_URL
    "https://github.com/llvm/llvm-project/releases/download/llvmorg-${QBDI_LLVM_VERSION}/llvm-${QBDI_LLVM_VERSION}.src.tar.xz"
)
set(QBDI_LLVM_URL_HASH
    "SHA256=7d71635948e4da1814ce8e15ec45399e4094a5442e86d352c96ded0f2b3171b6")

FetchContent_Populate(
  llvm
  URL "${QBDI_LLVM_URL}"
  URL_HASH "${QBDI_LLVM_URL_HASH}"
  DOWNLOAD_DIR "${QBDI_THIRD_PARTY_DIRECTORY}/llvm-download"
  SOURCE_DIR "${FETCHCONTENT_BASE_DIR}/qbdi_llvm/llvm"
  BINARY_DIR "${FETCHCONTENT_BASE_DIR}/llvm-build"
  SUBBUILD_DIR "${FETCHCONTENT_BASE_DIR}/llvm-subbuild"
  QUIET)

set(CMAKE_CXX_STANDARD
    17
    CACHE STRING "USE CPP 17")
set(LLVM_BUILD_TOOLS
    OFF
    CACHE BOOL "Disable LLVM_BUILD_TOOLS")
set(LLVM_BUILD_UTILS
    OFF
    CACHE BOOL "Disable LLVM_BUILD_UTILS")
set(LLVM_BUILD_TESTS
    OFF
    CACHE BOOL "Disable LLVM_BUILD_TESTS")
set(LLVM_BUILD_BENCHMARKS
    OFF
    CACHE BOOL "Disable LLVM_BUILD_BENCHMARKS")
set(LLVM_BUILD_EXAMPLES
    OFF
    CACHE BOOL "Disable LLVM_BUILD_EXAMPLES")
set(LLVM_INCLUDE_TOOLS
    OFF
    CACHE BOOL "Disable LLVM_INCLUDE_TOOLS")
set(LLVM_INCLUDE_UTILS
    OFF
    CACHE BOOL "Disable LLVM_INCLUDE_UTILS")
set(LLVM_INCLUDE_TESTS
    OFF
    CACHE BOOL "Disable LLVM_INCLUDE_TESTS")
set(LLVM_INCLUDE_BENCHMARKS
    OFF
    CACHE BOOL "Disable LLVM_INCLUDE_BENCHMARKS")
set(LLVM_INCLUDE_EXAMPLES
    OFF
    CACHE BOOL "Disable LLVM_INCLUDE_EXAMPLES")
set(LLVM_ENABLE_TERMINFO
    OFF
    CACHE BOOL "Disable LLVM_ENABLE_TERMINFO")
set(LLVM_ENABLE_BINDINGS
    OFF
    CACHE BOOL "Disable LLVM_ENABLE_BINDINGS")
set(LLVM_ENABLE_RTTI
    OFF
    CACHE BOOL "Disable LLVM_ENABLE_RTTI")
set(LLVM_APPEND_VC_REV
    OFF
    CACHE BOOL "Disable LLVM_APPEND_VC_REV")
set(LLVM_ENABLE_Z3_SOLVER
    OFF
    CACHE BOOL "Disable LLVM_ENABLE_Z3_SOLVER")
set(LLVM_ENABLE_ZLIB
    OFF
    CACHE BOOL "Disable LLVM_ENABLE_ZLIB")
set(LLVM_ENABLE_ZSTD
    OFF
    CACHE BOOL "Disable LLVM_ENABLE_ZSTD")
set(LLVM_TARGET_ARCH
    ${QBDI_LLVM_ARCH}
    CACHE STRING "set LLVM_ARCH")
set(LLVM_TARGETS_TO_BUILD
    ${QBDI_LLVM_ARCH}
    CACHE STRING "set LLVM_TARGETS_TO_BUILD")

set(QBDI_LLVM_TRIPLE "")
if(QBDI_ARCH_ARM)
  if(QBDI_PLATFORM_ANDROID)
    set(QBDI_LLVM_TRIPLE armv7-linux-androideabi)
  else()
    set(QBDI_LLVM_TRIPLE armv7-linux-gnu)
  endif()
elseif(QBDI_ARCH_AARCH64)
  if(QBDI_PLATFORM_ANDROID)
    set(QBDI_LLVM_TRIPLE aarch64-linux-android)
  else()
    set(QBDI_LLVM_TRIPLE aarch64-linux-gnu)
  endif()
elseif(QBDI_ARCH_X86)
  set(LLVM_BUILD_32_BITS
      ON
      CACHE INTERNAL "set LLVM_BUILD_32_BITS")
  if(QBDI_PLATFORM_OSX)
    set(LLVM_ENABLE_LIBCXX
        ON
        CACHE INTERNAL "set LLVM_ENABLE_LIBCXX")
    set(QBDI_LLVM_TRIPLE i386-apple-darwin17.7.0)
  elseif(QBDI_PLATFORM_LINUX OR QBDI_PLATFORM_ANDROID)
    set(QBDI_LLVM_TRIPLE i386-pc-linux)
  endif()
elseif(QBDI_ARCH_X86_64)
  if(QBDI_PLATFORM_LINUX)
    set(QBDI_LLVM_TRIPLE x86_64-pc-linux-gnu)
  endif()
else()
  message(FATAL_ERROR "Unsupported LLVM Architecture.")
endif()

if(QBDI_PLATFORM_WINDOWS)
  add_compile_definitions(_DISABLE_CONSTEXPR_MUTEX_CONSTRUCTOR)
endif()

if(NOT ("${QBDI_LLVM_TRIPLE}" STREQUAL ""))
  set(LLVM_DEFAULT_TARGET_TRIPLE
      "${QBDI_LLVM_TRIPLE}"
      CACHE STRING "set LLVM_DEFAULT_TARGET_TRIPLE")
endif()

# build llvm with visibility hidden
if(DEFINED CMAKE_C_VISIBILITY_PRESET)
  set(QBDI_CACHE_CMAKE_C_VISIBILITY_PRESET ${CMAKE_C_VISIBILITY_PRESET})
endif()
if(DEFINED CMAKE_CXX_VISIBILITY_PRESET)
  set(QBDI_CACHE_CMAKE_CXX_VISIBILITY_PRESET ${CMAKE_CXX_VISIBILITY_PRESET})
endif()
set(CMAKE_C_VISIBILITY_PRESET
    "hidden"
    CACHE STRING "set CMAKE_C_VISIBILITY_PRESET" FORCE)
set(CMAKE_CXX_VISIBILITY_PRESET
    "hidden"
    CACHE STRING "set CMAKE_CXX_VISIBILITY_PRESET" FORCE)

if(NOT ("${NATIVE_TABLEN_PATH}" STREQUAL ""))
  set(LLVM_TABLEGEN
      "${NATIVE_TABLEN_PATH}"
      CACHE INTERNAL "force tablegen")
elseif(NOT ("${QBDI_LLVM_TABLEN_TOOLSCHAIN}" STREQUAL ""))
  # create a second directory to build the native llvm-tblgen
  # mostly use when crosscompile and need another compiler to create a native
  # target
  include(QBDI_llvm_tblgen)
  set(LLVM_TABLEGEN
      "${QBDI_LLVM_NATIVE_TBLGEN}"
      CACHE INTERNAL "force tablegen")
else()
  # check if llvm-tblgen-X is available
  find_program(LLVM_TABLEN_BIN NAMES llvm-tblgen-${QBDI_LLVM_MAJOR_VERSION})
  message(STATUS "LLVM Table Gen found: ${LLVM_TABLEN_BIN}")
  if(${LLVM_TABLEN_BIN_FOUND})
    set(LLVM_TABLEGEN
        "${LLVM_TABLEN_BIN}"
        CACHE STRING "force tablegen")
  endif()
endif()

if(QBDI_CCACHE AND CCACHE_FOUND)
  set(LLVM_CCACHE_BUILD
      ON
      CACHE BOOL "Enable CCACHE in llvm")
else()
  set(LLVM_CCACHE_BUILD
      OFF
      CACHE BOOL "Enable CCACHE in llvm")
endif()

if(QBDI_ASAN AND HAVE_FLAG_SANITIZE_ADDRESS)
  set(LLVM_USE_SANITIZER
      Address
      CACHE STRING "Enable ASAN")
endif()

add_subdirectory(${llvm_SOURCE_DIR} ${llvm_BINARY_DIR} EXCLUDE_FROM_ALL)

# restore visibility
if(DEFINED QBDI_CACHE_CMAKE_C_VISIBILITY_PRESET)
  set(CMAKE_C_VISIBILITY_PRESET
      ${QBDI_CACHE_CMAKE_C_VISIBILITY_PRESET}
      CACHE INTERNAL "set CMAKE_C_VISIBILITY_PRESET" FORCE)
else()
  unset(CMAKE_C_VISIBILITY_PRESET CACHE)
endif()
if(DEFINED QBDI_CACHE_CMAKE_CXX_VISIBILITY_PRESET)
  set(CMAKE_CXX_VISIBILITY_PRESET
      ${QBDI_CACHE_CMAKE_CXX_VISIBILITY_PRESET}
      CACHE INTERNAL "set CMAKE_CXX_VISIBILITY_PRESET" FORCE)
else()
  unset(CMAKE_CXX_VISIBILITY_PRESET CACHE)
endif()

# list of LLVM library to build
set(QBDI_LLVM_TARGET_LIBRARY)
set(QBDI_LLVM_LINK_LIBRARY)
macro(add_llvm_lib)
  foreach(LIB ${ARGV})
    if("${LIB}" MATCHES "^::@")
      continue()
    endif()
    string(FIND "${LIB}" "::@" pos)
    if("${pos}" EQUAL -1)
      set(TARGETLIB "${LIB}")
    else()
      string(SUBSTRING "${LIB}" 0 "${pos}" TARGETLIB)
    endif()
    if((TARGET ${TARGETLIB}) AND NOT (${TARGETLIB} IN_LIST
                                      QBDI_LLVM_TARGET_LIBRARY))
      list(APPEND QBDI_LLVM_TARGET_LIBRARY ${TARGETLIB})
      get_target_property(_LIB_LINK ${TARGETLIB} INTERFACE_LINK_LIBRARIES)
      if(_LIB_LINK)
        add_llvm_lib(${_LIB_LINK})
      endif()
    elseif(NOT (TARGET ${TARGETLIB}) AND NOT (${TARGETLIB} IN_LIST
                                              QBDI_LLVM_LINK_LIBRARY))
      list(APPEND QBDI_LLVM_LINK_LIBRARY ${TARGETLIB})
    endif()
  endforeach()
endmacro()

add_llvm_lib(
  LLVMBinaryFormat
  LLVMMCDisassembler
  LLVMMCParser
  LLVMMC
  LLVMSupport
  LLVMObject
  LLVMTextAPI
  LLVMCore
  LLVMBitReader
  LLVMBitstreamReader
  LLVMRemarks)

if(QBDI_PLATFORM_OSX OR QBDI_PLATFORM_IOS)
  add_llvm_lib(LLVMDemangle)
endif()

if(QBDI_ARCH_ARM)
  add_llvm_lib(LLVMARMAsmParser LLVMARMDisassembler LLVMARMDesc LLVMARMInfo
               LLVMARMUtils)
elseif(QBDI_ARCH_AARCH64)
  add_llvm_lib(LLVMAArch64AsmParser LLVMAArch64Desc LLVMAArch64Disassembler
               LLVMAArch64Info LLVMAArch64Utils)
elseif(QBDI_ARCH_X86_64 OR QBDI_ARCH_X86)
  add_llvm_lib(LLVMX86AsmParser LLVMX86Disassembler LLVMX86Desc LLVMX86Info)
else()
  message(FATAL_ERROR "Unsupported LLVM Architecture.")
endif()

if(QBDI_PLATFORM_OSX)
  find_package(Python3 REQUIRED COMPONENTS Interpreter)

  set(LLVMSupportFixName "${llvm_BINARY_DIR}/libLLVMSupportFix.a")
  add_custom_command(
    OUTPUT "${LLVMSupportFixName}"
    COMMAND
      "${Python3_EXECUTABLE}"
      "${CMAKE_CURRENT_SOURCE_DIR}/cmake/llvm/rename_object.py" -i
      $<TARGET_FILE:LLVMSupport> -o "${LLVMSupportFixName}" -r Memory.cpp.o 1 -r
      Error.cpp.o 1
    COMMENT "Fix LLVMSupport library"
    DEPENDS LLVMSupport
    VERBATIM)
  list(REMOVE_ITEM QBDI_LLVM_TARGET_LIBRARY LLVMSupport)
  list(APPEND QBDI_LLVM_TARGET_LIBRARY "${LLVMSupportFixName}")

  set(LLVMObjectFixName "${llvm_BINARY_DIR}/libLLVMObjectFix.a")
  add_custom_command(
    OUTPUT "${LLVMObjectFixName}"
    COMMAND
      "${Python3_EXECUTABLE}"
      "${CMAKE_CURRENT_SOURCE_DIR}/cmake/llvm/rename_object.py" -i
      $<TARGET_FILE:LLVMObject> -o "${LLVMObjectFixName}" -r Minidump.cpp.o 1
    COMMENT "Fix LLVMObject library"
    DEPENDS LLVMObject
    VERBATIM)
  list(REMOVE_ITEM QBDI_LLVM_TARGET_LIBRARY LLVMObject)
  list(APPEND QBDI_LLVM_TARGET_LIBRARY "${LLVMObjectFixName}")

  list(APPEND QBDI_LLVM_LINK_LIBRARY -lc++)
elseif(QBDI_PLATFORM_LINUX)
  list(APPEND QBDI_LLVM_LINK_LIBRARY -lstdc++)
endif()

merge_static_libs(qbdi-llvm qbdi-llvm \${QBDI_LLVM_TARGET_LIBRARY})
target_link_libraries(qbdi-llvm INTERFACE ${QBDI_LLVM_LINK_LIBRARY})

target_include_directories(
  qbdi-llvm
  INTERFACE ${llvm_SOURCE_DIR}/include
  INTERFACE ${llvm_BINARY_DIR}/include
  INTERFACE ${llvm_SOURCE_DIR}/lib/Target/${QBDI_LLVM_ARCH}
  INTERFACE ${llvm_BINARY_DIR}/lib/Target/${QBDI_LLVM_ARCH}
  INTERFACE ${llvm_SOURCE_DIR}/lib
  INTERFACE ${llvm_BINARY_DIR}/lib)

add_custom_target(llvm DEPENDS qbdi-llvm)
