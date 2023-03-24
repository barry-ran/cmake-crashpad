#include "widget.h"

#include <QApplication>
#include <QDebug>

#include "client/crash_report_database.h"
#include "client/crashpad_client.h"
#include "client/settings.h"

bool initializeCrashpad();

int main(int argc, char *argv[])
{
    QApplication a(argc, argv);

    qDebug() << "initializeCrashpad:" << initializeCrashpad();
    // 这个crash可以捕获到
    //*(volatile int *)0 = 0;

    Widget w;
    w.show();
    return a.exec();
}

bool initializeCrashpad() {
    QString exeDir = QCoreApplication::applicationDirPath();

#if defined(Q_OS_WIN)
    base::FilePath handleDir((exeDir + "/crashpad_handler.exe").toStdWString());
    base::FilePath reportsDir(exeDir.toStdWString());
    base::FilePath metricsDir(exeDir.toStdWString());
#endif

#if defined(Q_OS_MAC)
    base::FilePath handleDir((exeDir + "/crashpad_handler").toStdString());
    base::FilePath reportsDir(exeDir.toStdString());
    base::FilePath metricsDir(exeDir.toStdString());
#endif

    // BugSplat database url
    QString url = "http://cmake_crashpad.bugsplat.com/post/bp/crash/crashpad.php";
    // Metadata that will be posted to BugSplat
    QMap<std::string, std::string> annotations;
    annotations["format"] = "minidump";                 // Required: Crashpad setting to save crash as a minidump
    annotations["database"] = "cmake_crashpad";     // Required: BugSplat database
    annotations["product"] = "test";     // Required: BugSplat appName
    annotations["version"] = "1.0.0";  // Required: BugSplat appVersion
    //annotations["key"] = "Sample key";                  // Optional: BugSplat key field
    //annotations["user"] = "fred@bugsplat.com";          // Optional: BugSplat user email
    //annotations["list_annotations"] = "Sample comment";	// Optional: BugSplat crash description

    // Disable crashpad rate limiting so that all crashes have dmp files
    std::vector<std::string> arguments;
    arguments.push_back("--no-rate-limit");

    // Initialize crashpad database
    std::unique_ptr<crashpad::CrashReportDatabase> database = crashpad::CrashReportDatabase::Initialize(reportsDir);
    if (database == NULL) {
        return false;
    }

    // Enable automated crash uploads
    crashpad::Settings* settings = database->GetSettings();
    if (settings == NULL) {
        return false;
    }
    settings->SetUploadsEnabled(true);

    // Start crash handler
    crashpad::CrashpadClient* client = new crashpad::CrashpadClient();
    bool status = client->StartHandler(handleDir, reportsDir, metricsDir, url.toStdString(), annotations.toStdMap(), arguments, true, false);
    return status;
}
