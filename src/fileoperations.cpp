#include "fileoperations.h"
#include <QDebug>
#include <QFile>
#include <QDir>
#include <QTextStream>

fileOperations::fileOperations()
{
    //filePath = QDir().homePath() + "/.config/null.hsjpekka/icalendar-filters/";
    filePath = defaultPath();
    fileName = defaultName;
}

QString fileOperations::defaultPath()
{
    return QDir().homePath() + "/Downloads/";
}

QString fileOperations::error()
{
    return errorStr;
}

QString fileOperations::readTxt()
{
    QString result;
    QFile iFile;
    QTextStream input;

    errorStr = "";
    iFile.setFileName(filePath + fileName);
    if (!iFile.open(QIODevice::ReadOnly | QIODevice::Text)) {
        errorStr = "Error in opening ";
        errorStr.append(filePath + fileName);
        errorStr.append(": ");
        errorStr.append(iFile.errorString());
        qWarning() << errorStr;
        return result;
    }

    input.setDevice(&iFile);
    result = input.readAll();
    if (input.status() != QTextStream::Ok) {
        errorStr = "Error in reading ";
        errorStr.append(filePath + fileName);
        errorStr.append(". Status: ");
        errorStr.append(input.status());
        qWarning() << errorStr;
    }
    iFile.close();

    return result;
}

bool fileOperations::removeFile()
{
    QFile file(filePath + fileName);
    return file.remove();
}

QString fileOperations::setFileName(QString name, QString path)
{
    if (name == "") {
        fileName = defaultName;
        filePath = defaultPath();
    } else {
        fileName = name;
    }
    if (path != "") {
        if (path.at(path.size()-1) != '/') {
            path.append('/');
        }
        if (path.at(0) != '/') {
            filePath = QDir().homePath() + "/" + path;
        } else {
            filePath = path;
        }
    }

    return filePath + fileName;
}

QString fileOperations::writeTxt(QString text)
{
    QString result;
    QFile oFile;
    QTextStream output;

    errorStr = "";
    oFile.setFileName(filePath + fileName);
    if (!oFile.open(QIODevice::WriteOnly | QIODevice::Text)) {
        errorStr = "Error in opening ";
        errorStr.append(filePath + fileName);
        qWarning() << "Error in opening the temporary file.";
        return result;
    }

    output.setDevice(&oFile);
    output << text;
    output.flush();
    if (output.status() == QTextStream::Ok) {
        result = filePath + fileName;
    } else {
        errorStr = "Error in writing ";
        errorStr.append(filePath + fileName);
        qWarning() << "Error in writing the temporary file.";
    }
    oFile.close();

    return result;
}
