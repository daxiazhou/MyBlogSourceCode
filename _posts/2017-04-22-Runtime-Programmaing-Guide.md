---
title: Runtime 知识总结
layout: post
date: 2017-04-20
---

##消息
###objc_msgSend 函数
在 Object-C 中，到运行时才会把消息与方法的实现绑定起来，编译器把 `[receiver message]` 转换为 `objct_msgSend(receiver, selector)`。receiver 和 selector 是 `objc_msgSend` 函数最基本的参数，如果消息还有其它参数，也会传给 `objc_msgSend`，如：

```objc
objc_msgSend(receiver, selector, arg1, arg2, ...)
```

为实现动态绑定，`objc_msgSend` 函数做了下面三件事：

1. 找到方法对应的实现。
2. 调用方法实现，把它接收到的对象和方法的参数传给方法实现。
3. 最后，把方法实现的返回值作为自己的返回值传递出去。

消息发送依赖于类数据结构中的两个基本元素：

* 指向父类的指针
* 类分发表，个人理解就是方法列表，把方法选择器和方法实现关联起来。

实例对象中有一个指针变量，叫做 isa，指向其类结构，通过这个指针可以找到它的类以及所有它继承的类。

图 3-1 

当对一个对象发送消息时，消息发送函数通过 isa 指针找到类结构，在分发表中搜索方法选择器。如果找到不到，就到 superclass 的分发表中找，如果一直找不到会进入到根类 NSObject 类中取查找。如果找到了选择器，消息发送函数调用这个方法，并把接收者传给这个方法。为了加快消息发送的速度，运行时在缓存中保存最近使用过的方法，每次现在缓存中查找，提高了查找的效率。


###隐藏的参数
objc_msgSend 函数找到方法实现后不仅会把方法的所有参数传递给方法实现，还会传递两个隐藏的参数：

* 接收消息的对象
* 方法选择器

这两个参数并没有在源代码中显示声明，它们是在编译阶段被插入的方法实现中的。尽管这两个参数没有被明确声明，源代码中仍然可以引用它们。在方法中使用 `self` 引用接收消息的对象，使用 `_cmd` 引用方法选择器。在下面这个例子中，`_cmd` 引用 `strange` 方法的选择器，self 引用了 `strange` 消息的接收者。

```objc
- (void)strange
{
    id  target = getTheReceiver();
    SEL method = getTheMethod();
 
    if ( target == self || method == _cmd )
        return nil;
    return [target performSelector:method];
}
```

###获得方法地址
想要避免动态绑定，只能通过拿到方法的地址直接调用它，这种方法适用的场景很少，除非是连续多次调用某个方法的极端情况。

通过 `NSObject` 类中的 `methodForSelector:` 方法可以得到指向方法实现的指针，在将该指针转换成对应的函数类型时，要明确声明上节提到的两个隐藏参数。下面这个例子展示了如何直接调用 `setFilled:` 方法实现：

```objc
void (*setter)(id, SEL, BOOL);
int i;
 
setter = (void (*)(id, SEL, BOOL))[target
    methodForSelector:@selector(setFilled:)];
for ( i = 0 ; i < 1000 ; i++ )
    setter(targetList[i], @selector(setFilled:), YES);
```
函数指针 `setter ` 的前两个参数分别是消息的接收者(self)和方法选择器(_cmd)。

##动态方法解析
有些情况下你想动态地提供一个方法的实现，例如，使用 @dynamic 指令修饰的 属性。

```objc
@dynamic propertyName;
```
`@dynamic` 告诉编译器动态的给这个属性提供存取方法。我们可以通过实现 `resolveInstanceMethod:` 和 `resolveClassMethod:` 方法，动态的为方法选择器提供实例方法和类方法的实现。Object-C 方法不过是至少包含两个参数(self 和 _cmd)的 C 函数，我们可以通过 `class_addMethod` 函数为类添加指定的方法：

```objc
void dynamicMethodIMP(id self, SEL _cmd) {
    // implementation ....
}

@implementation MyClass
+ (BOOL)resolveInstanceMethod:(SEL)aSEL
{
    if (aSEL == @selector(resolveThisMethodDynamically)) {
          class_addMethod([self class], aSEL, (IMP) dynamicMethodIMP, "v@:");
          return YES;
    }
    return [super resolveInstanceMethod:aSEL];
}
@end
```
这个例子中为 `resolveThisMethodDynamically ` 添加了实现内容，就是函数 `dynamicMethodIMP ` 中的代码。动态方法解析在小心转发机制触发之前执行，如果 `respondsToSelector:` 或者 `instancesRespondToSelector:` 被调用，动态方法解析给了一个为方法选择器提供 `IMP` 的机会。如果你实现了 `resolveInstanceMethod `，但是想让方法选择器进入消息转发机制，那么返回 `NO` 就可以了。

##消息转发

如果向一个对象发送消息，这个对象没有处理，在报 error 之前，runtime 






