//
//  EWRippleAnimationView.swift
//  EWArcSoft-Swift
//
//  Created by Ethan.Wang on 2018/12/21.
//  Copyright © 2018 Ethan. All rights reserved.
//

import UIKit

let pulsingCount = 3
let multiple = 1.4
let animationDuration = 3

class EWRippleAnimationView: UIView {

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.clear
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ rect: CGRect) {
        let animationLayer = CALayer()
        for i in 0..<pulsingCount {
            let animationArray = self.getAnimationArray()
            let animationGroup: CAAnimationGroup = self.getAnimationGroupAnimations(array: animationArray, index: i)
            let pulsingLayer = self.pulsingLayer(rect: rect, animation: animationGroup)
            animationLayer.addSublayer(pulsingLayer)
        }
        self.layer.addSublayer(animationLayer)
    }

    private func getAnimationGroupAnimations(array: Array<CAAnimation>, index: Int) -> CAAnimationGroup{
        let defaultCurve = CAMediaTimingFunction(name: .default)
        let animationGroup = CAAnimationGroup()
        animationGroup.fillMode = .backwards
        animationGroup.beginTime = CACurrentMediaTime() + Double(index*animationDuration / pulsingCount)
        animationGroup.duration = CFTimeInterval(animationDuration)
        animationGroup.repeatCount = HUGE
        animationGroup.timingFunction = defaultCurve
        animationGroup.animations = array
        animationGroup.isRemovedOnCompletion = false
        return animationGroup
    }


    private func pulsingLayer(rect: CGRect, animation animationGroup: CAAnimationGroup) -> CALayer{
        let pulsingLayer = CALayer()
        pulsingLayer.frame = CGRect(x: 0, y: 0, width: rect.size.width, height: rect.size.height)
        pulsingLayer.backgroundColor = UIColor(red: 255/255, green: 216/255, blue: 87/255, alpha: 0.5).cgColor
        pulsingLayer.borderWidth = 0.5
        pulsingLayer.borderColor = UIColor(red: 255/255, green: 216/255, blue: 87/255, alpha: 0.5).cgColor
        pulsingLayer.cornerRadius = rect.size.height/2
        pulsingLayer.add(animationGroup, forKey: "plulsing")
        return pulsingLayer
    }

    private func getAnimationArray() -> Array<CAAnimation>{
        var animationArray: [CAAnimation]
        let scaleAnimation = self.getScaleAnimation()
        let borderColorAnimation = self.getBorderColorAnimation()
        let backgroundColorAnimation = self.getBackgroundColorAnimation()
        animationArray = [scaleAnimation,borderColorAnimation,backgroundColorAnimation]
        return animationArray
    }

    private func getBorderColorAnimation() -> CAKeyframeAnimation{
        let borderColorAnimation = CAKeyframeAnimation()
        borderColorAnimation.keyPath = "borderColor"
        borderColorAnimation.values = [UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 0.5).cgColor,
                                       UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 0.5).cgColor,
                                       UIColor(red: 255/255, green: 255/255,blue: 255/255, alpha: 0.5).cgColor,
                                       UIColor(red: 255/255, green: 255/255,blue: 255/255, alpha: 0).cgColor]
        borderColorAnimation.keyTimes = [0.3,0.6,0.9,1]
        return borderColorAnimation
    }

    private func getScaleAnimation() -> CABasicAnimation{
        let scaleAnimation = CABasicAnimation(keyPath: "transform.scale")
        scaleAnimation.fromValue = 1
        scaleAnimation.toValue = multiple
        return scaleAnimation
    }

    private func getBackgroundColorAnimation() -> CAKeyframeAnimation {
        let backgroundColorAnimation = CAKeyframeAnimation()
        backgroundColorAnimation.keyPath = "backgroundColor"
        backgroundColorAnimation.values = [UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 0.5).cgColor,
                                          UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 0.5).cgColor,
                                          UIColor(red: 255/255, green: 255/255,blue: 255/255, alpha: 0.5).cgColor,
                                          UIColor(red: 255/255, green: 255/255,blue: 255/255, alpha: 0).cgColor]
        backgroundColorAnimation.keyTimes = [0.3,0.6,0.9,1]
        return backgroundColorAnimation
    }

}
