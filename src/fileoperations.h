#ifndef FILEOPERATIONS_H
#define FILEOPERATIONS_H
#include <QObject>
#include <QDir>

class fileOperations: public QObject
{
    Q_OBJECT
public:
    fileOperations();
    Q_INVOKABLE QString error();
    Q_INVOKABLE QString readTxt();
    Q_INVOKABLE QString writeTxt(QString text);
    Q_INVOKABLE bool removeFile();
    Q_INVOKABLE QString setFileName(QString name = "", QString path = "");

private:
    QString errorStr, filePath, fileName;
    const QString defaultName = "temporal.ics";
    QString defaultPath();
};

#endif // FILEOPERATIONS_H
