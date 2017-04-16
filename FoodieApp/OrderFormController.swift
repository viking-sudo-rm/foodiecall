//
//  OrderFormController.swift
//  FoodieApp
//
//  Created by William Merrill on 4/14/17.
//  Copyright © 2017 SnorriDev. All rights reserved.
//

import Eureka

class OrderFormController: FormViewController {
    
    func readAPI() {
        
        var url = URL(string: "http://www.yalefoodiecall.com/api/buildings")
        URLSession.shared.dataTask(with:url!) { (data, response, error) in
            if error != nil {
                print(error ?? "stuff")
            } else {
                do {
                    
                    let buildings = try JSONSerialization.jsonObject(with: data!, options: []) as! [[String:String]]
                    
                    let pickerRow = self.form.rowBy(tag: "Building") as! PickerInlineRow<String>
                    for building in buildings {
                        pickerRow.options.append(building["display"]!)
                    }
                    
                } catch let error as NSError {
                    print(error)
                }
                
            }
            
        }.resume()
        
        url = URL(string: "http://www.yalefoodiecall.com/api/menu")
        URLSession.shared.dataTask(with:url!) { (data, response, error) in
            if error != nil {
                print(error ?? "stuff")
            } else {
                do {
                    
                    let menu = try JSONSerialization.jsonObject(with: data!, options: []) as! [[String:Any]]
                    
                    let orderSection = Section("Order")
                    for food in menu {
                        orderSection <<< StepperRow() {
                            $0.title = food["name"] as? String
                            $0.baseValue = 0
                            $0.displayValueFor = self.displayInt(d:)
                        }
                    }
                    self.form +++ orderSection
                    
                } catch let error as NSError {
                    print(error)
                }
                
            }
            
            }.resume()
        
        
    }
    
    func displayInt(d : Double?) -> String? {
        if (d == nil || d == 0) {
            return nil
        }
        return String(Int(d!))
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        form +++ Section("Contact Info")
            <<< TextRow(){ row in
                row.title = "Name"
                row.placeholder = "Name"
            }
            <<< EmailRow(){
                $0.title = "Email"
                $0.placeholder = "Email"
            }
            <<< PhoneRow(){
                $0.title = "Phone"
                $0.placeholder = "Phone"
            }
            +++ Section("Location")
            //should load from JSON
            <<< PickerInlineRow<String>("Building"){
                $0.title = "Building"
                $0.options = []
            }
            <<< TextRow(){
                $0.title = "Entryway"
                $0.placeholder = "Entryway"
            }
        
        readAPI()
        
    }
}
