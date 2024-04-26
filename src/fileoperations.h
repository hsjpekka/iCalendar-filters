#ifndef FILEOPERATIONS_H
#define FILEOPERATIONS_H
#include <QObject>

class fileOperations: public QObject
{
    Q_OBJECT
public:
    fileOperations();
    Q_INVOKABLE QString writeTxt(QString text);
    Q_INVOKABLE bool removeTemporalFile();

private:
    QString filePath, fileName;
};

#endif // FILEOPERATIONS_H
