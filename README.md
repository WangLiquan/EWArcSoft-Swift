# EWArcSoft-Swift
<h3>Swift版本的虹软面部识别ArcFace2.0SDK接入</h3>

# 实现功能:

开启前置摄像头获取稳定人脸信息后截图并跳转至另一控制器

# 实现步骤:

1. 在官方注册账号,注册App,并下载SDK.

2. 添加bright文件.

3. 在.info文件中添加权限提示字段,

4. 加入必需框架

5. 将一个文件的后缀名改为.mm

6. 激活引擎

7. 使用AVFondation框架,实现CameraController,开启前置摄像头,并创建数据回调delegate

8. 新建VideoCheckViewController,实现页面.

9. 添加陀螺仪判断,以保证照片清晰度

10. 在delegate回调中实现主要功能.


<br>

![效果图预览](https://github.com/WangLiquan/EWArcSoftDemo/raw/master/images/demonstration.gif)

