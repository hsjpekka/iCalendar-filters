import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Pickers 1.0

Dialog {
    id: page
    property string calendarLabel
    property string action
    property string url: ""

    readonly property string acCreate: "create"
    readonly property string acDelete: "delete"
    readonly property string acModify: "modify"

    canAccept: txtLabel.text > "" && txtOsoite.text > ""

    onAccepted: {
        calendarLabel = txtLabel.text
        url = txtOsoite.text
    }

    Component.onCompleted: {
        action = calendarLabel == "" ? acCreate : acModify
        cbAction.setUp()
        if (url > "" && (url.charAt(0) == '/' || url.indexOf("file:") == 0)) {
            remoteOrLocal.checked = false
        }
    }

    Column {
        spacing: Theme.paddingLarge
        width: parent.width

        DialogHeader {
            title: action === acCreate? qsTr("Create calendar entry") :
                           action === acDelete? qsTr("Delete calendar entry?") :
                                                qsTr("Modify calendar entry")
        }

        ComboBox {
            id: cbAction
            label: qsTr("action")
            menu: ContextMenu {
                MenuItem {
                    text: cbAction.strCreate
                }
                MenuItem {
                    text: cbAction.strModify
                }
                MenuItem {
                    text: cbAction.strDelete
                }
            }
            onValueChanged: {
                if (!settingUp) {
                    if (value === strCreate) {
                        action = acCreate
                    } else if (value === strDelete) {
                        action = acDelete
                    } else {
                        action = acModify
                    }
                }
            }

            readonly property string strCreate: qsTr("create")
            readonly property string strDelete: qsTr("delete")
            readonly property string strModify: qsTr("modify")
            property bool settingUp: false

            function setUp() {
                settingUp = true;
                currentIndex = action == acCreate? 0 : 1;
                settingUp = false;
                return;
            }
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

        TextSwitch{
            id: remoteOrLocal
            checked: true
            text: checked? qsTr("remote server") : qsTr("local file")
            visible: !(action == acDelete)
        }

        Component {
            id: filePickerPage
            FilePickerPage {
                nameFilters: [ '*.ics', '*.ical' ]
                onSelectedContentPropertiesChanged: {
                    txtOsoite.text = selectedContentProperties.filePath
                }
            }
        }

        Button {
            text: qsTr("choose file")
            visible: !remoteOrLocal.checked
            anchors.horizontalCenter: parent.horizontalCenter
            onClicked: {
                pageStack.push(filePickerPage)
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
    }
}
