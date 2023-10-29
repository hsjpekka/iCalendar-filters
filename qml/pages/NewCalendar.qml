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
                focus = false
            }
        }

        TextField {
            id: txtOsoite
            width: parent.width
            enabled: create
            placeholderText: qsTr("https://address.of.the/calendar")
            label: qsTr("address of the iCalendar-file")

            property int i: 0
            property string haaga: "https://haagankarhut.nimenhuuto.com/calendar/ical?auth[user_id]=284538&auth[ver]=02&auth[signature]=71b4f7c43381a8146f954d03d8498af910a9aa93"
            property string arena: "https://warriorbears.nimenhuuto.com/calendar/ical?auth[user_id]=163835&auth[ver]=02&auth[signature]=0874572b168871b055d4eb8fc44a94a85509c667"
        }

        Button {
            text: "vaihda"
            onClicked: {
                if (txtOsoite.i === 0) {
                    txtOsoite.text = txtOsoite.haaga
                    txtOsoite.i++
                } else {
                    txtOsoite.text = txtOsoite.arena
                    txtOsoite.i = 0
                }
            }
        }
    }


}
