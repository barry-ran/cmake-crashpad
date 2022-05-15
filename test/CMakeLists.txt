cmake_minimum_required(VERSION 3.5)

project(test LANGUAGES CXX)

set(CMAKE_INCLUDE_CURRENT_DIR ON)

set(CMAKE_AUTOUIC ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# QtCreator supports the following variables for Android, which are identical to qmake Android variables.
# Check https://doc.qt.io/qt/deployment-android.html for more information.
# They need to be set before the find_package( ...) calls below.

#if(ANDROID)
#    set(ANDROID_PACKAGE_SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/android")
#    if (ANDROID_ABI STREQUAL "armeabi-v7a")
#        set(ANDROID_EXTRA_LIBS
#            ${CMAKE_CURRENT_SOURCE_DIR}/path/to/libcrypto.so
#            ${CMAKE_CURRENT_SOURCE_DIR}/path/to/libssl.so)
#    endif()
#endif()

find_package(QT NAMES Qt6 Qt5 COMPONENTS Widgets REQUIRED)
find_package(Qt${QT_VERSION_MAJOR} COMPONENTS Widgets REQUIRED)

set(PROJECT_SOURCES
        main.cpp
        widget.cpp
        widget.h
        widget.ui
)

if(${QT_VERSION_MAJOR} GREATER_EQUAL 6)
    qt_add_executable(test
        ${PROJECT_SOURCES}
    )
else()
    if(ANDROID)
        add_library(test SHARED
            ${PROJECT_SOURCES}
        )
    else()
        add_executable(test
            ${PROJECT_SOURCES}
        )
    endif()
endif()

target_link_libraries(test PRIVATE Qt${QT_VERSION_MAJOR}::Widgets)

# crashpad
target_include_directories(test PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/../crashpad/include)
target_include_directories(test PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/../crashpad/include/third_party/mini_chromium/mini_chromium)
target_link_directories(test PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/../crashpad/lib)

if(CMAKE_SYSTEM_NAME STREQUAL "Windows")
    target_link_libraries(test PRIVATE
        $<$<CONFIG:Debug>:clientd>
        $<$<CONFIG:Debug>:based>
        $<$<CONFIG:Debug>:utild>

        $<$<NOT:$<CONFIG:Debug>>:client>
        $<$<NOT:$<CONFIG:Debug>>:base>
        $<$<NOT:$<CONFIG:Debug>>:util>
    )

    get_target_property(CRASH_HANDLER_OUTPUT_PATH test RUNTIME_OUTPUT_DIRECTORY)
    add_custom_command(TARGET test POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_if_different "${CMAKE_CURRENT_SOURCE_DIR}/../crashpad/bin/crashpad_handler.exe" $<TARGET_FILE_DIR:test>
    )
endif()
