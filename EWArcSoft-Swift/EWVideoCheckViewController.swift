//
//  EWVideoCheckViewController.swift
//  EWArcSoft-Swift
//
//  Created by Ethan.Wang on 2018/12/21.
//  Copyright © 2018 Ethan. All rights reserved.
//

import UIKit
import AVFoundation
import CoreMotion

let IMAGE_WIDTH = 720
let IMAGE_HEIGHT = 1280

/// 人脸识别页面控制器
class EWVideoCheckViewController: UIViewController {
    /// 陀螺仪传感器Manager
    private let motionManager: CMMotionManager = CMMotionManager()
    /// 根据takePhoto状态来决定拍照
    private var takePhone: Bool = false
    /// 拍照后结果展示圆形ImageView
    private let showImageView: UIImageView = {
        let imageView = UIImageView(frame: CGRect(x: (UIScreen.main.bounds.size.width - 230)/2, y: 231, width: 230, height: 230))
        imageView.layer.cornerRadius = 115
        imageView.layer.masksToBounds = true
        imageView.contentMode = .center
        return imageView
    }()
    /// 拍照后背景半透明View
    private lazy var imageBackView: UIImageView = {
        let imageView = UIImageView(frame: UIScreen.main.bounds)
        imageView.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        imageView.isHidden = true
        imageView.addSubview(showImageView)
        return imageView
    }()
    /// 扫描框ImageView
    private let scanningImageView: UIImageView = {
        let imageView = UIImageView(frame: CGRect(x: (UIScreen.main.bounds.size.width - 230)/2, y: 231, width: 230, height: 230))
        imageView.image = UIImage(named: "scanning")
        return imageView
    }()
    /// 摄像机控制器
    private var cameraController: EWCameraController = EWCameraController()
    /// 虹软进行人脸识别分析的工具
    private var videoProcessor: ASFVideoProcessor = ASFVideoProcessor()
    /// 装载所有人脸信息框的Array
    private var allFaceRectViewArray: [UIView] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        /// 初始化陀螺仪传感器
        startMotionManager()
        /// 将设备方向赋给cameraController
        let uiOrientation = UIApplication.shared.statusBarOrientation
        cameraController.delegate = self
        cameraController.setUpCaptureSession(videoOrientation: AVCaptureVideoOrientation(ui:uiOrientation))
        /// 将摄影类layer置于控制器前
        guard self.cameraController.previewLayer != nil else { return }
        self.view.layer.addSublayer(self.cameraController.previewLayer!)
        self.cameraController.previewLayer?.frame = self.view.layer.frame
        /// 虹软识别控制器初始化
        videoProcessor.initProcessor()
        /// 波纹发散动画View
        let animationView = EWRippleAnimationView(frame:CGRect(x: 0, y: 0, width: self.showImageView.frame.size.width , height: self.showImageView.frame.size.height))
        animationView.center = self.showImageView.center
        self.imageBackView.addSubview(animationView)
        self.imageBackView.bringSubviewToFront(self.showImageView)

