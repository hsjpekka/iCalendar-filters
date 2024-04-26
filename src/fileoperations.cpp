#include "fileoperations.h"
#include <QDebug>
#include <QFile>
#include <QDir>
#include <QTextStream>

fileOperations::fileOperations()
{
//    filePath = QDir().homePath() + "/.config/null.hsjpekka/icalendar-filters/";
    filePath = QDir().homePath() + "/Downloads/";
    fileName = "temporal.ics";
}

bool fileOperations::removeTemporalFile()
{
    QFile file(filePath + fileName);
    return file.remove();
}

QString fileOperations::writeTxt(QString text)
{
    QString result;
    QFile oFile;
    QTextStream output;

    oFile.setFileName(filePath + fileName);
    if (!oFile.open(QIODevice::WriteOnly | QIODevice::Text)) {
        result = "Error in opening ";
        result.append(filePath + fileName);
        qWarning() << "Error in opening the temporary file.";
        return result;
    }

    output.setDevice(&oFile);
    output << text;
    output.flush();
    if (output.status() == QTextStream::Ok) {
        result = filePath + fileName;
    } else {
        result = "Error in writing ";
        result.append(filePath + fileName);
        qWarning() << "Error in writing the temporary file.";
    }
    oFile.close();

    return result;
}
