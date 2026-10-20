/*
    SPDX-FileCopyrightText: 2026 Brhett

    SPDX-License-Identifier: GPL-2.0-or-later
*/

#include "StoreChrome.h"

#include <KWindowEffects>
#include <KWindowShadow>

#include <QGuiApplication>
#include <QMouseEvent>
#include <QPainter>
#include <QPainterPath>
#include <QTimer>
#include <QtMath>

#include <algorithm>
#include <vector>

// Window frame shared with Finder and Settings (FinderChrome, SettingsChrome).

namespace
{
constexpr int WindowRadius = 12; // macOS window corner radius
constexpr int ResizeBorder = 6; // grab zone along the edges, inside the window
constexpr int ShadowSize = 32; // how far the shadow reaches outside the window

// Box-blurs the alpha channel of a premultiplied ARGB image (three passes of
// a box blur approximate a Gaussian).
void blurAlpha(QImage &image, int radius)
{
    const int w = image.width();
    const int h = image.height();
    std::vector<int> alpha(w * h);
    for (int y = 0; y < h; ++y) {
        const QRgb *line = reinterpret_cast<const QRgb *>(image.constScanLine(y));
        for (int x = 0; x < w; ++x) {
            alpha[y * w + x] = qAlpha(line[x]);
        }
    }
    std::vector<int> tmp(w * h);
    auto pass = [&](bool horizontal) {
        const int len = horizontal ? w : h;
        const int lines = horizontal ? h : w;
        for (int l = 0; l < lines; ++l) {
            auto at = [&](int i) -> int & {
                return horizontal ? alpha[l * w + i] : alpha[i * w + l];
            };
            auto out = [&](int i) -> int & {
                return horizontal ? tmp[l * w + i] : tmp[i * w + l];
            };
            int sum = 0;
            for (int i = -radius; i <= radius; ++i) {
                sum += at(std::clamp(i, 0, len - 1));
            }
            for (int i = 0; i < len; ++i) {
                out(i) = sum / (2 * radius + 1);
                sum += at(std::clamp(i + radius + 1, 0, len - 1)) - at(std::clamp(i - radius, 0, len - 1));
            }
        }
        alpha.swap(tmp);
    };
    for (int i = 0; i < 3; ++i) {
        pass(true);
        pass(false);
    }
    for (int y = 0; y < h; ++y) {
        QRgb *line = reinterpret_cast<QRgb *>(image.scanLine(y));
        for (int x = 0; x < w; ++x) {
            line[x] = qRgba(0, 0, 0, alpha[y * w + x]);
        }
    }
}

QPainterPath roundedPath(const QRectF &rect, qreal radius)
{
    QPainterPath path;
    path.addRoundedRect(rect, radius, radius);
    return path;
}

Qt::CursorShape cursorFor(Qt::Edges edges)
{
    if (edges == (Qt::TopEdge | Qt::LeftEdge) || edges == (Qt::BottomEdge | Qt::RightEdge)) {
        return Qt::SizeFDiagCursor;
    }
    if (edges == (Qt::TopEdge | Qt::RightEdge) || edges == (Qt::BottomEdge | Qt::LeftEdge)) {
        return Qt::SizeBDiagCursor;
    }
    if (edges & (Qt::LeftEdge | Qt::RightEdge)) {
        return Qt::SizeHorCursor;
    }
    return Qt::SizeVerCursor;
}
}

StoreChrome::StoreChrome(QObject *parent)
    : QObject(parent)
{
}

StoreChrome::~StoreChrome() = default;

QQuickWindow *StoreChrome::window() const
{
    return m_window;
}

void StoreChrome::setWindow(QQuickWindow *window)
{
    if (m_window == window) {
        return;
    }
    if (m_window) {
        m_window->removeEventFilter(this);
    }
    m_window = window;
    if (window) {
        window->setFlag(Qt::FramelessWindowHint, true);
        window->setColor(Qt::transparent);
        window->installEventFilter(this);
        connect(window, &QWindow::windowStateChanged, this, [this] {
            updateBlur();
            updateShadow();
            Q_EMIT maximizedChanged();
        });
        connect(window, &QWindow::activeChanged, this, &StoreChrome::activeChanged);
        connect(window, &QWindow::widthChanged, this, &StoreChrome::updateBlur);
        connect(window, &QWindow::heightChanged, this, &StoreChrome::updateBlur);
    }
    Q_EMIT windowChanged();
}

