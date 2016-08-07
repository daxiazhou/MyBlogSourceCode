---
layout: post
title: AutoLayout 和 Masonry
date: 2016-08-8 00:03:24.000000000 +09:00
---


#AutoLayout 和 Masonry

#AutoLayout

##什么是约束（Constraint）？
[Auto Layout Guide](https://developer.apple.com/library/prerelease/content/documentation/UserExperience/Conceptual/AutolayoutPG/AnatomyofaConstraint.html#//apple_ref/doc/uid/TP40010853-CH9-SW1) 给出的解释: *Each constraint represents a single equation.*

![image](../images/AutoLayoutAndMasonry/ConstraintEquation.png =600x)

这个Constraint声明红色视图与蓝色视图间距为8。不仅可以在两个视图之间的属性设置Constraint，还可以在一个视图的两个不同属性之间设置Constraint，如视图的height与weight成一定比例。常用的AutoLayout属性如下图所示：

![image](../images/AutoLayoutAndMasonry/AutoLayoutAttributes.png =400x)

##2. Intrinsic Content Size

Intrinsic Content Size依赖于视图的当前内容，如Button和Label的intrinsic content size依赖于它展示字符数量和字体大小。有些视图的intrinsic content size比较复杂，如ImageView，没有图片是就没有intrinsic content size，当添加了图片后intrinsic content size立刻变成当前图片的大小。AutoLayout使用一对Constraint从两个维度表现ntrinsic content size。

![image](../images/AutoLayoutAndMasonry/IntrinsicContentSize.png =400x)

* Content Hugging: 使视图不向外扩张
* Compression Resistance: 保持视图大小不被压缩
并不是所有的视图都有 intrinsic content size。
![image](../images/AutoLayoutAndMasonry/CommonControls.png =600x)


#Masnary
Masonry 是一个轻量级的布局框架，使用优雅的链式语法封装自动布局，使用方便，可提高手写布局的开发效率。它提供了三个主要的API：

	- (NSArray *)mas_makeConstraints:(void(^)(MASConstraintMaker *make))block;
	- (NSArray *)mas_updateConstraints:(void(^)(MASConstraintMaker *make))block;
	- (NSArray *)mas_remakeConstraints:(void(^)(MASConstraintMaker *make))block;

* **mas_makeConstraints**: 只负责新增约束 Autolayout 不能同时存在两条针对于同一对象的约束 否则会报错
* **mas_updateConstraints**: 针对上面的情况，会更新在block中出现的约束，不会导致出现两个相同约束的情况
* **mas_remakeConstraints**: 清除之前的所有约束，仅保留最新的约束


##4. 系统更新Constraints的方法

* updateConstraints
* updateConstraintsIFNeeded
* setNeedsUpdateConstraints

