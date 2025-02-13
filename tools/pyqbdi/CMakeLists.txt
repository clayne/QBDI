if(QBDI_ARCH_X86
   OR QBDI_ARCH_X86_64
   OR QBDI_ARCH_AARCH64
   OR QBDI_ARCH_ARM)

  if(DEFINED QBDI_TOOLS_PYQBDI_TARGET_PYTHON_VERSION)
    find_package(
      Python3 "${QBDI_TOOLS_PYQBDI_TARGET_PYTHON_VERSION}" EXACT REQUIRED
      COMPONENTS Interpreter Development.Module
      OPTIONAL_COMPONENTS Development.Embed)
  else()
    find_package(
      Python3 REQUIRED
      COMPONENTS Interpreter Development.Module
      OPTIONAL_COMPONENTS Development.Embed)
  endif()

  if(NOT Python3_FOUND)
    message(FATAL_ERROR "Python3 not found")
  endif()

  # in manylinux image, python doesn't have a library
  # If Python3::Development is not found, try to found the include with the executable
  if(NOT Python3_Development_FOUND AND "${Python3_INCLUDE_DIRS}" STREQUAL "")
    execute_process(
      COMMAND "${Python3_EXECUTABLE}" -c
              "from sysconfig import get_paths; print(get_paths()['include'])"
      OUTPUT_VARIABLE Python3_INCLUDE_DIRS
      OUTPUT_STRIP_TRAILING_WHITESPACE)
    if("${Python3_INCLUDE_DIRS}" STREQUAL "")
      message(FATAL_ERROR "Python3_INCLUDE_DIRS not found")
    endif()
  endif()

  execute_process(
    COMMAND "${Python3_EXECUTABLE}" -c
            "import platform; print(platform.architecture()[0])"
    OUTPUT_VARIABLE PYTHON_BIT
    OUTPUT_STRIP_TRAILING_WHITESPACE)

  message(STATUS "Python lib:     ${Python3_LIBRARIES}")
  message(STATUS "Python include: ${Python3_INCLUDE_DIRS}")
  message(STATUS "Python interpreter: ${Python3_EXECUTABLE}")
  message(STATUS "Python ${PYTHON_BIT}")

  # verify we compile pyqbdi tools with the good version of python
  if((${PYTHON_BIT} STREQUAL "64bit") AND NOT (QBDI_ARCH_X86_64
                                               OR QBDI_ARCH_AARCH64))
    message(
      FATAL_ERROR
        "PyQBDI with Python ${PYTHON_BIT} is not compatible with the architecture ${QBDI_ARCH}"
    )
  elseif((${PYTHON_BIT} STREQUAL "32bit") AND NOT (QBDI_ARCH_X86
                                                   OR QBDI_ARCH_ARM))
    message(
      FATAL_ERROR
        "PyQBDI with Python ${PYTHON_BIT} is not compatible with the architecture ${QBDI_ARCH}"
    )
  endif()

  add_library(pyqbdi_utils INTERFACE)
  add_dependencies(pyqbdi_utils pyqbdi_pybind11)

  add_library(pyqbdi_module INTERFACE)
  add_dependencies(pyqbdi_module pyqbdi_pybind11)

  if(QBDI_PLATFORM_WINDOWS)
    target_compile_options(pyqbdi_utils INTERFACE "/GR" "/EHsc")
    target_compile_options(pyqbdi_module INTERFACE "/GR" "/EHsc")
  else()
    target_compile_options(pyqbdi_utils INTERFACE "-frtti")
    target_compile_options(pyqbdi_module INTERFACE "-frtti")
  endif()

  include("${CMAKE_CURRENT_SOURCE_DIR}/utils/CMakeLists.txt")
  include("${CMAKE_CURRENT_SOURCE_DIR}/binding/CMakeLists.txt")

  ##
  # Shared library with QBDIPreload (if available)
  ##
  set(PYQBDI_SRC_MODULE "${CMAKE_CURRENT_SOURCE_DIR}/pyqbdi_module.cpp")
  pybind11_add_module(pyqbdi ${PYQBDI_SRC_MODULE})
  target_include_directories(
    pyqbdi PRIVATE $<BUILD_INTERFACE:${CMAKE_CURRENT_BINARY_DIR}>
                   ${CMAKE_CURRENT_SOURCE_DIR} ${Python3_INCLUDE_DIRS})

  target_link_libraries(pyqbdi PRIVATE pyqbdi_module pyqbdi_utils QBDI_static)
  set_target_properties(pyqbdi PROPERTIES CXX_STANDARD 14 CXX_STANDARD_REQUIRED
                                                          ON)

  set_target_properties(pyqbdi PROPERTIES PREFIX "")

  if(QBDI_PLATFORM_OSX)
    set_target_properties(pyqbdi PROPERTIES LINK_FLAGS
                                            "-undefined dynamic_lookup")
  elseif(QBDI_PLATFORM_LINUX)
    set_target_properties(pyqbdi PROPERTIES LINK_FLAGS "-s")
  elseif(QBDI_PLATFORM_WINDOWS)
    set_target_properties(pyqbdi PROPERTIES SUFFIX ".pyd")
  endif()

  if(QBDI_TOOLS_QBDIPRELOAD)
    # Due to the use of embeded interpreter in PyQBDIPreload, we should like
    # it against the python library. However, in manylinux image,
    # lipython3.XX.so is not available. The script pyqbdipreload.py will search
    # for this library at the runtime, so the lipython3.XX.so is not available
    # at build time, just omit it.
    if(Python3_Development.Embed_FOUND)
      pybind11_add_module(pyqbdipreloadlib SHARED
                          "${CMAKE_CURRENT_SOURCE_DIR}/preload.cpp")
    else()
      pybind11_add_module(pyqbdipreloadlib
                          "${CMAKE_CURRENT_SOURCE_DIR}/preload.cpp")
    endif()

    target_include_directories(
      pyqbdipreloadlib
      PRIVATE $<BUILD_INTERFACE:${CMAKE_CURRENT_BINARY_DIR}>
              "${CMAKE_CURRENT_SOURCE_DIR}"
              "${CMAKE_CURRENT_SOURCE_DIR}/../QBDIPreload/include"
              ${Python3_INCLUDE_DIRS})

    target_link_libraries(pyqbdipreloadlib PRIVATE pyqbdi_module pyqbdi_utils
                                                   QBDIPreload QBDI_static)
    set_target_properties(pyqbdipreloadlib PROPERTIES CXX_STANDARD 14
                                                      CXX_STANDARD_REQUIRED ON)
    set_target_properties(pyqbdipreloadlib PROPERTIES PREFIX "")

    if(QBDI_PLATFORM_OSX)
      set_target_properties(pyqbdipreloadlib
                            PROPERTIES LINK_FLAGS "-undefined dynamic_lookup")
      # fix import library of pyqbdipreloadlib:
      # - remove all rpath
      # - change id
      # - replace Python lib by libpythonX.Y.dylib
      # - resign
      add_custom_command(
        TARGET pyqbdipreloadlib
        POST_BUILD
        COMMAND
          "${Python3_EXECUTABLE}"
          "${CMAKE_CURRENT_SOURCE_DIR}/fix_preload_lib_osx.py"
          $<TARGET_FILE:pyqbdipreloadlib>)
    elseif(QBDI_PLATFORM_LINUX)
      set_target_properties(pyqbdipreloadlib PROPERTIES LINK_FLAGS "-s")
    endif()

  endif()

  if(PYQBDI_OUTPUT_DIRECTORY)
    message(STATUS "export PYQBDI to ${PYQBDI_OUTPUT_DIRECTORY}/")
    add_custom_command(
      TARGET pyqbdi
      POST_BUILD
      COMMAND ${CMAKE_COMMAND} -E copy $<TARGET_FILE:pyqbdi>
              ${PYQBDI_OUTPUT_DIRECTORY}/$<TARGET_FILE_NAME:pyqbdi>)
    if(QBDI_TOOLS_QBDIPRELOAD)
      add_custom_command(
        TARGET pyqbdipreloadlib
        POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy $<TARGET_FILE:pyqbdipreloadlib>
                ${PYQBDI_OUTPUT_DIRECTORY}/$<TARGET_FILE_NAME:pyqbdipreloadlib>
        COMMAND
          ${CMAKE_COMMAND} -E copy
          "${CMAKE_CURRENT_SOURCE_DIR}/pyqbdipreload.py"
          "${PYQBDI_OUTPUT_DIRECTORY}/pyqbdipreload.py")
    endif()

    # Note Windows : also see tools/QBDIWinPreloader/CMakeLists.txt for WinPreload in wheel package
  endif()

  ##
  # Library for doc
  ##
  add_custom_command(
    TARGET pyqbdi
    POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy $<TARGET_FILE:pyqbdi>
            ${PROJECT_BINARY_DIR}/docs/$<TARGET_FILE_NAME:pyqbdi>)

endif()
