cmake_minimum_required(VERSION 3.14)

project(commonqt LANGUAGES CXX)

set(CMAKE_INCLUDE_CURRENT_DIR OFF)
set(CMAKE_AUTOMOC OFF)
set(CMAKE_CXX_STANDARD 14)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(QT NAMES Qt6 Qt5 COMPONENTS Core REQUIRED)
find_package(Qt${QT_VERSION_MAJOR} 
    COMPONENTS
    Gui
    Widgets	
    REQUIRED
)
find_package(Qt${QT_VERSION_MAJOR}PrintSupport REQUIRED)
find_package(Smoke REQUIRED )

if (${QT_VERSION_MAJOR} EQUAL 5)
   include_directories(${CMAKE_PREFIX_PATH}/include/QtCore/${Qt5Core_VERSION} 
          ${CMAKE_PREFIX_PATH}/include/QtCore/${Qt5Core_VERSION}/QtCore 
	  ${SMOKE_LIB}/include)
elseif (${QT_VERSION_MAJOR} EQUAL 6) 
   include_directories(${CMAKE_PREFIX_PATH}/include/QtCore/${Qt6Core_VERSION} 
          ${CMAKE_PREFIX_PATH}/include/QtCore/${Qt6Core_VERSION}/QtCore 
	  ${SMOKE_LIB}/include)
endif()

link_directories(${SMOKE_LIB}/lib)

add_library(commonqt SHARED commonqt.cpp)

target_link_libraries(commonqt smokeqtcore smokebase Qt${QT_VERSION_MAJOR}::Widgets Qt${QT_VERSION_MAJOR}::PrintSupport)

install( TARGETS commonqt RUNTIME DESTINATION ${CMAKE_INSTALL_PREFIX}/bin) 

			
			
	