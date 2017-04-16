//
//  WebViewController.swift
//  FoodieCall
//
//  Created by William Merrill on 4/10/17.
//  Copyright © 2017 SnorriDev. All rights reserved.
//

import UIKit

class WebViewController: UIViewController, UIWebViewDelegate {
    
    @IBOutlet weak var webView: UIWebView!
    
    // TODO remove button and have full splash screen:
    // http://stackoverflow.com/questions/18438248/how-to-keep-showing-splash-screen-until-webview-is-finished-loading-objective-c
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        webView.delegate = self
        if let url = URL(string: "http://foodiecall.herokuapp.com/mobile") {
            let request = URLRequest(url: url)
            webView.loadRequest(request)
        }
    }
}
