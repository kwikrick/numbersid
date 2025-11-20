fips_ide_group(source/numbersid)
fips_begin_app(numbersid windowed)
    fips_files(numbersid.c numbersid-ui-impl.cc) 
    if (FIPS_IOS)
        fips_files(ios-info.plist)
    endif()
    fips_deps(ui)
fips_end_app()

# Copy help.txt after build
add_custom_command(TARGET numbersid POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy_directory
        ${CMAKE_SOURCE_DIR}/help
        $<TARGET_FILE_DIR:numbersid>/help
)