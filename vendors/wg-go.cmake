set(WGGO_DIR ${PP_BUILD_OUTPUT}/wg-go)

# Add some flags if -DANDROID (requires NDK tools in the PATH)
if(ANDROID)
    set(WGGO_ANDROID 1)
else()
    set(WGGO_ANDROID "")
endif()

if(WIN32)
    if(CMAKE_SYSTEM_PROCESSOR MATCHES "^(AMD64|amd64|x86_64)$")
        set(WGGO_MINGW_PREFIX x86_64-w64-mingw32 CACHE STRING "MinGW-w64 tool prefix for wg-go")
    elseif(CMAKE_SYSTEM_PROCESSOR MATCHES "^(ARM64|arm64|aarch64)$")
        set(WGGO_MINGW_PREFIX aarch64-w64-mingw32 CACHE STRING "MinGW-w64 tool prefix for wg-go")
    else()
        message(FATAL_ERROR "wg-go Windows build does not know the MinGW-w64 prefix for CMAKE_SYSTEM_PROCESSOR='${CMAKE_SYSTEM_PROCESSOR}'. Configure with -DPP_BUILD_USE_WGGO=OFF to skip wg-go.")
    endif()

    set(WGGO_MINGW_HINTS
        "$ENV{STRAWBERRY}/c/bin"
        "C:/Strawberry/c/bin"
        "C:/msys64/ucrt64/bin"
        "C:/msys64/mingw64/bin"
    )

    find_program(WGGO_CC
        NAMES ${WGGO_MINGW_PREFIX}-gcc gcc
        HINTS ${WGGO_MINGW_HINTS}
        DOC "MinGW-w64 C compiler for wg-go"
    )
    find_program(WGGO_CXX
        NAMES ${WGGO_MINGW_PREFIX}-g++ g++
        HINTS ${WGGO_MINGW_HINTS}
        DOC "MinGW-w64 C++ compiler for wg-go"
    )
    find_program(WGGO_GENDEF
        NAMES gendef
        HINTS ${WGGO_MINGW_HINTS}
        DOC "MinGW-w64 gendef tool for wg-go"
    )
    find_program(WGGO_DLLTOOL
        NAMES ${WGGO_MINGW_PREFIX}-dlltool dlltool
        HINTS ${WGGO_MINGW_HINTS}
        DOC "MinGW-w64 dlltool for wg-go"
    )

    set(WGGO_MISSING_TOOLS "")
    foreach(WGGO_TOOL IN ITEMS WGGO_CC WGGO_CXX WGGO_GENDEF WGGO_DLLTOOL)
        if(NOT ${WGGO_TOOL})
            list(APPEND WGGO_MISSING_TOOLS ${WGGO_TOOL})
        elseif(IS_ABSOLUTE "${${WGGO_TOOL}}" AND NOT EXISTS "${${WGGO_TOOL}}")
            list(APPEND WGGO_MISSING_TOOLS ${WGGO_TOOL})
        endif()
    endforeach()
    if(WGGO_MISSING_TOOLS)
        message(FATAL_ERROR "wg-go Windows build requires a MinGW-w64 toolchain for cgo. Missing: ${WGGO_MISSING_TOOLS}. Install Strawberry Perl with its MinGW toolchain, install MSYS2 mingw-w64/ucrt64, add the MinGW bin directory to PATH, or set WGGO_CC, WGGO_CXX, WGGO_GENDEF, and WGGO_DLLTOOL to full tool paths. Configure with -DPP_BUILD_USE_WGGO=OFF to skip WireGuard.")
    endif()

    message(STATUS "wg-go MinGW C compiler: ${WGGO_CC}")
    message(STATUS "wg-go MinGW C++ compiler: ${WGGO_CXX}")
    message(STATUS "wg-go gendef: ${WGGO_GENDEF}")
    message(STATUS "wg-go dlltool: ${WGGO_DLLTOOL}")

    set(WGGO_CMD
        ${CMAKE_COMMAND} -E env
        "CC=${WGGO_CC}"
        "CXX=${WGGO_CXX}"
        "CGO_CFLAGS="
        "CGO_CXXFLAGS="
        "CGO_LDFLAGS="
        make-windows.bat ${WGGO_DIR}
    )
else()
    set(WGGO_CMD
        make -C ${CMAKE_CURRENT_SOURCE_DIR}/vendors/wg-go
        DESTDIR=${WGGO_DIR}
        ANDROID=${WGGO_ANDROID})
endif()

ExternalProject_Add(WireGuardGoProject
    SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/vendors/wg-go
    CONFIGURE_COMMAND ""
    BUILD_COMMAND ${WGGO_CMD}
    INSTALL_COMMAND ""
    BUILD_IN_SOURCE 1
)

if(APPLE)
    add_custom_command(
        TARGET WireGuardGoProject
        POST_BUILD
        COMMAND install_name_tool -id "@rpath/libwg-go.dylib" "${WGGO_DIR}/lib/libwg-go.dylib"
    )
elseif(WIN32)
    add_custom_command(
        TARGET WireGuardGoProject
        POST_BUILD
        COMMAND "${WGGO_GENDEF}" "${WGGO_DIR}/lib/wg-go.dll"
        COMMAND "${WGGO_DLLTOOL}" -d wg-go.def -l "${WGGO_DIR}/lib/wg-go.lib"
    )
endif()

add_library(WireGuardGoInterface INTERFACE)
add_dependencies(WireGuardGoInterface WireGuardGoProject)
target_include_directories(WireGuardGoInterface INTERFACE ${WGGO_DIR}/include)
target_link_directories(WireGuardGoInterface INTERFACE ${WGGO_DIR}/lib)
target_link_libraries(WireGuardGoInterface INTERFACE wg-go)
