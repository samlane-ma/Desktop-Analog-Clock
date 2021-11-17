configurationData = configuration_data()
configurationData.set('PACKAGE_NAME', meson.project_name())
configurationData.set('LOCALE_DIR', LOCALE_DIR)

install_data('DesktopClock.plugin', install_dir: LIB_INSTALL_DIR)

DesktopClockSources = [
'desktop-analog-clock.vala',
]

DesktopClockDependencies = [
dependency('gtk+-3.0', version: '>=3.18'), 
dependency('budgie-1.0', version: '>=2'),
dependency('gdk-3.0'),
dependency('libpeas-gtk-1.0'),
meson.get_compiler('c').find_library('m', required: false)
]

DesktopClockValaArgs = [
'--target-glib=2.38', 
'--enable-deprecated'
]

shared_library('desktop-analog-clock', DesktopClockSources, dependencies: DesktopClockDependencies, vala_args: DesktopClockValaArgs, install: true, install_dir: LIB_INSTALL_DIR)

DesktopClockExecutableSources = [
'desktop-clock.vala'
]

DesktopClockExecutableDependencies = [
dependency('gtk+-3.0'),
meson.get_compiler('c').find_library('m', required: false)
]

DesktopClockExecutableValaArgs = [
'--target-glib=2.38',
]

DesktopClockExecutableCArgs = [
'-lm',
]

executable(
    'desktop-clock', DesktopClockExecutableSources,
    dependencies: DesktopClockExecutableDependencies,
    install: true,
    vala_args: DesktopClockExecutableValaArgs,
    c_args: DesktopClockExecutableCArgs,
    install_dir: LIB_INSTALL_DIR,
)
