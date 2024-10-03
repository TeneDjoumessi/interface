#ifndef SQLQUERYMODEL_H
#define SQLQUERYMODEL_H

#include <QSqlQuery>
#include <QSqlQueryModel>
#include <QSqlRecord>
#include <QSqlError>
#include <QDebug>
#include <QSqlDatabase>

class SqlQueryModel : public QSqlQueryModel
{
    Q_OBJECT
    Q_PROPERTY(QString query READ queryStr WRITE setQueryStr NOTIFY queryStrChanged)
    Q_PROPERTY(QStringList userRoleNames READ userRoleNames CONSTANT)

public:
    explicit SqlQueryModel(QObject *parent = nullptr)
        : QSqlQueryModel(parent) {}

    QHash<int, QByteArray> roleNames() const override
    {
       QHash<int, QByteArray> roles;
       for (int i = 0; i < record().count(); i ++) {
           roles.insert(Qt::UserRole + i + 1, record().fieldName(i).toUtf8());
       }
       return roles;
    }

    QVariant data(const QModelIndex &index, int role) const override
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

    bool setData(const QModelIndex &index, const QVariant &value, int role) override
    {
        if (role < Qt::UserRole)
            return false;

        int column = role - Qt::UserRole - 1;
        QModelIndex modelIndex = createIndex(index.row(), column);

        int id = data(createIndex(index.row(), 0), Qt::DisplayRole).toInt();
        QString columnName = record().fieldName(column);

        QSqlDatabase::database().transaction();

        QSqlQuery query;
        query.prepare(QString("UPDATE driver SET %1 = :value WHERE id = :id").arg(columnName));
        query.bindValue(":value", value);
        query.bindValue(":id", id);

        if (query.exec()) {
            if (QSqlDatabase::database().commit()) {
                emit dataChanged(modelIndex, modelIndex);
                refresh();
                qDebug() << "Update successful for id:" << id << "column:" << columnName << "new value:" << value;
                return true;
            } else {
                QSqlDatabase::database().rollback();
                qDebug() << "Commit failed:" << QSqlDatabase::database().lastError().text();
                return false;
            }
        } else {
            QSqlDatabase::database().rollback();
            qDebug() << "Update failed:" << query.lastError().text();
            qDebug() << "Query:" << query.lastQuery();
            qDebug() << "Bound values:" << query.boundValues();
            return false;
        }
    }

    Qt::ItemFlags flags(const QModelIndex &index) const override
    {
        return QSqlQueryModel::flags(index) | Qt::ItemIsEditable;
    }

    QString queryStr() const {
        return query().lastQuery();
    }

    void setQueryStr(const QString &query) {
        if (queryStr() == query)
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

    void refresh() {
        this->setQuery(this->query().lastQuery());
        emit dataChanged(index(0, 0), index(rowCount() - 1, columnCount() - 1));
    }

signals:
    void queryStrChanged();
};

#endif // SQLQUERYMODEL_H
