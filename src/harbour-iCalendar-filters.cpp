#ifdef QT_QML_DEBUG
#include <QtQuick>
#endif

#include <sailfishapp.h>
#include <QGuiApplication>
#include <QScopedPointer>
#include <QQuickView>
#include <QQmlEngine>
#include <QQmlContext>

#include "../buteo-sync-plugin-webcal-filtered/src/icsfilter.h"

int main(int argc, char *argv[])
{
    // SailfishApp::main() will display "qml/harbour-webcal-filters.qml", if you need more
    // control over initialization, you can use:
    //
    //   - SailfishApp::application(int, char *[]) to get the QGuiApplication *
    //   - SailfishApp::createView() to get a new QQuickView * instance
    //   - SailfishApp::pathTo(QString) to get a QUrl to a resource file
    //   - SailfishApp::pathToMainQml() to get a QUrl to the main QML file
    //
    // To display the view, call "show()" (will show fullscreen on device).
    QScopedPointer<QGuiApplication> app(SailfishApp::application(argc, argv));
    QScopedPointer<QQuickView> view(SailfishApp::createView());
    icsFilter filter;

    view->engine()->rootContext()->setContextProperty("icsFilter", &filter);

    view->setSource(SailfishApp::pathToMainQml());
    view->show();

    return app->exec();
}
