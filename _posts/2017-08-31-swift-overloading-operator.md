---
title: Swift 运算符重载
layout: post
date: 2017-08-31
---

运算符是编程语言的核心模块，你能想象没有 `+` 或 `=` 的语言是什么样的么？

操作符太基础了，以至于很多语言把它作为编译器的一部分。但是，Swift 编译器没有对大多数操作符硬编码，而是提供了创建运算符的库。当然，Swift 标准库也提供所有常用的操作符。虽然是微秒变化，但是打开了自定义操作符的大门。

Swift 操作符十分强大，你可以通过两种方法修改它们来满足自己的需求：

* 为已存在的操作符定义新功能
* 创建新的操作符

`+` 就是个简单的运算符重载，如果使用两个整数：

```swift
1 + 1 // 2
```
如果使用两个字符串相加，它的行为就不一样了：

```swift
"1" + "1" // "11"
```
当对两个整数使用 `+` 时，是对它们的算术值进行相加。但是换成两个字符串时，`+` 把它们连接起来了。

在这篇教程中，你将会探索如何塑造操作符和创建自定义 3D 向量类型。

##准备工作
创建新的 PlayGround，添加下面的代码：

```swift

import UIKit

struct Vector: ExpressibleByArrayLiteral, CustomStringConvertible {
  let x: Int
  let y: Int
  let z: Int

  var description: String {
    return "(\(x), \(y), \(z))"
  }

  init(_ x: Int, _ y: Int, _ z: Int) {
    self.x = x
    self.y = y
    self.z = z
  }

  init(arrayLiteral: Int...) {
    assert(arrayLiteral.count == 3, "Must initialize vector with 3 values.")
    self.x = arrayLiteral[0]
    self.y = arrayLiteral[1]
    self.z = arrayLiteral[2]
  }
}
```
这里定义了 `Vector` 类型，它有三个属性和两个构造器。`CustomStringConvertible` 协议和 `description` 计算属性的作用是把 `Vector` 打印成指定格式的字符。

继续添加下面的代码：

```swift
let vectorA: Vector = [1, 3, 2]
let vectorB: Vector = [-2, 5, 1]
```
`ExpressibleByArrayLiteral` 协议提供了使用数组作为参数初始化 `Vector` 的接口，这个协议要求实现一个接受可变参数的构造器 `init(arrayLiteral: Int…)`。可变参数 `...` 让我们在创建 `Vector` 时，可以传入不限数量的值，如 `Vector(0)` 或者 `Vector(5, 4, 3)`。实现了这个协议，我们可以直接使用数组构造 `Vector` 对象，`let vectorA: Vector = [1, 3, 2]`。但是，数组的数量不能超过 3 个，不然会导致 crash。

##重载加法运算符

为了重载操作符，你必须实现一个以操作符命名的函数。添加下面的代码：

```swift
static func +(left: Vector, right: Vector) -> Vector {
  return [left.x + right.x, left.y + right.y, left.z + right.z]
}
```
这个函数接受两个向量，输出它们的和。现在，继续在 Playground 中添加代码测试这个函数：

```swift
vectorA + vectorB // (-1, 8, 3)
```
你可以在右边的看到合并后向量的值。

###其它运算类型

加法是中缀（infix）操作，使用时把它放置在两个值的中间。这里还有一些其它类型的运算：

* infix: 中缀，放在两个值中间，就像加号操作（1 + 1）
* prefix: 前缀，放在值的前面，比如负号（-3）、
* postfix: 后缀，放在值的后面，比如强制解包操作（mayBeNil!）
* ternary: 三元运算，在 Swift 中，不支持开发者自定义三元运算。

下面重载负号运算符，它接收 vectorA (1, 3, 2) 返回 (-1, -3, -2).
添加下面的代码：

```swift
static prefix func -(vector: Vector) -> Vector {
  return [-vector.x, -vector.y, -vector.z]
}
```
操作符默认是中缀类型，如果想改成其它类型，要在函数前指定运算的类型。符号运算不是中缀的，所以我们为它指定了前缀运算类型（prefix）。

下面实现向量的减法运算：
 
```swift
static func -(left: Vector, right: Vector) -> Vector {
  return left + -right
}
```

测试计算结果

```swift
vectorA - vectorB // (3, -2, 1)
```

###混合其它类型参数

你可以通过乘法叠加向量值，如果向量乘以 2，要对向量的每个元素乘以 2，下面就来实现它。

当实现向量加法操作时，不需要考虑参数顺序，因为两个参数都是向量类型。重载乘法操作实现标量乘法时，你需要考虑参数的顺序。`Int * Vector` 和 `Vector * Int` 属于两种不同的情况，如果只实现一种情况， Swift 编译器不会自动识别另一种情况。

```swift 
static func *(left: Int, right: Vector) -> Vector {
  return [right.x * left, right.y * left, right.z * left]
}

static func *(left: Vector, right: Int) -> Vector {
  return right * left
}
```

