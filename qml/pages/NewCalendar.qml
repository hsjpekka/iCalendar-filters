import QtQuick 2.0
import Sailfish.Silica 1.0

Dialog {
    id: page
    property string calendarLabel
    property string action: acCreate
    property string url: ""

    readonly property string acCreate: "create"
    readonly property string acDelete: "delete"
    readonly property string acModify: "modify"

    onAccepted: {
        calendarLabel = txtLabel.text
        url = txtOsoite.text
    }

    Column {
        spacing: Theme.paddingLarge
        width: parent.width

        DialogHeader {
            title: action === acCreate? qsTr("Create calendar entry") :
                           action === acDelete? qsTr("Delete calendar entry?") :
                                                qsTr("Modify calendar entry")
        }

        TextField {
            id: txtLabel
            text: action === acCreate? "" : calendarLabel
            placeholderText: qsTr("calendar label")
            label: action === acCreate? qsTr("write exactly as in Jolla Calendar") :
                           qsTr("calendar label")
            readOnly: action === acDelete
            EnterKey.onClicked: {
                //focus = false
                txtOsoite.focus = true
            }
        }

        TextField {
            id: txtOsoite
            width: parent.width
            readOnly: action === acDelete
            text: action === acCreate? "" : url
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

        ComboBox {
            id: cbAction
            label: qsTr("action")
            menu: ContextMenu {
                MenuItem {
                    text: cbAction.strCreate
                }
                MenuItem {
                    text: cbAction.strDelete
                }
                MenuItem {
                    text: cbAction.strModify
                }
            }
            onValueChanged: {
                if (value === strCreate) {
                    action = acCreate
                } else if (value === strDelete) {
                    action = acDelete
                } else {
                    action = acModify
                }
            }

            readonly property string strCreate: qsTr("create")
            readonly property string strDelete: qsTr("delete")
            readonly property string strModify: qsTr("modify")
        }
    }
}
