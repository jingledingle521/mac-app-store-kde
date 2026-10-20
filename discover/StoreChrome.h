/*
    SPDX-FileCopyrightText: 2026 Brhett

    SPDX-License-Identifier: GPL-2.0-or-later
*/

#pragma once

#include <QObject>
#include <QPointer>
#include <QQuickWindow>
#include <QRegion>

class KWindowShadow;

/**
 * App Store: macOS's App Store window. No title bar: a rounded, shadowed
 * window whose glass sidebar runs to the top (the stoplights are drawn by
 * the sidebar's QML), with KWin blurring behind the sidebar. Moved from
 * empty space at the top (startMove), resized from its edges. The window's
 * QML paints the content and the sidebar's tint (sidebarColor) inside the
 * rounded corners (radius).
 */
class StoreChrome : public QObject
{
    Q_OBJECT

    Q_PROPERTY(QQuickWindow *window READ window WRITE setWindow NOTIFY windowChanged)
    Q_PROPERTY(qreal sidebarWidth READ sidebarWidth WRITE setSidebarWidth NOTIFY sidebarWidthChanged)
    Q_PROPERTY(bool maximized READ isMaximized NOTIFY maximizedChanged)
    Q_PROPERTY(bool active READ isActive NOTIFY activeChanged)
    Q_PROPERTY(int radius READ radius NOTIFY maximizedChanged)
    Q_PROPERTY(QColor sidebarColor READ sidebarColor CONSTANT)

public:
    explicit StoreChrome(QObject *parent = nullptr);
    ~StoreChrome() override;

    QQuickWindow *window() const;
    void setWindow(QQuickWindow *window);
    qreal sidebarWidth() const;
    void setSidebarWidth(qreal width);
    bool isMaximized() const;
    bool isActive() const;
    int radius() const;
    QColor sidebarColor() const;

    Q_INVOKABLE void startMove();
    Q_INVOKABLE void toggleMaximized();
    Q_INVOKABLE void minimize();
    Q_INVOKABLE void close();

    /** MAC_TEST_TOUR=<dir>: MacTour visits the pages and saves a picture
     *  of each (snap) in <dir>, then quits. Empty when not touring. */
    Q_INVOKABLE QString testTour() const;
    /** MAC_TEST_TOUR_ONLY=<pictures,…>: just these (as named by the tour). */
    Q_INVOKABLE QStringList testTourOnly() const;
    Q_INVOKABLE void snap(const QString &name);

Q_SIGNALS:
    void windowChanged();
    void sidebarWidthChanged();
    void maximizedChanged();
    void activeChanged();

protected:
    bool eventFilter(QObject *watched, QEvent *event) override;

private:
    Qt::Edges edgesAt(const QPointF &pos) const;
    void updateBlur();
    void updateShadow();

    QPointer<QQuickWindow> m_window;
    qreal m_sidebarWidth = 0;
    KWindowShadow *m_shadow = nullptr;
    Qt::Edges m_cursorEdges;
    QRegion m_appliedBlur;
    bool m_blurApplied = false;
    bool m_surfaceReady = false;
};
