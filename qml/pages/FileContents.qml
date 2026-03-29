import QtQuick 2.0
import Sailfish.Silica 1.0
import "../components"


Page {
    id: page

    property var filtersObj
    property string calendarLbl
    property string origIcsFile

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        Column {
            id: column
            width: parent.width

            PageHeader {
                title: qsTr("%1-files").arg(calendarLbl)
            }

            SectionHeader{
                text: viewFiltersFile.iContent === 0 ? h1
                      : (viewFiltersFile.iContent === 1 ? h2 : h3)
                textFormat: Text.StyledText

                property string txt1: qsTr("original")
                property string txt2: qsTr("filter")
                property string txt3: qsTr("modified")
                property string h1: "<b>" + txt1 + "</b> &nbsp; | &nbsp; <i>" + txt2 + "</i> &nbsp; | &nbsp; <i>" + txt3 + "</i>"
                property string h2: "<i>" + txt1 + "</i> &nbsp; | &nbsp; <b>" + txt2 + "</b> &nbsp; | &nbsp; <i>" + txt3 + "</i>"
                property string h3: "<i>" + txt1 + "</i> &nbsp; | &nbsp; <i>" + txt2 + "</i> &nbsp; | &nbsp; <b>" + txt3 + "</b>"

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        viewFiltersFile.nextFile()
                    }
                }
            }

            TextArea {
                id: viewFiltersFile
                width: parent.width
                font.pixelSize: Theme.fontSizeMedium
                readOnly: true
                text: origIcsFile
                placeholderText: noContent
                onClicked: {
                    nextFile()
                }

                readonly property int iOrig: 0
                readonly property int iMod: 2
                readonly property int iFilters: 1

                property int iContent: 0
                property int iMax: Math.max(iOrig, iMod, iFilters)

                property string noContent: iContent === iOrig ? qsTr("No iCalendar-file!") : (iContent === iFilters ? qsTr("No filters!"): qsTr("-- no contents --"))

                function nextFile() {
                    iContent++;
                    reWrite();
                    if (iContent > iMax) {
                        iContent = 0;
                    }
                    return;
                }

                function reWrite(i) {
                    var iSheet;
                    if (i >= 0 && i <= iMax) {
                        iSheet = i;
                        iContent = i;
                    } else {
                        iSheet = iContent;
                    }

                    if (iSheet === iOrig) {
                        text = origIcsFile;
                    } else if (iSheet === iFilters){
                        //composeFilter();
                        text = JSON.stringify(filtersObj, null, 2);
                    } else {
                        text = icsFilter.filterIcs(calendarLbl, origIcsFile, JSON.stringify(filtersObj));
                    }

                    return;
                }
            }

        }

        VerticalScrollDecorator {}
    }
}
