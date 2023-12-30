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
TARGET = harbour-webcal-filters

CONFIG += sailfishapp

HEADERS += \
    ../buteo-sync-plugin-webcal-filtered/src/icsfilter.h

SOURCES += src/harbour-webcal-filters.cpp \
    ../buteo-sync-plugin-webcal-filtered/src/icsfilter.cpp

DISTFILES += qml/harbour-webcal-filters.qml \
    qml/cover/CoverPage.qml \
    qml/pages/FilterTest.qml \
    qml/pages/Filters.qml \
    qml/pages/FirstPage.qml \
    qml/components/IcalEventsView.qml \
    rpm/harbour-webcal-filters.changes.in \
    rpm/harbour-webcal-filters.changes.run.in \
    rpm/harbour-webcal-filters.spec \
    translations/*.ts \
    harbour-webcal-filters.desktop

SAILFISHAPP_ICONS = 86x86 108x108 128x128 172x172

# to disable building translations every time, comment out the
# following CONFIG line
CONFIG += sailfishapp_i18n

# German translation is enabled as an example. If you aren't
# planning to localize your app, remember to comment out the
# following TRANSLATIONS line. And also do not forget to
# modify the localized app name in the the .desktop file.
TRANSLATIONS += translations/harbour-webcal-filters-de.ts \
    translations/harbour-webcal-filters-fi.ts
