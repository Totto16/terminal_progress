project(
    'terminal_progress_cpp',
    'cpp',
    license: 'MIT',
    meson_version: '>=1.3.0',
    default_options: {
        'buildtype': 'release',
        'optimization': '3',
        'cpp_std': ['c++23', 'c++2a', 'c++latest', 'c++11'],
        'warning_level': '3',
        'werror': 'true',
        'b_ndebug': 'if-release',
    },
    version: '0.0.1',
)

cpp = meson.get_compiler('cpp')

internal_cpp_args = []

internal_cpp_args += cpp.get_supported_arguments(
    '-Wassign-enum',
    '-Wenum-conversion',
    '-Wenum-switch',
    '-fstrict-enums',
    '-Wenum-identifier',
    '-Wenum-compare',
    '-Wenum-enum-conversion',
    '-Wenum-float-conversion',
    '-Wenum-too-large',
    '-Wenum-compare-switch',
    '-Wenum-compare-conditional',
    '-fno-strict-aliasing',
    '-Wpointer-arith',
    '-Wmissing-declarations',
    '-Wformat=2',
    '-Wstrict-prototypes',
    '-Wmissing-prototypes',
    '-Wnested-externs',
    '-Wold-style-definition',
    '-Wundef',
    '-Wunused',
    '-Wcast-align',
    '-Wmissing-noreturn',
    '-Wmissing-format-attribute',
    '-Wmissing-include-dirs',
    '-Wlogical-op',
    '-Wignored-qualifiers',
    '-Werror=redundant-decls',
    '-Werror=implicit',
    '-Werror=nonnull',
    '-Werror=init-self',
    '-Werror=main',
    '-Werror=missing-braces',
    '-Werror=sequence-point',
    '-Werror=return-type',
    '-Werror=trigraphs',
    '-Werror=array-bounds',
    '-Werror=write-strings',
    '-Werror=address',
    '-Werror=int-to-pointer-cast',
    '-Werror=pointer-to-int-cast',
    '-Werror=empty-body',
    '-Werror=write-strings',
    '-Werror=strict-aliasing',
    '-Wno-sign-compare',
    '-Wno-cast-function-type',
    '-Wno-unused-parameter',
    '-Wno-missing-field-initializers',
    '-Wno-type-limits',
    '-Wshadow',
    '-Wfloat-conversion',
)

lib_src_files = []
cli_files = []
inc_dirs = []
lib_inc_dirs = []


terminal_progress_cpp_lib_version = meson.project_version()

terminal_progress_cpp_lib_header_install_dir = 'terminal_progress_cpp'


subdir('include')
subdir('src')


terminal_progress_cpp_lib = library(
    'terminal_progress_cpp',
    lib_src_files,
    include_directories: inc_dirs,
    cpp_args:  internal_cpp_args,
    install: true,
    version: terminal_progress_cpp_lib_version,
)

pkg = import('pkgconfig')

pkg.generate(
    terminal_progress_cpp_lib,
    description: 'A terminal progress reported library for the OSC command, Written in C++',
    name: 'terminal_progress_cpp',
    filebase: 'terminal_progress_cpp',
    subdirs: [terminal_progress_cpp_lib_header_install_dir],
)

terminal_progress_cpp_dep = declare_dependency(
    link_with: terminal_progress_cpp_lib,
    include_directories: lib_inc_dirs,
    version: terminal_progress_cpp_lib_version,
)

meson.override_dependency('terminal_progress_cpp', terminal_progress_cpp_dep)

executable(
    'example',
    cli_files,
    dependencies: [terminal_progress_cpp_dep],
    install: false,
    cpp_args: [internal_cpp_args],
)

