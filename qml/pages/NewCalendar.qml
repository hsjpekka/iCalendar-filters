import QtQuick 2.0
import Sailfish.Silica 1.0

Dialog {
    id: page
    property string calendarLabel
    property bool create: true
    property string url: ""

    Component.onCompleted: {
        if (create) {
            txtLabel.focus = true
        }
    }

    onAccepted: {
        calendarLabel = txtLabel.text
        url = txtOsoite.text
    }

    Column {
        spacing: Theme.paddingLarge
        width: parent.width

        DialogHeader {
            title: create? qsTr("Create calendar entry") :
                           qsTr("Delete calendar entry?")
        }

        TextField {
            id: txtLabel
            text: calendarLabel
            placeholderText: qsTr("calendar label")
            label: create? qsTr("write exactly as in Jolla Calendar") :
                           qsTr("calendar label")
            readOnly: !create
            EnterKey.onClicked: {
                //focus = false
                txtOsoite.focus = true
            }
        }

        TextField {
            id: txtOsoite
            width: parent.width
            readOnly: !create
            text: create? "" : url
            placeholderText: qsTr("https://address.of.the/calendar")
            label: qsTr("address of the iCalendar-file")
            validator: RegExpValidator {
                regExp: /[^\s]+/ // no spaces or tabs in the url
            }
            EnterKey.onClicked: {
                focus = false
            }

            //property int i: 0
        }

    }


}
