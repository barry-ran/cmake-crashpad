#include "widget.h"
#include "./ui_widget.h"

Widget::Widget(QWidget *parent)
    : QWidget(parent)
    , ui(new Ui::Widget)
{
    ui->setupUi(this);
}

Widget::~Widget()
{
    delete ui;
}


void Widget::on_crashBtn_clicked()
{
    // windows上这个crash为什么捕获不到？
    // windows上crashpad内部使用::SetUnhandledExceptionFilter()来注册异常处理函数
    // 而SetUnhandledExceptionFilter不能处理所有windows上的异常：
    // 1. windowproc等消息处理函数中的异常 - windowproc是由系统内核回调的，系统内部使用SEH处理系统内核回调的异常，所以SetUnhandledExceptionFilter抓不到
    // 2. crt中有自己的异常处理机制，在某些情况下会删除任何自定义崩溃处理程序(SetUnhandledExceptionFilter(NULL))，并且我们的崩溃处理程序将永远不会被调用
    // 关于windows下异常处理是一个比较复杂的问题，后面有时间专门调研

    // 202303 update:(换了新版crashpad ad2e04可以捕获了)
    *(volatile int *)0 = 0;
}
