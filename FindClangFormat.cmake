# FindClangFormat
# ------------------------------------------------------------------
#
# CLANGFORMAT_EXECUTABLE - exact path to clang-format (optional).
# CLANGFORMAT_ROOT or CLANGFORMATROOT - additional directory for search
#    clang-format (optional).
#
# The following are set after the configuration is done:
#   CLANGFORMAT_FOUND       -  true if clang-format found, else otherwise;
#   CLANGFORMAT_ROOT_DIR    -  path to the clang-format base directory;
#   CLANGFORMAT_EXECUTABLE  -  path to the clang-format executable;
#   CLANGFORMAT_VERSION     -  version string of the clang-format.
#
#
# Sample usage:
#
#   find_package(ClangFormat REQUIRED)
#   # And do something like that:
#   add_custom_target(clangformat ALL COMMAND ${CLANGFORMAT_EXECUTABLE}
#       -style=<style | file:filename.clang-format>
#       -i ${ALL_FILES}
#   )
#
#   or:
#   
#   find_package(ClangFormat 14)
#   if (CLANGFORMAT_FOUND)
#       # Do something...
#   endif()
#
#   or:
#   
#   find_package(ClangFormat 14 REQUIRED)
#   # Do something...
#
#
# AUTHOR
#
# Artem SHKURATOV (https://github.com/svs590 / shkuratov.arm@gmail.com).
#
# ------------------------------------------------------------------



macro(get_version EXECUTABLE VERSION_STRING)
    execute_process(
        COMMAND "${${EXECUTABLE}}" --version
        OUTPUT_VARIABLE ${VERSION_STRING}
        ERROR_QUIET
        OUTPUT_STRIP_TRAILING_WHITESPACE
    )

    if (${VERSION_STRING} MATCHES "clang-format version .*")
        # Might be: "clang-format version 14.0.1-++20220426083136+0e27d08cdeb3-1~exp1~20220426083221.132"
        # or: "Ubuntu clang-format version 14.0.1-++20220426083136+0e27d08cdeb3-1~exp1~20220426083221.132"
        # or just "clang-format version 14.0.1"
        string(
            REGEX REPLACE ".*[ \t]?clang-format version ([.0-9]+).*" "\\1"
            ${VERSION_STRING}
            ${${VERSION_STRING}}
        )
    endif()
endmacro(get_version)



# TODO: use cmake_parse_arguments and add
# NO_DEFAULT_PATH/NO_PACKAGE_ROOT_PATH/NO_CMAKE_PATH... options
macro(find_all_programs NAMES PATHS OUTPUT_LIST)
    unset(${OUTPUT_LIST})

    set(FAP_NAMES_SAVE ${${NAMES}})
    set(FAP_PATHS_SAVE ${${PATHS}})
    set(FAP_IGNORE_PATH_SAVE ${CMAKE_IGNORE_PATH})
    set(FAP_SYSTEM_IGNORE_PATH_SAVE ${CMAKE_SYSTEM_IGNORE_PATH})
    
    foreach (name ${FAP_NAMES_SAVE})
        set(CMAKE_IGNORE_PATH ${FAP_IGNORE_PATH_SAVE})
        set(CMAKE_SYSTEM_IGNORE_PATH ${FAP_SYSTEM_IGNORE_PATH_SAVE})
                
        while (TRUE)
            unset(CANDIDATE CACHE)
            find_program(CANDIDATE NAMES ${name} PATHS ${FAP_PATHS_SAVE})

            if (CANDIDATE)
                list(APPEND ${OUTPUT_LIST} ${CANDIDATE})
                
                get_filename_component(EXCLUDE_DIRS "${CANDIDATE}" DIRECTORY)
                list(APPEND CMAKE_IGNORE_PATH ${EXCLUDE_DIRS})
                list(APPEND CMAKE_SYSTEM_IGNORE_PATH ${EXCLUDE_DIRS})
            else()
                unset(CANDIDATE CACHE)
                break()
            endif()
        endwhile()
    
        list(POP_FRONT FAP_NAMES_SAVE)    
    endforeach()
endmacro()



macro(select_by_version VERSION_STRING EXECUTABLES OUTPUT_EXECUTABLE)
    set(SBV_VERSION_STRING "")
    set(SBV_MAX_VERSION_STRING "0.0.0.0")
    unset(OUTPUT_EXECUTABLE)

    foreach(EXECUTABLE_CANDIDATE ${${EXECUTABLES}})
        get_version(EXECUTABLE_CANDIDATE SBV_VERSION_STRING)

        if (${VERSION_STRING} AND ${SBV_VERSION_STRING} VERSION_EQUAL ${VERSION_STRING})
            set(${OUTPUT_EXECUTABLE} ${EXECUTABLE_CANDIDATE})
            break()
        endif()

        if (${SBV_VERSION_STRING} VERSION_GREATER ${SBV_MAX_VERSION_STRING})
            set(SBV_MAX_VERSION_CANDIDATE ${EXECUTABLE_CANDIDATE})
            set(SBV_MAX_VERSION_STRING ${SBV_VERSION_STRING})
        endif()
    endforeach()

    if (NOT ${OUTPUT_EXECUTABLE})
        if (SBV_MAX_VERSION_CANDIDATE)
            set(${OUTPUT_EXECUTABLE} ${SBV_MAX_VERSION_CANDIDATE})
        endif()
    endif()