qreal StoreChrome::sidebarWidth() const
{
    return m_sidebarWidth;
}

void StoreChrome::setSidebarWidth(qreal width)
{
    if (qFuzzyCompare(m_sidebarWidth, width)) {
        return;
    }
    m_sidebarWidth = width;
    updateBlur();
    Q_EMIT sidebarWidthChanged();
}

bool StoreChrome::isMaximized() const
{
    return m_window && (m_window->windowStates() & (Qt::WindowMaximized | Qt::WindowFullScreen));
}

bool StoreChrome::isActive() const
{
    return m_window && m_window->isActive();
}

int StoreChrome::radius() const
{
    return isMaximized() ? 0 : WindowRadius;
}

QColor StoreChrome::sidebarColor() const
{
    // As Settings': light text sits on it over any wallpaper.
    return QColor(36, 36, 40, 215);
}

void StoreChrome::startMove()
{
    if (m_window) {
        m_window->startSystemMove();
    }
}

void StoreChrome::toggleMaximized()
{
    if (m_window) {
        isMaximized() ? m_window->showNormal() : m_window->showMaximized();
    }
}

void StoreChrome::minimize()
{
    if (m_window) {
        m_window->showMinimized();
    }
}

void StoreChrome::close()
{
    if (m_window) {
        m_window->close();
    }
}

Qt::Edges StoreChrome::edgesAt(const QPointF &pos) const
{
    Qt::Edges edges;
    if (!m_window || isMaximized()) {
        return edges;
    }
    const int corner = WindowRadius;
    const qreal w = m_window->width();
    const qreal h = m_window->height();
    if (pos.x() < ResizeBorder) {
        edges |= Qt::LeftEdge;
    } else if (pos.x() > w - ResizeBorder) {
        edges |= Qt::RightEdge;
    }
    if (pos.y() < ResizeBorder) {
        edges |= Qt::TopEdge;
    } else if (pos.y() > h - ResizeBorder) {
        edges |= Qt::BottomEdge;
    }
    // Generous diagonal grab near the corners.
    if (edges == Qt::LeftEdge || edges == Qt::RightEdge) {
        if (pos.y() < corner) {
            edges |= Qt::TopEdge;
        } else if (pos.y() > h - corner) {
            edges |= Qt::BottomEdge;
        }
    } else if (edges == Qt::TopEdge || edges == Qt::BottomEdge) {
        if (pos.x() < corner) {
            edges |= Qt::LeftEdge;
        } else if (pos.x() > w - corner) {
            edges |= Qt::RightEdge;
        }
    }
    return edges;
}

bool StoreChrome::eventFilter(QObject *watched, QEvent *event)
{
    if (watched != m_window) {
        return false;
    }
    switch (event->type()) {
    case QEvent::PlatformSurface:
        // A new native surface has none of our effects yet.
        m_surfaceReady = false;
        m_appliedBlur = QRegion();
        m_blurApplied = false;
        break;
    case QEvent::Expose:
        // The Wayland surface exists only once the window is exposed; apply
        // the effects then, once per surface.
        if (!m_surfaceReady && m_window->isExposed()) {
            m_surfaceReady = true;
            QTimer::singleShot(0, this, [this]() {
                updateBlur();
                updateShadow();
            });
        }
        break;
    case QEvent::MouseMove: {
        // Resizing from the window edges (there is no frame to grab).
        auto *e = static_cast<QMouseEvent *>(event);
        if (e->buttons() != Qt::NoButton) {
            break;
        }
        const Qt::Edges edges = edgesAt(e->position());
        if (edges != m_cursorEdges) {
            if (m_cursorEdges) {
                QGuiApplication::restoreOverrideCursor();
            }
            if (edges) {
                QGuiApplication::setOverrideCursor(cursorFor(edges));
            }
            m_cursorEdges = edges;
        }
        break;
    }
    case QEvent::Leave:
        if (m_cursorEdges) {
            QGuiApplication::restoreOverrideCursor();
            m_cursorEdges = {};
        }
        break;
    case QEvent::MouseButtonPress: {
        auto *e = static_cast<QMouseEvent *>(event);
        const Qt::Edges edges = edgesAt(e->position());
        if (e->button() == Qt::LeftButton && edges) {
            m_window->startSystemResize(edges);
            return true;
        }
        break;
    }
    default:
        break;
    }
    return false;
}