在数学里，向量还有一个有趣的运算操作：叉乘。因为在大部分情况下不推荐使用自定义操作符号，我们继续使用 `*` 实现叉乘。叉乘接受两个向量返回一个新的向量，具体实现如下：

```swift
static func *(left: Vector, right: Vector) -> Vector {
  return [left.y * right.z - left.z * right.y, left.z * right.x - left.x * right.z, left.x * right.y - left.y * right.x]
}
```
验证计算结果：

```swift
vectorA * 2 * vectorB // (-14, -10, 22)
```

###协议中的运算符重载

一些协议要求成员必须实现它的接口，如实现 `Equatable` 协议，就要实现它的 `==` 操作。类似的，`Comparable` 协议要求实现者至少要实现 `<` 和 `==`，因为 `Comparable` 继承自 `Equatable`。`Comparable` 的实现者可以有选择的实现 `>`、`>=` 和 `<=`，因为这些操作有默认的实现。

`Comparable` 对于向量没有意义，但是 `Equatable` 还是有用的，如果两个向量的元素都相等，那这两个向量就是相等的。为 `Vector` 添加 `Equatable` 协议：

```swift
struct Vector: ExpressibleByArrayLiteral, CustomStringConvertible, Equatable {
```
Xcode 会提示你 `Vector` 没有实现 `Equatable` 协议的 `==` 操作，添加下面的代码后提示会消失：

```swift
static func ==(left: Vector, right: Vector) -> Bool {
  return left.x == right.x && left.y == right.y && left.z == right.z
}
```
验证结果：

```swift
vectorA == vectorB // false
```
因为 `vectorA` 与 `vectorB` 不相同，所以返回 `false`。


##创建自定义运算符
上面提到过不推荐使用自定义符号么，但是总有例外。如果满足下面的两个要求，可以考虑使用自定义运算符：

* 运算符的含义众所周知，或者对于阅读代码的人有帮助
* 在键盘上很容易打出来

下面将要实现的运算符正好满足这两个条件。向量点乘运算接受两个向量返回意识标量值，点乘运算就是将两个向量中对应元素相乘，然后把乘积相加。

点乘符号是 `•`，使用 `Option + 8` 就能很方便的打出来。上面的教程都是重载运算符，因为那些运算符本来就存在。`•` 是个新的运算符，你必须先创建运算符。添加下面的声明：

```swift
infix operator •: AdditionPrecedence
```
这句代码把 `•` 定义为运算符，`infix` 表示要把它放在两个值中间使用，`AdditionPrecedence` 表明它的优先级和 `+` 一样。

现在操作符已经注册好了，添加下面的实现代码：

```swift
static func •(left: Vector, right: Vector) -> Int {
  return left.x * right.x + left.y * right.y + left.z * right.z
}
```
验证结果：

```swift
vectorA • vectorB // 15
```
看起来没什么问题了，试试添加下面这行代码：

```swift
vectorA • vectorB + vectorA // Error!
```
Xcode 报错了，为什么呢？
因为 `•` 和 `+` 有相同的优先级，编译器从左向右解析表达式，代码被解释成：

```swift
(vectorA • vectorB) + vectorA
```
这个表达式最终变成了 `Int + Vector`，我们并没有实现这个运算。

##优先级组

在 Swift 标准库中，运算符的优先级如下：

![](./operator_precedence.png)

有些运算符你以前可能没有见过，下面是一些注释：

1. 按位运算符 `<<` 和 `>>` 用于二进制计算
2. 类型转换符号 `is` 和 `as` 用于判断或者改变值类型
3. `??` 用于把可选类型转换为非可选类型
4. 如果你没有自定义运算符声明优先级，它会被分配一个默认优先级
5. 三元运算符 `? :` 的功能类似于 if-else 
6. `AssignmentPrecedence` 作为 `=` 的派生物，优先级其它的都低

###点乘的优先级
我们定义的点乘运算符不适用上表中的优先级，虽然它的优先级比加号低，但是它适合使用 `CastingPrecedence` 或者 `RangeFormationPrecedence` 吗？我们需要为它定义新的优先级。
使用下面的代码替换原来点乘运算的声明：

```swift
precedencegroup DotProductPrecedence {
  lowerThan: AdditionPrecedence
  associativity: left
}

infix operator •: DotProductPrecedence
```
我们创建了新的优先级 `DotProductPrecedence`，因为想让加法预算优先，所以把它的优先级设置得比 `AdditionPrecedence` 低。我们并且把它设成左结合的，是想让它像加法或者乘法运算一样从左往右进行运算。
使用之前的代码验证下：

```swift 
vectorA • vectorB + vectorA // 29
```

###原文
[Overloading Custom Operators in Swift
](https://www.raywenderlich.com/157556/overloading-custom-operators-swift)