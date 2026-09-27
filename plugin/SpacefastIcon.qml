import QtQuick
import QtQuick.Shapes
import qs.Commons

// The Spacefast "SF" mark, drawn natively from the paths in the favicon at
// https://my.spacefast.com/favicon.svg. The letters follow the bar's
// foreground color like every other bar icon. The offset shadow keeps the
// brand's lime unless `accent` is turned off.
Item {
  id: root

  property real iconSize: Style.font.icon
  property color color: Color.foreground
  property color accentColor: "#d8f24b"
  property bool accent: true

  implicitWidth: iconSize
  implicitHeight: iconSize

  // Letter box in favicon units: S is 24 wide, F starts at 31 and is 25 wide,
  // both 34 tall. The shadow sits 5/2.15 units down and right.
  readonly property real shadowOffset: 5 / 2.15
  readonly property real unitsWide: 56 + shadowOffset
  readonly property real unitsTall: 34 + shadowOffset
  readonly property real k: Math.min(width / unitsWide, height / unitsTall)

  Item {
    anchors.centerIn: parent
    width: root.unitsWide * root.k
    height: root.unitsTall * root.k
    rotation: -1

    Letters {
      visible: root.accent
      x: root.shadowOffset * root.k
      y: root.shadowOffset * root.k
      fill: root.accentColor
    }

    Letters {
      x: 0
      y: 0
      fill: root.color
    }
  }

  component Letters: Shape {
    id: letters
    property color fill
    width: 56 * root.k
    height: 34 * root.k
    preferredRendererType: Shape.CurveRenderer

    ShapePath {
      fillColor: letters.fill
      strokeWidth: -1
      scale: Qt.size(root.k, root.k)
      PathSvg { path: "M0 0h24v7H7v7h17v20H0v-7h17v-7H0V0Z" }
    }

    ShapePath {
      fillColor: letters.fill
      strokeWidth: -1
      scale: Qt.size(root.k, root.k)
      PathSvg { path: "M31 0h25v7H38v6h15v7H38v14H31V0Z" }
    }
  }
}
