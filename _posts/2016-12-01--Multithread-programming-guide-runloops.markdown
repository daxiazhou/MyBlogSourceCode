---
layout: post
title: 多线程编程指南（二）Run Loops
date: 2016-12-01
---

Run loop 是与线程密切相关的基础设施。通常，线程一次只执行一个任务，执行完毕后线程就会退出，Run loop 能够让线程能随时处理事件但并不退出。run loop 接收时间来自于两种源，分别是输入源(input source)和timer。输入源传送异步事件，通常来自于其它线程或者应用。timer 传递同步事件。如下图所示:

![](/images/Runloops/runloop.jpg)

####1. Run Loop Mode
Run loop mode 是 source、timer、observer 的集合。每次启功 run loop，要为它指定一种 “mode”，在运行过程中，只有与该 mode 相关联的源会被监测和被允许传递事件。系统已经预定义了一些常用的 mode，当然，你也可以自定义 mode。系统预定义的 mode 有:

* NSDefaultRunLoopMode: 默认模式，大多数操作使用这种模式就可以了
* NSEventTrackingRunLoopMode: 追东鼠标拖拽或者屏幕滚动等事件
* NSConnectionReplyMode: macOS 10.0+ 支持
* NSModalPanelRunLoopMode: macOS 10.0+ 支持
* NSRunLoopCommonModes: 常用 mode 的组合，默认包含 defaultmode 和 trackingmode 两种，还可以添加其它的 mode 到这里。与 commonmode 相关联的源也就与它包含的的多个 mode 相关联。

主线程的 Run loop 的 commonmode 包含两个 mode: defaultmode 和 commonmode，DefaultMode 是 App 平时所处的状态，TrackingRunLoopMode 是追踪 ScrollView 滑动时的状态。当你创建一个 Timer 并加到 DefaultMode 时，Timer 会得到重复回调，但此时滑动一个TableView时，RunLoop 会将 mode 切换为 TrackingRunLoopMode，这时 Timer 就不会被回调，并且也不会影响到滑动操作。如果想让 Timer 在两个 Mode 下都能得到回调，一种办法就是将这个 Timer 分别加入这两个 Mode。还有一种方式，就是将 Timer 加入到 commonmode 中。

####2. Input Sources
输入源异步地传递事件到线程，主要有两种类型，Port-based input sources 和 Custom input sources。Port-based input sources 监视应用的 Mach  端口，Custom input sources 监视自定义源的事件。系统已经预定义了一种 custom input source，叫做 Perform Selector Sources，有了它，我们可以在任何线程执行指定的方法。在目标线程，Perform Selector 请求按照线性顺序执行。一个 Perform Selector 执行完毕后会自动从 run loop 中移除。当对一个目标线程使用 Perform Selector 时，目标线程必须有run loop。对于子线程，必须明确的调用 NSRunLoop 的是 start 方法，才能创建 run loop。Run loop 在一次循环中会处理所有排队的 Perform Selector，而不是一次循环只执行一个。系统提供了多个方法添加 Perform Selector 到其它线程:
 
* performSelectorOnMainThread:withObject:waitUntilDone:
* performSelectorOnMainThread:withObject:waitUntilDone:modes:
* performSelector:onThread:withObject:waitUntilDone:
* performSelector:onThread:withObject:waitUntilDone:modes:
* performSelector:withObject:afterDelay:
* performSelector:withObject:afterDelay:inModes:
* cancelPreviousPerformRequestsWithTarget:
* cancelPreviousPerformRequestsWithTarget:selector:object:

PerformSelector 实际上会建一个 Timer 添加到目标线程的 Run loop 中，如果，目标线程没有 run loop，这个方法则会失效。

####3. Timer Sources
其实就是 NSTimer ，相信大部分开发者都用过它。Timer 也要与run loop 的 mode 相关联，只有 run loop 运行的 mode 与 Timer 关联的 mode 相同，timer 才能工作。例如，新建一个工程，添加一个定时器到 runloop 的 NSDefaultRunLoopMode 中，然后拖一个 TextView 到 Storyboard 中，启动后拖着 TextView 滚动时，timer 就会停止打印 log，当松开后又会继续打印 log。

```
- (void)viewDidLoad {
    [super viewDidLoad];

    // 定义一个定时器，约定两秒之后调用self的printLog方法
    NSTimer *timer = [NSTimer timerWithTimeInterval:2.0
                                             target:self
                                           selector:@selector(printLog)
                                           userInfo:nil
                                            repeats:YES];
    
    // 将定时器添加到当前RunLoop的NSDefaultRunLoopMode下
    [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
}

- (void)printLog
{
    NSLog(@"---------------- run");
}
```
如果某个时间点被错过了，例如执行了一个很长的任务，则那个时间点的回调也会跳过去，不会延后执行。

####4. Observers
每个 Observer 都包含了一个回调（函数指针），当 RunLoop 的状态发生变化时，观察者就能通过回调接受到这个变化。可以观察的几个节点:

```
typedef CF_OPTIONS(CFOptionFlags, CFRunLoopActivity) {
    kCFRunLoopEntry         = (1UL << 0), // 即将进入Loop
    kCFRunLoopBeforeTimers  = (1UL << 1), // 即将处理 Timer
    kCFRunLoopBeforeSources = (1UL << 2), // 即将处理 Source
    kCFRunLoopBeforeWaiting = (1UL << 5), // 即将进入休眠
    kCFRunLoopAfterWaiting  = (1UL << 6), // 刚从休眠中唤醒
    kCFRunLoopExit          = (1UL << 7), // 即将退出Loop
};
```
在代码中创建一个 Observer 观察状态的变化：

```
- (void)viewDidLoad {
    [super viewDidLoad];
    
    // 创建观察者
    CFRunLoopObserverRef observer = CFRunLoopObserverCreateWithHandler(CFAllocatorGetDefault(), kCFRunLoopAllActivities, YES, 0, ^(CFRunLoopObserverRef observer, CFRunLoopActivity activity) {
        NSLog(@"监听到RunLoop发生改变---%zd",activity);
    });
    // 添加观察者到当前RunLoop中
    CFRunLoopAddObserver(CFRunLoopGetCurrent(), observer, kCFRunLoopDefaultMode);
    // 释放observer，最后添加完需要释放掉
    CFRelease(observer);
}
```
控制台输出:
![](images/Runloops/runlooplog.jpg )
