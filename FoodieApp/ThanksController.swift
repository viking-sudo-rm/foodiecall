//
//  ThanksController.swift
//  FoodieApp
//
//  Created by William Merrill on 4/19/17.
//  Copyright © 2017 SnorriDev. All rights reserved.
//

import UIKit

class ThanksController : UIViewController {
    
    let SURVEY_URL = "https://goo.gl/forms/LC2l2EaWJ3lVCJgT2"
    let FACEBOOK_URL = "https://www.facebook.com/yalefoodiecall/"
    
    @IBAction func backToTitle(sender: AnyObject) {
        let c = [self.navigationController?.viewControllers[0]] as! [UIViewController]
        self.navigationController?.setViewControllers(c, animated: true)
    }
    
    @IBAction func surveyLink(sender: AnyObject) {
        webLink(urlString: self.SURVEY_URL)
    }
    
    @IBAction func facebookLink(sender: AnyObject) {
        webLink(urlString: self.FACEBOOK_URL)
    }
    
    func webLink(urlString: String) {
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    
    
}