        self.view.addSubview(imageBackView)
        self.view.addSubview(scanningImageView)

    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.cameraController.startCaptureSession()
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.cameraController.stopCaptureSession()
    }
    /// 将虹软获取的人脸rect转换成CRRect类型
    private func dataFaceRectToViewFaceRect(faceRect: MRECT) -> CGRect {
        var frameRect: CGRect = CGRect.zero
        let viewFrame = self.view.frame
        let faceWidth = faceRect.right - faceRect.left
        let faceHeight = faceRect.bottom - faceRect.top
        frameRect.size.width = viewFrame.width/CGFloat(IMAGE_WIDTH)*CGFloat(faceWidth)
        frameRect.size.height = viewFrame.height/CGFloat(IMAGE_HEIGHT)*CGFloat(faceHeight)
        frameRect.origin.x = viewFrame.width/CGFloat(IMAGE_WIDTH)*CGFloat(faceRect.left)
        frameRect.origin.y = viewFrame.height/CGFloat(IMAGE_HEIGHT)*CGFloat(faceRect.top)
        return frameRect
    }
    /// 开始陀螺仪判断
    private func startMotionManager() {
        motionManager.startGyroUpdates()
    }
    /// 根据CMSampleBuffer媒体文件获取相片
    private func getImageFromSampleBuffer (buffer:CMSampleBuffer) -> UIImage? {
        if let pixelBuffer = CMSampleBufferGetImageBuffer(buffer) {
            let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
            let context = CIContext()
            let imageRect = CGRect(x: 0, y: 0, width: CVPixelBufferGetWidth(pixelBuffer), height: CVPixelBufferGetHeight(pixelBuffer))
            if let image = context.createCGImage(ciImage, from: imageRect) {
                return UIImage(cgImage: image, scale: UIScreen.main.scale, orientation: .up)
            }
        }
        return nil
    }
    /// 进行人脸识别结果筛选
    private func faceInfoScreening(faceInfo: ASFVideoFaceInfo) -> Bool {
        //// 判断face3DAngle,保证人脸正对摄像头
        guard faceInfo.face3DAngle != nil else {
            return false
        }
        guard faceInfo.face3DAngle.status == 0 else {
            return false
        }
        guard faceInfo.face3DAngle.rollAngle <= 10 && faceInfo.face3DAngle.rollAngle >= -10 else {
            return false
        }
        guard faceInfo.face3DAngle.yawAngle <= 10 && faceInfo.face3DAngle.yawAngle >= -10 else {
            return false
        }
        guard faceInfo.face3DAngle.pitchAngle <= 10 && faceInfo.face3DAngle.pitchAngle >= -10 else {
            return false
        }
        /// 判断陀螺仪实时加速度,保证手机在尽量平稳的状态
        guard let newestAccel = self.motionManager.gyroData else {
            return false
        }
        guard newestAccel.rotationRate.x < 0.000005 && newestAccel.rotationRate.y < 0.000005 && newestAccel.rotationRate.z < 0.000005 else {
            return false
        }
        return true
    }
}

extension EWVideoCheckViewController: EWCameraControllerDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if takePhone == false {
            /// 获取数据传入虹软人面识别控制器
            guard let cameraData = Utility.getCameraData(from: sampleBuffer) else {              return }
            guard let faceInfoArray = self.videoProcessor.process(cameraData) as? [ASFVideoFaceInfo] else {
                Utility.freeCameraData(cameraData)
                return
            }
            DispatchQueue.main.async { [weak self] in
                guard let weakSelf = self else {
                    Utility.freeCameraData(cameraData)
                    return
                }
                /// 获取人脸view数组是为了判断rect
                if weakSelf.allFaceRectViewArray.count < faceInfoArray.count {
                    for _ in faceInfoArray {
                        let view = UIView()
                        weakSelf.view.addSubview(view)
                        weakSelf.allFaceRectViewArray.append(view)
                    }
                }
                for index in faceInfoArray.indices {
                    let faceRectView: UIView = weakSelf.allFaceRectViewArray[index]
                    let faceInfo: ASFVideoFaceInfo = faceInfoArray[index]
                    faceRectView.frame = weakSelf.dataFaceRectToViewFaceRect(faceRect: faceInfo.faceRect)
                    guard weakSelf.faceInfoScreening(faceInfo: faceInfo) == true else {
                        break
                    }
                    /// 判断人脸View.frame,保证人脸在扫描框中
                    guard CGRect(x: 30, y: 150, width: UIScreen.main.bounds.size.width - 60, height: UIScreen.main.bounds.size.height-300).contains(faceRectView.frame) else {
                            break
                    }
                    /// 全部条件满足,则拍照.
                    weakSelf.takePhone = true
                    /// 将数据转换成UIImage
                    let resultImage = weakSelf.getImageFromSampleBuffer(buffer: sampleBuffer)
                    /// 将预览View展示,把结果image加入预览ImageView
                    weakSelf.imageBackView.isHidden = false
                    weakSelf.showImageView.image = resultImage
                    /// 添加一个缩小动画,并在动画结束后跳转到新页面
                    UIView.animate(withDuration: 1.3, animations: {
                        weakSelf.showImageView.transform = CGAffineTransform(scaleX: 0.7, y: 0.7)
                    }, completion: { (_) in
                        let vc = EWShowImageViewController()
                        vc.image = resultImage
                        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 2.0, execute: {
                            weakSelf.present(vc, animated: false, completion: nil)
                        })
                    })
                }
            }
            /// 释放内存!!! 重要!!!
            Utility.freeCameraData(cameraData)
        }
    }
}
