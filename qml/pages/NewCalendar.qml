import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Pickers 1.0
import Nemo.Notifications 1.0
import "../utils/globals.js" as Globals


Dialog {
    id: page
    canAccept: txtLabel.text > "" && txtUrl.text > "" && labelOk
    onDone: {
        if (result === DialogResult.Accepted) {
            modifyCalendarList()
        }
    }
    Component.onCompleted: {
        newFilters = JSON.parse(JSON.stringify(oldFilters))
        if (oldLabel === "" || oldLabel === undefined) {
            action = acCreate
        } else {
            action = acModify
            iCal = findCalendarIndex(oldLabel)
        }
        cbAction.setUp()
        if (oldUrl > "" && (oldUrl.charAt(0) == '/' || oldUrl.indexOf("file:") == 0)) {
            remoteOrLocal.checked = false
        }
    }

    property string oldLabel
    property alias newLabel: txtLabel.text
    property string action
    property string oldUrl: ""
    property alias newUrl: txtUrl.text
    property var oldFilters
    property var newFilters // = emptyJson
    property int iCal
    property bool labelOk: true

    readonly property string acCreate: "create"
    readonly property string acDelete: "delete"
    readonly property string acModify: "modify"
    readonly property var emptyJson: JSON.parse(Globals.emptyJson)
    readonly property var emptyCalendar: JSON.parse(Globals.emptyCalendar)

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
            text: action === acCreate? "" : oldLabel
            placeholderText: qsTr("calendar label")
            label: action === acCreate? qsTr("write exactly as in Jolla Calendar") :
                           qsTr("calendar label")
            readOnly: action === acDelete
            EnterKey.onClicked: {
                txtUrl.focus = true
                verifyLabel(txtLabel.text)
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
                    txtUrl.text = selectedContentProperties.filePath
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
            id: txtUrl
            width: parent.width
            readOnly: action === acDelete
            text: action === acCreate? "" : oldUrl
            placeholderText: qsTr("https://address.of.the/calendar")
            label: qsTr("address of the iCalendar-file")
            validator: RegExpValidator {
                regExp: /[^\s]+/ // no spaces or tabs in the oldUrl
            }
            EnterKey.onClicked: {
                focus = false
            }
        }
    }

    function modifyCalendarList() {
        if (action === acCreate) {
            if (verifyLabel(newLabel)) {
                newCalendar(newLabel, newUrl)
            } else {
                message(qsTr("Calendar %1 exists already.").arg(newLabel),
                        qsTr("Not added."))

            }
        } else if (action === acDelete) {
            removeCalendarFromJson()
        } else {
            if (labelOk) {
                modifyCalendar(iCal, newLabel, newUrl)
            }
        }

        return;
    }

    function modifyCalendar(ic, lbl, url) {
        var i, key, record;
        record = emptyCalendar;

        if (ic < 0 || ic > newFilters.calendars.length) {
            message(qsTr("Can't modify calendar."),
                    qsTr("Parameter iCal out of scope, %1.").arg(ic));
            return -1;
        }

        i=0;
        while (i < newFilters.calendars.length) {
            if (i === ic) {
                for (key in newFilters.calendars[i]) {
                    if (key.toLocaleLowerCase() === "url" && url > "") {
                        record.url = url;
                    } else if (key.toLocaleLowerCase() === "label" && lbl > "") {
                        record.label = lbl;
                    } else {
                        record[key] = newFilters.calendars[i][key];
                    }
                }
                newFilters.calendars[i] = record;
            }
            i++;
        }

        return;
    }

    function message(bodyTxt, summaryTxt) {
        note.body = bodyTxt;
        note.summary = summaryTxt;
        return;
    }

    function newCalendar(labelNew, urlNew) {
        var i, k, record, clndr;

        record = emptyCalendar;
        record.label = labelNew;
        record.url = urlNew;

        clndr = emptyJson;

        i = 0;
        while(i < newFilters.calendars.length) {
            clndr.calendars.push(newFilters.calendars[i]);
            i++;
        }
        clndr.calendars.push(record);
        newFilters = JSON.parse(JSON.stringify(clndr));
        k = newFilters.calendars.length;
        iCal = k - 1;

        return k;
    }

    function removeCalendarFromJson() {
        var k, key, djson;
        djson = emptyJson;
        console.log("removing nro", iCal, "calendar", newLabel)
        k = 0;
        while (k < newFilters.calendars.length) {
            if (k !== iCal) {
                djson.calendars.push(newFilters.calendars[k]);
            }
            k++;
        }
        newFilters = JSON.parse(JSON.stringify(djson));
        return newFilters.calendars.length;
    }

    function findCalendarIndex(label) {
        var i, k;
        if (label === undefined || label === "") {
            label = newLabel
        }

        k = -1;
        i = 0;
        while (i < newFilters.calendars.length) {
            if (newFilters.calendars[i].label === label) {
                k = i;
                i = newFilters.calendars.length;
            }
            i++;
        }
        return k;
    }

    function verifyLabel(lbl) {
        var k = findCalendarIndex(lbl);
        if (k >= 0 && k !== iCal) {
            message(qsTr("Calendar label exists."), qsTr("You already have a calendar entry labelled %1.").arg(lbl));
            labelOk = false;
        } else {
            labelOk = true;
        }
        return labelOk;
    }

}
