---
layout: post
title: 多线程编程指南（一）线程管理
date: 2016-12-1 00:19:24
---

线程是应用程序中独立的实体，它有自己的运行栈，可以被内核独立的调度。创建线程需要消耗一定的系统资源，要为它分配内核内存空间和程序内存空间。内核内存空间用于保存线程数据结构和属性。程序内存空间用于存储线程栈，在 iOS 中，主线程至少是 1M，子线程最少 16KB 。
####1 创建线程
创建线程相对简单，首先创建一个方法作为线程入口，然后从另一个线程启动它即可。
#####1.1 使用 NSThread 创建线程
 * 直接使用 NSThread 的类方法 `detachNewThreadSelector:toTarget:withObject:` 创建一个线程：
  ```
 [NSThread detachNewThreadSelector:@selector(myThreadMainMethod:) toTarget:self withObject:nil];
 ```
 * 先创建一个 NSThread 实例对象，然后调用它的 start 方法：
 
 ```
 NSThread* myThread = [[NSThread alloc] initWithTarget:self
                                              selector:@selector(myThreadMainMethod:)
                                                object:nil];
[myThread start];  // Actually create the thread
 ```
 这两种方法创建的线程都是可脱离的(detached)，可脱离线程是不能被其他线程回收或杀死的，它的存储器资源在它终止时由系统自动释放。

#####1.2 使用 POSIX 线程
POSIX 线程 API 是使用 C 语言进行 Linux 开发常用的创建线程的方式，在 iOS 开发中一般不会使用。

#####1.3 使用任意 NSObject 实例对象创建线程
NSObject 实例方法 `performSelectorInBackground:withObject:` 创建一个后台线程，这种方法与 NSThread 的 `detachNewThreadSelector:toTarget:withObject:` 方法类似。

####2. 设置线程属性

#####2.1 设置线程栈的大小
创建线程时系统已经为它分配了一定的内存空间作为栈，栈用于管理栈帧(Stack frame，是一个为函数保留的区域，用来存储关于参数、局部变量和返回地址的信息。堆栈帧通常是在新的函数调用的时候创建，并在函数返回的时候销毁。调用栈（Call stack）就是指存放某个程序的正在运行的函数的信息的栈。Call stack 由 stack frames 组成，每个 stack frame 对应于一个未完成运行的函数。)如果想改变线程栈的大小，必须要在创建线程之前设置。 也就是说，使用 NSThread 创建一个实现对象，必须在调用 start 方法之前使用 setStackSize: 方法设置栈的大小。

#####2.2 设置线程本地存储
线程拥有一个字典，在线程的整个生命周期中，你可以使用该字典保存信息，NSThread 提供了 threadDictionary 方法获取该字典。

#####2.3 设置线程优先级
任何新线程都有一个与之关联的默认优先级，内核调度算法在决定该运行哪个线程时，会把线程的优先级作为考量因素，较高优先级的线程会比较低优先级的线程具有更多的运行机会。较高优先级不保证你的线程具体执行的时间，只是相比较低优先级的线程，它更有可能被调度器选择执行而已。使用 NSThread 的 setThreadPriority: 方法设置线程优先级。

苹果建议使用线程默认的优先级，提高线程的优先级会增加低优先级线程饥饿的可能性。如果应用程序中包含高、低优先级线程交互的情况，饥饿的低优先级线程可能会阻塞其它线程，造成性能瓶颈。

####3. 终止线程
终止线程最好的方法是让它正常的从入口历程中退出。上面也提到过，脱离的线程会在退出前自动释放系统分配给它的资源，直接杀死线程会阻止线程退出前的清理工作，可能会导致内存泄露或者其它潜在问题。如果你期望线程在执行中退出，那就要把线程设计成能够接受外界的退出消息的方式，一种方法是使用 run loop 输入源接收消息。如果你对 run loop 不熟悉，下面一节将重点接收它。

```
- (void)threadMainRoutine
{
    BOOL moreWorkToDo = YES;
    BOOL exitNow = NO;
    NSRunLoop* runLoop = [NSRunLoop currentRunLoop];
 
    // Add the exitNow BOOL to the thread dictionary.
    NSMutableDictionary* threadDict = [[NSThread currentThread] threadDictionary];
    [threadDict setValue:[NSNumber numberWithBool:exitNow] forKey:@"ThreadShouldExitNow"];
 
    // Install an input source.
    [self myInstallCustomInputSource];
 
    while (moreWorkToDo && !exitNow)
    {
        // Do one chunk of a larger body of work here.
        // Change the value of the moreWorkToDo Boolean when done.
 
        // Run the run loop but timeout immediately if the input source isn't waiting to fire.
        [runLoop runUntilDate:[NSDate date]];
 
        // Check to see if an input source handler changed the exitNow value.
        exitNow = [[threadDict valueForKey:@"ThreadShouldExitNow"] boolValue];
    }
}
```
####参考文章
* [Threading Programming Guide](https://developer.apple.com/library/content/documentation/Cocoa/Conceptual/Multithreading/Introduction/Introduction.html#//apple_ref/doc/uid/10000057i-CH1-SW1)