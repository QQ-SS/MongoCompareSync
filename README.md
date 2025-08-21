# MongoCompareSync

## Description
这是一个使用腾讯 [CodeBuddy IDE](https://www.codebuddy.ai/) 开发的MongoDB增量同步工具。

它使用 [Flutter](https://flutter.dev/) 开发，支持 MacOS、Windows 平台。

实现了对任意两个 [MongoDB](https://www.mongodb.com/) 数据库之间的任意集合进行数据比较与同步，包括增删查改等操作，同时可以根据自定义的规则可以忽略掉文档中某些属性的比较。