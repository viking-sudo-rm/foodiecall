//
//  LoadingController.swift
//  FoodieApp
//
//  Created by William Merrill on 4/20/17.
//  Copyright © 2017 SnorriDev. All rights reserved.
//

import UIKit

class LoadingController : UIViewController {
    
    @IBOutlet var activityIndicator : UIActivityIndicatorView?;
    
    override func viewDidLoad() {
        self.activityIndicator?.startAnimating()
    }
    
}
