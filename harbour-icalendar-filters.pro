# NOTICE:
#
# Application name defined in TARGET has a corresponding QML filename.
# If name defined in TARGET is changed, the following needs to be done
# to match new name:
#   - corresponding QML filename must be changed
#   - desktop icon filename must be changed
#   - desktop filename must be changed
#   - icon definition filename in desktop file must be changed
#   - translation filenames have to be changed

# The name of your application
TARGET = harbour-icalendar-filters

CONFIG += sailfishapp

HEADERS += \
    ../buteo-sync-plugin-webcal-filtered/src/icsfilter.h \
    src/fileoperations.h

SOURCES += \
    ../buteo-sync-plugin-webcal-filtered/src/icsfilter.cpp \
    src/fileoperations.cpp \
    src/harbour-icalendar-filters.cpp

DISTFILES += \
    harbour-icalendar-filters.desktop \
    qml/cover/CoverPage.qml \
    qml/harbour-icalendar-filters.qml \
    qml/pages/FilterTest.qml \
    qml/pages/Filters.qml \
    qml/pages/FirstPage.qml \
    qml/components/IcalEventsView.qml \
    qml/utils/globals.js \
    rpm/harbour-icalendar-filters.changes.in \
    rpm/harbour-icalendar-filters.changes.run.in \
    rpm/harbour-icalendar-filters.spec \
    translations/*.ts

SAILFISHAPP_ICONS = 86x86 108x108 128x128 172x172

# to disable building translations every time, comment out the
# following CONFIG line
CONFIG += sailfishapp_i18n

# German translation is enabled as an example. If you aren't
# planning to localize your app, remember to comment out the
# following TRANSLATIONS line. And also do not forget to
# modify the localized app name in the the .desktop file.
TRANSLATIONS += \
    translations/harbour-icalendar-filters-fi.ts
