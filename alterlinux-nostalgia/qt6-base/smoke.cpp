#include <QAtomicInteger>
#include <QCoreApplication>
#include <QCryptographicHash>
#include <QDebug>
#include <QLocale>
#include <QRegularExpression>
#include <QThread>
#include <QTimer>
#include <vector>
#ifdef QT_WIDGETS_LIB
#include <QApplication>
#include <QDomDocument>
#include <QFontDatabase>
#include <QImage>
#include <QPainter>
#include <QPushButton>
#include <QSslSocket>
#endif

int main(int argc, char **argv)
{

#ifdef QT_WIDGETS_LIB
    QApplication application(argc, argv);
#else
    QCoreApplication application(argc, argv);
#endif
    QAtomicInteger<quint64> counter(0);
    std::vector<QThread *> threads;
    for (int i = 0; i < 4; ++i) {
        auto thread = QThread::create([&counter] {
            for (int j = 0; j < 1000; ++j)
                counter.fetchAndAddRelaxed(1);
        });
        threads.push_back(thread);
        thread->start();
    }
    for (auto thread : threads) {
        thread->wait();
        delete thread;
    }
    if (counter.loadRelaxed() != 4000)
        return 1;
    const auto digest = QCryptographicHash::hash("abc", QCryptographicHash::Sha256).toHex();
    if (digest != "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad")
        return 2;
    const auto blake2 = QCryptographicHash::hash("abc", QCryptographicHash::Blake2b_512).toHex();
    if (blake2 != "ba80a53f981c4d0d6a2797b69f12f6e94c212f14685ac4b74b12bb6fdbffa2d17"
                  "d87c5392aab792dc252d5de4533cc9518d38aa8dbf1925ab92386edd4009923")
        return 10;
    QRegularExpression expression(QStringLiteral("^Qt[0-9]+$"));
    expression.optimize();
    if (!expression.match(QStringLiteral("Qt6")).hasMatch())
        return 3;
    const auto localized = QLocale(QStringLiteral("ja_JP")).toString(1234567);
    if (localized.isEmpty())
        return 4;

#ifdef QT_WIDGETS_LIB
    if (QFontDatabase::families().isEmpty())
        return 6;
    QImage image(128, 64, QImage::Format_ARGB32_Premultiplied);
    image.fill(QColor(10, 20, 30));
    {
        QPainter painter(&image);
        painter.fillRect(0, 0, 4, 4, Qt::red);
        painter.drawText(QRect(8, 8, 120, 56), QStringLiteral("Qt6 i486 test"));
    }
    if (image.pixelColor(0, 0) != QColor(Qt::red))
        return 7;
    QPushButton button(QStringLiteral("i486"));
    button.resize(128, 64);
    button.show();
    application.processEvents();
    button.render(&image);
    if (!QSslSocket::supportsSsl())
        return 8;
    QDomImplementation::setInvalidDataPolicy(QDomImplementation::ReturnNullNode);
    QDomDocument document;
    const char invalidXml[] = "<r><![CDATA[da\0ta]]></r>";
    if (document.setContent(QByteArray(invalidXml, sizeof(invalidXml) - 1)))
        return 9;
    qInfo() << "GUI, fonts, raster, Widgets and TLS OK";
#endif
    QTimer::singleShot(0, &application, &QCoreApplication::quit);
    if (application.exec() != 0)
        return 5;
    qInfo() << "Qt" << qVersion() << "atomic64, threads, SHA256, Blake2, regex, locale, event loop OK";
    return 0;
}
