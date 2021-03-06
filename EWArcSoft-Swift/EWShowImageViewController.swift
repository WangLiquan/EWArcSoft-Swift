//
//  EWShowImageViewController.swift
//  EWArcSoft-Swift
//
//  Created by Ethan.Wang on 2018/12/21.
//  Copyright © 2018 Ethan. All rights reserved.
//

import UIKit

class EWShowImageViewController: UIViewController {

    public var image: UIImage?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.white
        let imageView = UIImageView(frame: UIScreen.main.bounds)
        imageView.image = image
        imageView.layer.cornerRadius = 80.5
        imageView.layer.masksToBounds = true
        imageView.contentMode = .scaleAspectFill
        self.view.addSubview(imageView)
    }

}
