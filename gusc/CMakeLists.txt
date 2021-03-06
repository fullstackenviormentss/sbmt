cmake_minimum_required(VERSION 2.8)

project(gusc)

find_package(Boost REQUIRED COMPONENTS system filesystem thread program_options)

include_directories(. ${Boost_INCLUDE_DIRS})

add_library( gusc 
             lib/ast.cpp 
             lib/create_directories.cpp 
             lib/filesystem_io.cpp 
             lib/lattice_c.cpp )
target_link_libraries(gusc ${Boost_SYSTEM_LIBRARY} ${Boost_FILESYSTEM_LIBRARY} ${Boost_THREAD_LIBRARY})
target_include_directories(gusc PUBLIC ../gusc)

install(TARGETS gusc DESTINATION lib)

add_executable(fuzzycube apps/fuzzycube.cpp)
target_link_libraries(fuzzycube gusc)

add_executable(makedirs apps/makedirs.cpp)
target_link_libraries(makedirs gusc ${Boost_SYSTEM_LIBRARY} ${Boost_FILESYSTEM_LIBRARY})

add_executable(digits apps/digits.cpp)
target_link_libraries(digits gusc ${Boost_PROGRAM_OPTIONS_LIBRARY})

install(TARGETS fuzzycube digits makedirs DESTINATION bin)

