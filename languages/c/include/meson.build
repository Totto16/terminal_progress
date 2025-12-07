
lib_src_files += files('terminal_progress.h')

lib_inc_dirs += include_directories('.')
inc_dirs  += include_directories('.')

include_dir = get_option('prefix') / get_option('includedir')

install_include_dir = include_dir / terminal_progress_lib_header_install_dir

install_headers(
    files('terminal_progress.h'),
    install_dir: install_include_dir,
    preserve_path: true,
)
