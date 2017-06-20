---
title: Runtime 知识总结
layout: post
date: 2017-04-20
---
##1. 名词解释
####Method、SEL 和 IMP
```objc
/// An opaque type that represents a method in a class definition.
typedef struct objc_method *Method;

struct objc_method {
    SEL method_name                                          OBJC2_UNAVAILABLE;
    char *method_types                                       OBJC2_UNAVAILABLE;
    IMP method_imp                                           OBJC2_UNAVAILABLE;
}                                                            OBJC2_UNAVAILABLE;

```
`Method` 表示类中方法，使用 `SEL` 类型表示方法名, 其实就是常用的 `selector`，叫做方法选择器，它是一个指向 `objc_selector` 结构体的指针。

```objc
/// An opaque type that represents a method selector.
typedef struct objc_selector *SEL;
```
method_types 表示方法的类型，具体说明可以参考[Type Encodings](https://developer.apple.com/library/content/documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtTypeEncodings.html)

`IMP` 类型表示方法的实现，它是一个函数指针

```objc
typedef id (*IMP)(id, SEL, ...); 
```

####Ivar
`Ivar` 代表类中的实例变量的类型

```objc
/// An opaque type that represents an instance variable.
typedef struct objc_ivar *Ivar;

struct objc_ivar {
    char *ivar_name                                          OBJC2_UNAVAILABLE;
    char *ivar_type                                          OBJC2_UNAVAILABLE;
    int ivar_offset                                          OBJC2_UNAVAILABLE;
#ifdef __LP64__
    int space                                                OBJC2_UNAVAILABLE;
#endif
}  
```
####id 和 Class
`id` 指向类的实例的指针，`objc_object` 结构体中有一个 `Class` 类型的指针 `isa`，它指向对象所属的类。 

```objc
/// A pointer to an instance of a class.
typedef struct objc_object *id;

struct objc_object {
    Class isa  OBJC_ISA_AVAILABILITY;
};
```
`Class` 代表 Objective-C 类的类型，是一个指向 `objc_class` 结构体的指针。

```objc
/// An opaque type that represents an Objective-C class.
typedef struct objc_class *Class;
```

##2. 消息
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
函数指针 `setter ` 的前两个参数分别是消息的接收者 (self) 和方法选择器 (_cmd)。

##3. 动态方法解析
有些情况下你想动态地提供一个方法的实现，例如，使用 @dynamic 指令修饰的 属性。

```objc
@dynamic propertyName;
```
`@dynamic` 告诉编译器动态的给这个属性提供存取方法。我们可以通过实现 `resolveInstanceMethod:` 和 `resolveClassMethod:` 方法，动态的为方法选择器提供实例方法和类方法的实现。Object-C 方法不过是至少包含两个参数(self 和 _cmd)的 C 函数，我们可以通过 `class_addMethod` 函数为类添加指定的方法：

```objc
@interface ZDXDemo : NSObject

@property (nonatomic, copy) NSString *name;

@end

@implementation ZDXDemo

@dynamic name;

+ (BOOL)resolveInstanceMethod:(SEL)aSEL
{
    if ([NSStringFromSelector(aSEL) hasPrefix:@"setName"]) {
        class_addMethod([self class], aSEL, class_getMethodImplementation([self class], @selector(setupNameValue:)), "v@:");
        return YES;
    }
    
    return [super resolveInstanceMethod:aSEL];
}

- (void)setupNameValue:(NSString *)name
{
    NSLog(@"This is setupNameValue, name:%@", name);
}

@end

int main(int argc, const char * argv[]) {
    @autoreleasepool {

        ZDXDemo *demo = [[ZDXDemo alloc] init];
        if ([demo respondsToSelector:@selector(setName:)]) {
            [demo performSelector:@selector(setName:) withObject:@"ZDXDemo"];
        }
    }
    
    return 0;
}
```
这个例子中为 `setName` 添加了实现内容，就是函数 `setupNameValue` 中的代码。动态方法解析在小心转发机制触发之前执行，如果 `respondsToSelector:` 或者 `instancesRespondToSelector:` 被调用，动态方法解析给了一个为方法选择器提供 `IMP` 的机会。如果你实现了 `resolveInstanceMethod `，但是想让方法选择器进入消息转发机制，那么返回 `NO` 就可以了。

##4. 消息转发

###重定向（forwardingTargetForSelector）
如果动态方法解析失败（返回 NO），在进入消息转发之前，还有一个机会将消息重定向给别的对象。通过重载 `- (id)forwardingTargetForSelector:(SEL)aSelector` 方法，返回一个接受该消息的对象。

```objc
@interface ZDXAnotherDemo : NSObject

- (void)setName:(NSString *)name;

@end

@implementation ZDXAnotherDemo

- (void)setName:(NSString *)name
{
    NSLog(@"This is AnotherDemo, name:%@", name);
}

@end


@interface ZDXDemo : NSObject

@property (nonatomic, copy) NSString *name;
@property (nonatomic, strong) ZDXAnotherDemo *anotherDemo;

@end

@implementation ZDXDemo

@dynamic name;

- (instancetype)init
{
    self = [super init];
    if (self) {
        _anotherDemo = [[ZDXAnotherDemo alloc] init];
    }
    
    return self;
}

- (id)forwardingTargetForSelector:(SEL)aSelector
{
    if (aSelector == @selector(setName:)) {
        return self.anotherDemo;
    }
    return [super forwardingTargetForSelector:aSelector];
}

int main(int argc, const char * argv[]) {
    @autoreleasepool {

        ZDXDemo *demo = [[ZDXDemo alloc] init];
        [demo performSelector:@selector(setName:) withObject:@"ZDXDemo"];
    }
    
    return 0;
}
@end

```
在这个例子中，我向 ZDXDemo 类的实例发送 `setName:` 消息，但是它并不存在这个方法，进入 `forwardingTargetForSelector ` 后，返回一个 ZDXAnotherDemo 类的实例，在 ZDXAnotherDemo 中有实现了 `setName` 方法，所有最后的输出是：`This is AnotherDemo, name:ZDXDemo`。

###转发（forwardInvocation）
如果 `forwardingTargetForSelector` 返回了 nil，就会触发消息转发机制。运行时调用消息接收者的 `forwardInvocation:` 方法，这个方法接受一个 `NSInvocation ` 类型参数，`NSInvocation ` 有三个属性：`seletor`、`target`、`methodSignature`，其中 `methodSignature ` 来自于 `methodSignatureForSelector`，系统会先调用这个方法生成签名，然后才能创建 `NSInvocation `，所以也要重写 `methodSignatureForSelector ` 。对于不能处理的消息，你可以通过实现 `forwardInvocation:` 方法做一些默认的处理。

```objc
@interface ZDXAnotherDemo : NSObject

- (void)setName:(NSString *)name;

@end

@implementation ZDXAnotherDemo

- (void)setName:(NSString *)name
{
    NSLog(@"This is AnotherDemo, name:%@", name);
}

@end

@interface ZDXDemo : NSObject

@property (nonatomic, copy) NSString *name;
@property (nonatomic, strong) ZDXAnotherDemo *anotherDemo;

@end

@implementation ZDXDemo

@dynamic name;
- (instancetype)init
{
    self = [super init];
    if (self) {
        _anotherDemo = [[ZDXAnotherDemo alloc] init];
    }
    
    return self;
}

- (void)forwardInvocation:(NSInvocation *)anInvocation
{
    if ([self.anotherDemo respondsToSelector:anInvocation.selector]) {
        [anInvocation invokeWithTarget:self.anotherDemo];
    } else {
        [super forwardInvocation:anInvocation];
    }
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
{
    NSMethodSignature *signature = [super methodSignatureForSelector:aSelector];
    if (!signature) {
        signature = [self.anotherDemo methodSignatureForSelector:aSelector];
    }
    
    return signature;
}

@end

int main(int argc, const char * argv[]) {
    @autoreleasepool {

        ZDXDemo *demo = [[ZDXDemo alloc] init];
        [demo performSelector:@selector(setName:) withObject:@"ZDXDemo"];

    }
    
    return 0;
}
```
在这个例子中，ZDXDemo 没有实现 `setName` 方法，进入转发流程。系统先调用了 `methodSignatureForSelector ` 生成方法的签名，然后才调用 `forwardInvocation ` 方法，我们拿到 `NSInvocation ` 对象后，转发给 `self.anotherDemo` 去处理。最终输入为：`This is AnotherDemo, name:ZDXDemo`。

###参考文章
* [Objective-C Runtime Programming Guide](https://developer.apple.com/library/content/documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Introduction/Introduction.html#//apple_ref/doc/uid/TP40008048-CH1-SW1)
* [Objective-C Runtime](http://yulingtianxia.com/blog/2014/11/05/objective-c-runtime/)







