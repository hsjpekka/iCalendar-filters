import QtQuick 2.0
import Sailfish.Silica 1.0
import "../components"

Page {
    id: page
    Component.onCompleted: {
        viewFiltersFile.nextFile();
    }

    property var filtersObj
    property string calendarLbl
    property string origIcsFile

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

        ListModel {
            id: modelLines

            function addLine(line) {
                append({"txt" : line});
                return count;
            }
        }

        SilicaListView {
            id: viewFiltersFile
            spacing: Theme.paddingSmall
            clip: true
            height: page.height - y
            width: parent.width
            model: modelLines
            delegate: lineDelegate

            VerticalScrollDecorator {}

            Component {
                id: lineDelegate

                Item {
                    height: rowNr.height
                    width: viewFiltersFile.width
                    Label {
                        id: rowNr
                        text: index + " : "
                        //color: Theme.secondaryColor
                        anchors.right: rowTxt.left
                        //font.pixelSize: Theme.fontSizeLarge
                    }
                    Label {
                        id: rowTxt
                        x: Theme.horizontalPageMargin + 2*Theme.fontSizeMedium
                        text: txt
                        //color: Theme.secondaryColor
                    }
                }
            }

            Label {
                text: viewFiltersFile.noContent
                color: Theme.secondaryColor
                visible: modelLines.count < 1
                y: 0.3*parent.height
                width: 0
                anchors.horizontalCenter: parent.horizontalCenter
                horizontalAlignment: TextInput.AlignHCenter
            }

            //*
            MouseArea {
                anchors.fill: parent
                propagateComposedEvents: true
                onClicked: {
                    viewFiltersFile.nextFile()
                }
            } //*/

            readonly property int iOrig: 0
            readonly property int iMod: 2
            readonly property int iFilters: 1

            property int iContent: iOrig - 1
            property int iMax: Math.max(iOrig, iMod, iFilters)

            property string noContent: iContent === iOrig ? qsTr("No iCalendar-file!") : (iContent === iFilters ? qsTr("No filters!"): qsTr("-- no contents --"))

            function nextFile() {
                var txt = "";
                iContent++;
                if (iContent > iMax) {
                    iContent = 0;
                }

                if (iContent === iOrig) {
                    rewrite(origIcsFile);
                } else if (iContent === iFilters){
                    rewrite(JSON.stringify(filtersObj, null, 2));
                } else {
                    rewrite(txt + icsFilter.filterIcs(calendarLbl, origIcsFile, JSON.stringify(filtersObj)));
                }

                return;
            }

            function rewrite(newLines) {
                var i, txtLines;
                modelLines.clear();
                txtLines = newLines.split(/\r?\n|\r|\n/g);
                i = 0;
                while (i < txtLines.length) {
                    modelLines.addLine(txtLines[i]);
                    i++;
                }
                return i;
            }
        }

    }

}
