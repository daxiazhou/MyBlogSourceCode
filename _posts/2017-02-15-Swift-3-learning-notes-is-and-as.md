---
title: Swift 3 学习笔记 - is 和 as
layout: post
date: 2017-03-08
---

##is
is 的功能与 Object-C 中的 `isKindOfClass` 类，用来判断一个对象是否属于某个类或者某个类的子类。区别是它不仅可以用于 `class` 类型上，也可以对 Struct 或者 enum 类型进行判断。

```swift
class ClassA {}
class ClassB: ClassA {}

let obj: AnyObject = ClassB()
if (obj is ClassA) {
    print("属于 ClassA") // true
}

if (obj is ClassB) {
    print("属于 ClassB") // true
}

```
在 Object—C 中经常使用 `isKindOfClass` 和 `isMemberOfClass` 判断一个对象是否属于某个类，在 Swift 中仍然可以使用它们。

##as
as 用于类型转换，`as?` 返回一个向下转换成的类型的可选值，`as!` 向下转换并强制解包。当使用 `as!`向下转型为一个不正确的类型时，会触发运行时错误。在编码的时候建议都使用 `as?`，转型失败会返回一个 nil，不会导致 crash。

```swift
class ClassA {}
class ClassB: ClassA {}

let obj: ClassA = ClassB()
if let objA = obj as? ClassB {
    print("true")
}

```