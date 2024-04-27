import QtQuick 2.0
import Sailfish.Silica 1.0

CoverBackground {
    Label {
        id: label
        anchors {
            horizontalCenter: parent.horizontalCenter
            bottom: image.top
            bottomMargin: Theme.paddingMedium
        }

        text: "iCalendar Filters"
    }

    Image {
        id: image
        anchors.centerIn: parent
        width: 0.5*parent.width
        height: width
        source: "harbour-icalendar-filters.png"
        fillMode: Image.Stretch
        z: -1
    }
    /*
    CoverActionList {
        id: coverAction

        CoverAction {
            iconSource: "image://theme/icon-cover-next"
        }

        CoverAction {
            iconSource: "image://theme/icon-cover-pause"
        }
    } //*/
}
