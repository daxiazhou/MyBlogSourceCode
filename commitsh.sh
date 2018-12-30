#! /bin/bash

#提交源码到Github
rm -rf _site
git add .
git commit -m "update at `date` "

git remote add origin git@github.com:daxiazhou/MyBlogSourceCode.git >> /dev/null 2>&1
echo "### Pushing Source to Github..."
git push origin master -f
echo "### Done"

#提交编译后的代码到Github
bundler exec jekyll clean
bundler exec jekyll build
cd _site

git init
git add .
git commit -m "update at `date` "

git remote add origin git@github.com:daxiazhou/daxiazhou.github.io.git >> /dev/null 2>&1
echo "### Pushing Source to Github..."
git push origin master -f
echo "### Done"