void StoreChrome::updateBlur()
{
    if (!m_window || !m_surfaceReady) {
        return;
    }
    QRegion blur;
    if (m_sidebarWidth > 0) {
        const QRect strip(0, 0, qCeil(m_sidebarWidth), m_window->height());
        // Keep the blur inside the rounded corner.
        const QPolygon shape = roundedPath(QRectF(0, 0, m_window->width(), m_window->height()), radius()).toFillPolygon().toPolygon();
        blur = QRegion(strip).intersected(QRegion(shape));
    }
    if (m_blurApplied && blur == m_appliedBlur) {
        return; // unchanged; don't bother KWin
    }
    KWindowEffects::enableBlurBehind(m_window, !blur.isEmpty(), blur);
    m_appliedBlur = blur;
    m_blurApplied = true;
}

void StoreChrome::updateShadow()
{
    if (!m_window || !m_surfaceReady) {
        return;
    }
    if (isMaximized()) {
        if (m_shadow) {
            m_shadow->destroy();
        }
        return;
    }
    if (!m_shadow) {
        // Shadow tiles: a blurred rounded rectangle with the window's own
        // shape cut out, sliced into corners and 1 px edge strips.
        const int r = WindowRadius;
        const int pad = ShadowSize;
        const int size = 2 * pad + 2 * r + 1;
        QImage image(size, size, QImage::Format_ARGB32_Premultiplied);
        image.fill(Qt::transparent);
        {
            QPainter p(&image);
            p.setRenderHint(QPainter::Antialiasing);
            p.setPen(Qt::NoPen);
            p.setBrush(QColor(0, 0, 0, 120));
            p.drawPath(roundedPath(QRectF(pad, pad + 6, size - 2 * pad, size - 2 * pad), r));
        }
        blurAlpha(image, pad / 3);
        {
            QPainter p(&image);
            p.setRenderHint(QPainter::Antialiasing);
            p.setCompositionMode(QPainter::CompositionMode_Clear);
            p.setPen(Qt::NoPen);
            p.setBrush(Qt::black);
            p.drawPath(roundedPath(QRectF(pad, pad, size - 2 * pad, size - 2 * pad), r));
        }
        auto tile = [&](const QRect &rect) {
            auto t = KWindowShadowTile::Ptr::create();
            t->setImage(image.copy(rect));
            return t;
        };
        const int c = pad + r; // corner tile size
        m_shadow = new KWindowShadow(this);
        m_shadow->setTopLeftTile(tile(QRect(0, 0, c, c)));
        m_shadow->setTopTile(tile(QRect(c, 0, 1, pad)));
        m_shadow->setTopRightTile(tile(QRect(c + 1, 0, c, c)));
        m_shadow->setRightTile(tile(QRect(c + 1 + r, c, pad, 1)));
        m_shadow->setBottomRightTile(tile(QRect(c + 1, c + 1, c, c)));
        m_shadow->setBottomTile(tile(QRect(c, c + 1 + r, 1, pad)));
        m_shadow->setBottomLeftTile(tile(QRect(0, c + 1, c, c)));
        m_shadow->setLeftTile(tile(QRect(0, c, pad, 1)));
        m_shadow->setPadding(QMargins(pad, pad, pad, pad));
    }
    if (m_shadow->isCreated() && m_shadow->window() == m_window) {
        return; // already attached
    }
    if (m_shadow->isCreated()) {
        m_shadow->destroy();
    }
    m_shadow->setWindow(m_window);
    m_shadow->create();
}

#include "moc_StoreChrome.cpp"
