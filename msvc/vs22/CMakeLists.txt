cmake_minimum_required(VERSION 3.16.0 FATAL_ERROR)

set(CMAKE_SYSTEM_VERSION 10.0 CACHE STRING "" FORCE)

project(mpir C CXX)

if(MSVC)
	add_custom_target(mpir_cmake ALL
		COMMAND msbuild gc LIB x64 Release > result.testresult
		WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
		COMMENT "Calling: msbuild gc LIB x64 Release"
	)
	
	file(GLOB lib_files ${CMAKE_CURRENT_SOURCE_DIR}/lib_mpir_gc/x64/Release/*.lib)
	install(FILES ${lib_files} DESTINATION ${CMAKE_INSTALL_DIR}/lib)
	file(GLOB lib_files ${CMAKE_CURRENT_SOURCE_DIR}/lib_mpir_gc/x64/Release/*.h)
	install(FILES DESTINATION ${CMAKE_INSTALL_DIR}/include)
else()
	message(FATAL_ERROR "Must use MSVC compiler")
endif()