/*#ifndef SQLQUERYMODEL_H
#define SQLQUERYMODEL_H
#include <QSqlQuery>
#include <QSqlQueryModel>
#include <QSqlRecord>

class SqlQueryModel : public QSqlQueryModel
{
    Q_OBJECT
    Q_PROPERTY(QString query READ queryStr WRITE setQueryStr NOTIFY queryStrChanged)
    Q_PROPERTY(QStringList userRoleNames READ userRoleNames CONSTANT)
public:
    using QSqlQueryModel::QSqlQueryModel;

    QHash<int, QByteArray> roleNames() const
    {
       QHash<int, QByteArray> roles;
       for (int i = 0; i < record().count(); i ++) {
           roles.insert(Qt::UserRole + i + 1, record().fieldName(i).toUtf8());
       }
       return roles;
   }
    QVariant data(const QModelIndex &index, int role) const
    {
        QVariant value;
        if (index.isValid()) {
            if (role < Qt::UserRole) {
                value = QSqlQueryModel::data(index, role);
            } else {
                int columnIdx = role - Qt::UserRole - 1;
                QModelIndex modelIndex = this->index(index.row(), columnIdx);
                value = QSqlQueryModel::data(modelIndex, Qt::DisplayRole);
            }
        }
        return value;
    }
    QString queryStr() const{
        return query().lastQuery();
    }
    void setQueryStr(const QString &query){
        if(queryStr() == query)
            return;
        setQuery(query);
        emit queryStrChanged();
    }
    QStringList userRoleNames() const {
        QStringList names;
        for (int i = 0; i < record().count(); i ++) {
            names << record().fieldName(i).toUtf8();
        }
        return names;
    }
signals:
    void queryStrChanged();
};
#endif // SQLQUERYMODEL_H
*/


// manage driver.qml

import QtQuick 2.0
import QtQuick.Controls 2.0
import QtQuick.Controls 1.4 as QC
import QtQuick.Controls.Styles 1.0
import SQL 1.0
Page {
     anchors.fill: parent
     header:ToolBar{
         anchors.left: parent.left
             anchors.right: parent.right
             height: 70
          background:Rectangle{
          color:"white"
          height:70
          width:parent.width
          }
            Row{
                y:20
          Image {
              id: managebus
              source: "icon/driver_48px.png"
              width: 50
              height: 50
          }

          Text{
          text: "Manage Drivers"
          font.bold: true
          font.pointSize: 11
          y:15



          }

            }
            Button {
                y:10
                  text: "+ Add Driver"
                  anchors.right: parent.right
                  anchors.margins: 60

                  id:managedriverbtn
                  onClicked:
                  {
                  loader.source ="AddDriver.qml"
                  }
                  contentItem: Text {
                      text:managedriverbtn.text
                      font.pointSize: 13
                      opacity: enabled ? 1.0 : 0.3
                      color:managedriverbtn.down ? "#090707" : "#ffffff"
                      horizontalAlignment: Text.AlignHCenter
                      verticalAlignment: Text.AlignVCenter
                      elide: Text.ElideRight
                  }


                  background: Rectangle {
                      color: "#1f54e8"
                      implicitWidth: 100
                      implicitHeight: 40
                      opacity: enabled ? 1 : 0.3
                      border.color:managedriverbtn.down ? "#17a81a" : "#3a64f9"
                      border.width: 1
                      radius: 6
                  }
              }



     }
     Column{
         anchors.fill: parent
      Row{

            anchors.margins: 60

            y:100
            anchors.right: parent.right
            anchors.leftMargin: 60
            spacing: 10
            Image {
                y:5
                id: searchicon
                source: "icon/search_500px.png"
                width: 35
                height: 35
            }

            TextField {
                id: searchField
                placeholderText: "Search"
                implicitWidth: 400
                color: "black"
                font.pointSize: 13
                validator: RegExpValidator {}
                background: Rectangle {
                    implicitWidth: 150
                    implicitHeight: 40
                    radius: 4
                    border.color: "black"
            }
                onAccepted: {
                    // Call the search function from the Database class
                            var model = "select * from driver where fname='%1'".arg(text)

                             sqlmodel.query = model; // Set the model to the search results
                }
           }

            // Refresh button to the right
                        Image {
                            id: refreshicon
                            source: "icon/refreshblack_60px.png"
                            width: 35
                            height: 35
                            MouseArea{
                                anchors.fill: parent
                            onClicked: {
                                // Call refresh functionality here
                                sqlmodel.query = "select * from driver"; // Example query for refreshing data
                            }
                            }
                        }
     }
         Rectangle{
             height: parent.height
             color: "#d5d5cf"
             width: parent.width
             SqlQueryModel{
                         id: sqlmodel
                         query: "select * from driver"
                     }
                     Component{
                         id: columnComponent
                         QC.TableViewColumn {width: 100 }
                     }
             QC.TableView {
                 id: tableView
                 width: parent.width
                 height: parent.height-55
                 anchors.margins: 20

                 resources:{
                     var roleList = sqlmodel.userRoleNames
                     var temp = []
                     for(var i in roleList){
                         var role  = roleList[i]
                         temp.push(columnComponent.createObject(tableView, { "role": role, "title": role}))
                     }
                     return temp
                 }

                 model: sqlmodel
             }
         }
     }

}