endmacro()




if (NOT CLANGFORMAT_EXECUTABLE)
    # Generate all executable names form CLANGFORMAT_VER_START to CLANGFORMAT_VER_END
    set(CLANGFORMAT_VER_START 5)
    set(CLANGFORMAT_VER_END 18) # Nearest future
    set(CLANGFORMAT_NAMES "")

    list(APPEND CLANGFORMAT_NAMES clang-format)
        foreach(v RANGE ${CLANGFORMAT_VER_START} ${CLANGFORMAT_VER_END})
        string(CONCAT CLANGFORMAT_NAME "clang-format-" ${v})
        list(APPEND CLANGFORMAT_NAMES ${CLANGFORMAT_NAME})
        string(CONCAT CLANGFORMAT_NAME "clang-format-" ${v} ".0")
        list(APPEND CLANGFORMAT_NAMES ${CLANGFORMAT_NAME})
    endforeach()

    unset(TRY_CLANGFORMAT_ROOT)
    if (CLANGFORMAT_ROOT OR CLANGFORMATROOT)
        if (CLANGFORMAT_ROOT)
            set(TRY_CLANGFORMAT_ROOT ${CLANGFORMAT_ROOT})
        else()
            set(TRY_CLANGFORMAT_ROOT ${CLANGFORMATROOT})
        endif()
    else()
        if (DEFINED ENV{CLANGFORMAT_ROOT})
            set(TRY_CLANGFORMAT_ROOT $ENV{CLANGFORMAT_ROOT})
        elif (DEFINED ENV{CLANGFORMATROOT})
            set(TRY_CLANGFORMAT_ROOT $ENV{CLANGFORMATROOT})
        endif()
    endif()

    set(TRY_FIND_ON_SYTEM FALSE)
    if (NOT TRY_CLANGFORMAT_ROOT)
        set(TRY_FIND_ON_SYTEM TRUE)

        if (CMAKE_CXX_COMPILER_ID MATCHES "MSVC")
            string(FIND ${CMAKE_CXX_COMPILER} "VC/Tools" MSVC_TOOLS_POS)
            if (${MSVC_TOOLS_POS} EQUAL -1)
                string(FIND ${CMAKE_CXX_COMPILER} "VC//Tools" MSVC_TOOLS_POS)
            endif()
            if (${MSVC_TOOLS_POS} EQUAL -1)
                string(FIND ${CMAKE_CXX_COMPILER} "VC\\Tools" MSVC_TOOLS_POS)
            endif()

            if (NOT ${MSVC_TOOLS_POS} EQUAL -1)
                string(SUBSTRING ${CMAKE_CXX_COMPILER} 0 ${MSVC_TOOLS_POS} MSVC_ROOT)
                string(CONCAT ADDITIONAL_CLANGFORMAT_ROOT ${MSVC_ROOT} "VC/Tools/Llvm/bin")
            endif()
        endif()
    else()
        set(ADDITIONAL_CLANGFORMAT_ROOT ${TRY_CLANGFORMAT_ROOT})
    endif()

    unset(CLANGFORMAT_ALL_CANDIDATES)
    find_all_programs(CLANGFORMAT_NAMES ADDITIONAL_CLANGFORMAT_ROOT CLANGFORMAT_ALL_CANDIDATES)
    select_by_version(ClangFormat_FIND_VERSION CLANGFORMAT_ALL_CANDIDATES CLANGFORMAT_EXECUTABLE)
endif()

if (NOT CLANGFORMAT_EXECUTABLE)
    message(FATAL_ERROR "Could NOT find ClangFormat. Try to set veriable CLANGFORMAT_ROOT or exact path CLANGFORMAT_EXECUTABLE.")
endif()

get_version(CLANGFORMAT_EXECUTABLE CLANGFORMAT_VERSION_STRING)
get_filename_component(CLANGFORMAT_ROOT_DIR ${CLANGFORMAT_EXECUTABLE} DIRECTORY)

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(
    ClangFormat
    REQUIRED_VARS CLANGFORMAT_EXECUTABLE CLANGFORMAT_ROOT_DIR
    VERSION_VAR CLANGFORMAT_VERSION_STRING
)

# Force cache variables
set(CLANGFORMAT_EXECUTABLE ${CLANGFORMAT_EXECUTABLE} CACHE PATH "clang-format executable")
set(CLANGFORMAT_ROOT_DIR ${CLANGFORMAT_ROOT_DIR} CACHE PATH "clang-format root directory") 
mark_as_advanced(CLANGFORMAT_ROOT_DIR)


if(CLANGFORMAT_EXECUTABLE)
    set(CLANGFORMAT_FOUND TRUE)
else()
    set(CLANGFORMAT_FOUND FALSE)
endif()
