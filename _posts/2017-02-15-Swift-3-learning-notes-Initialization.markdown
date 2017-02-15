---
title: Swift 3 学习笔记 - 构造器
layout: post
date: 2017-02-15
---

记录一些知识要点，加深记忆。
##1. 默认构造器
如果结构体或类的**所有属性**都有默认值，同时没有自定义的构造器，那么 Swift 会给这些结构体或类提供一个默认构造器。

```swift
class ShoppingListItem {
    var name: String?
    var quantity = 1
    var purchased = false
}
var item = ShoppingListItem()
```
name 是可选类型，默认值为 nil，如果再添加一个非可选类型的属性，且不赋默认值，必须在自定义构造器中为该属性赋值，否则编译器会报错。

如果没有为结构体创建自定义构造器，它不仅会自动获得一个默认构造器，还会获得逐一成员构造器，逐一成员构造器参数名与属性名相同。

```swift
struct Size {
    var width = 0.0, height = 0.0
}
let oneByone = Size()
let twoByTwo = Size(width: 2.0, height: 2.0)
```

##2. 指定构造器和便利构造器
类的所有存储型属性都必须在构造过程中设置初始值。如果属性是可选类型的，它已经有默认值 nil，在构造器中可以不为它设置初始值。每个类至少有一个指定构造器（类似 OC 中就是指定初始化方法），指定构造器语法：

```swift
init(parameters) {
    statements
}
```
便利构造器语法需要在 `init` 前添加 `convenience` 关键字

```swift
convenience init(parameters) {
    statements
}
```
指定构造器和便利构造器之间的调用关系规则如下：

1. 指定构造器必须调用其直接父类的指定构造器
2. 便利构造器必须调用同类中定义的其它构造器
3. 便利构造器必须最终调用一个指定构造器

Swift 中类构造分层两个阶段，第一个阶段，每个存储型属性被指定一个初始值。第二个阶段，在新实例准备使用之前进一步定制他们的存储型属性。构造器在第一个构造阶段完成之前，不能调用任何实例方法，不能读取任何实例属性的值，不能引用 self 作为一个值。只有第一个阶段结束后，该实例才会成为有效实例，才能访问属性和调用方法。

喵神在 Swifter 中总结了子类的初始化顺序：

 1. 设置子类自己需要初始化的参数
 2. 调用父类的相应的初始化方法
 3. 对父类中需要改变的成员进行设定

一般情况下 Swift 中子类默认不会继承父类的构造器，只有在特定的情况下才会继承父类的构造器：

1. 如果子类没有定义任何指定构造器，它将自动继承所有父类的指定构造器
2. 如果子类提供了所有父类指定构造器的实现（无论是通过规则 1 继承过来的，还是提供了自定义的实现）它将自动继承所有父类的便利构造器

##3. 可失败构造器
可失败构造器的语法为在 init 关键字后添加 `？`或者 `！`。`init？` 表示返回一个可选类型的实例对象，如果构造器的参数不符合要求，可直接返回 nil，其它类型的构造器是不允许返回 nil 的。`init!` 就表示返回隐式解包可选类型的实例对象。

```swift
struct Animal {
    let species: String
    init?(species: String) {
        if species.isEmpty { return nil }
        self.species = species
    }
}
let someCreature = Animal(species: "Giraffe")
// someCreature 的类型是 Animal? 而不是 Animal
```
##4. 必要构造器
在类的构造器前添加 required 关键字，表明该类的子类必须实现该构造器，子类重写父类的必要构造器时，必须要构造器前添加 required 关键字，不需要添加 override 关键字。

```swift
class SomeClass {
    required init() {
        // 构造器的实现代码
    }
}

class SomeSubclass: SomeClass {
    required init() {
        // 构造器的实现代码
    }
}
```
 
###参考链接
[The Swift Programming Language 中文版](http://wiki.jikexueyuan.com/project/swift/chapter2/14_Initialization.html)
[《Swifter - 100 个 Swift 必备 tips》](http://swifter.tips/buy/)
