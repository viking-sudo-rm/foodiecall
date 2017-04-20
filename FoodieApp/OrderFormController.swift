//
//  OrderFormController.swift
//  FoodieApp
//  Main file with all the form logic and API data.
//
//  Created by William Merrill on 4/14/17.
//  Copyright © 2017 SnorriDev. All rights reserved.
//

import Eureka

class OrderFormController: FormViewController {
    
    var priceFormatter = NumberFormatter()
    
    // TODO should probably add a struct to hold foods
    // and just have a list of those
    // can put quantity in each struct and do something like the following:
    // http://codelle.com/blog/2016/5/an-easy-way-to-convert-swift-structs-to-json/
    
    var prices : [String:NSNumber] = [:]
    var restaurants : [String:String] = [:]
    var quantities : [String:NSNumber] = [:]
    
    // list with buildings sorted
    var buildings : [String] = []
    var clusters : [String:NSNumber] = [:]
    
    var formValid = false
    
    // for validation
    let CHECK_ROWS_NON_NIL = ["name", "email", "phone", "building", "entryway"]
    
    func initialize() {
        priceFormatter.numberStyle = .currency
    }
    
    // read the data we need from the server and add it to the form
    func readAPI() {
        
        var url = URL(string: "http://www.yalefoodiecall.com/api/buildings")
        URLSession.shared.dataTask(with:url!) { (data, response, error) in
            if error != nil {
                print(error ?? "stuff")
            } else {
                
                DispatchQueue.main.async(execute: {
                
                    do {
                        
                        let buildings = try JSONSerialization.jsonObject(with: data!, options: []) as! [[String:Any]]
                        
                        
                        for building in buildings {
                            self.buildings.append(building["display"]! as! String)
                            self.clusters[building["display"]! as! String] = building["cluster"]! as? NSNumber
                        }
                        
                        let pickerRow = self.form.rowBy(tag: "building") as! PickerInlineRow<String>
                        pickerRow.updateCell()
                        
                    } catch let error as NSError {
                        print(error)
                    }
                
                })
                    
            }
            
        }.resume()
        
        url = URL(string: "http://www.yalefoodiecall.com/api/menu")
        URLSession.shared.dataTask(with:url!) { (data, response, error) in
            if error != nil {
                print(error ?? "got error")
            } else {
                
                DispatchQueue.main.async(execute: {
                
                    do {
                        
                        let menu = try JSONSerialization.jsonObject(with: data!, options: []) as! [[String:Any]]
                        
                        let orderSection = Section("order")
                        for food in menu {
                            
                            self.prices[food["name"] as! String] = food["price"] as? NSNumber
                            self.restaurants[food["name"] as! String] = food["restaurant"] as? String
                            
                            orderSection <<< StepperRow(food["name"] as? String) {
                                $0.title = (food["name"] as! String) + " (" + self.priceFormatter.string(from: food["price"] as! NSNumber)! + ")"
                                $0.baseValue = 0
                                $0.displayValueFor = self.displayInt(d:)
                                }.onChange { row in // value is correctly set
                                    self.quantities[row.tag!] = row.value! as NSNumber
                                    self.recalcSubtotal()
                                    self.recalcSavings()
                                    self.recalcTotal()
                                    self.changeValidationEvent()
                                }
                        }
                        
                        self.form +++ orderSection
                        +++ Section("Checkout")
                        <<< DecimalRow("subtotal") {
                            $0.disabled = true
                            $0.title = "Subtotal"
                            $0.value = 0.0
                            $0.displayValueFor = self.priceFormatter.string
                        }
                        <<< DecimalRow("savings") {
                                $0.disabled = true
                                $0.title = "Savings"
                                $0.value = 0.0
                                $0.displayValueFor = self.priceFormatter.string
                        }
                        <<< DecimalRow("total") {
                                $0.disabled = true
                                $0.title = "You pay"
                                $0.value = 0.0
                                $0.displayValueFor = self.priceFormatter.string
                        }
                        <<< ButtonRow("submit") {
                            $0.title = "Order"
                            $0.disabled = Condition.function([], { (form) -> Bool in
                                return !self.formValid
                            })
                        }
                        .onCellSelection {  cell, row in
                            if !row.isDisabled {
                                self.postForm()
                                print("form submitted")
                            }
                        }
                        
                        self.tableView.reloadData()
                        
                    } catch let error as NSError {
                        print(error)
                    }
                    
                })
                
            }
            
        }.resume()
        
    }
    
    // post the JSON-encoded form data to the server
    func postForm() {
        
        // setup the request
        var request = URLRequest(url: URL(string: "http://www.yalefoodiecall.com/api/order")!)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        let loadingController = self.storyboard?.instantiateViewController(withIdentifier: "loadingController")
        self.navigationController?.pushViewController(loadingController!, animated: true)
        print("pushed loadingController")
        
        let formData = self.form.values()
        do {
            
            // put quantities in the correct format
            let quantities = self.quantities.filter({$0.value != 0}).map({key, value in
                ["food":key, "quantity":value, "restaurant":self.restaurants[key] ?? "None"] as NSDictionary
            })
            
            let parameters = ["source": "mobileApp",
                              "name": formData["name"]!!,
                              "email": formData["email"] as! String,
                              "phone": formData["phone"]!!,
                              "building": formData["building"]!!,
                              "cluster": self.clusters[formData["building"] as! String]!,
                              "entryway": formData["entryway"] as! String,
                              "total": formData["total"] as! NSNumber!,
                              "order": quantities as NSArray] as NSDictionary
            
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted)
            
        } catch let error {
            print("could not validate form data")
            print(error.localizedDescription)
        }
        
        URLSession.shared.dataTask(with: request as URLRequest, completionHandler: { data, response, error in
            
            guard error == nil else {
                return
            }
            
            guard let data = data else {
                return
            }
            
            do {
                
                // interpret response from server as JSON
                if let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: Any] {
                    
                    print("got response:")
                    print(json)
                    
                    let thanksController = self.storyboard?.instantiateViewController(withIdentifier: "thanksController") as! ThanksController
                    self.navigationController?.pushViewController(thanksController, animated: true)
                    print("pushed thanksController")
                    
                }
                
            } catch let error {
                print(error.localizedDescription)
            }
        }).resume()
        
    }
    
    // don't call this directly
    func checkFormValid() {
        self.formValid = true
        for rowName in self.CHECK_ROWS_NON_NIL {
            let row = self.form.rowBy(tag: rowName)
            if row == nil || !(row?.isValid)! || row?.baseValue == nil {
                self.formValid = false
                return
            }
        }
        
        if self.form.rowBy(tag: "total") == nil {
            return
        }
        
        let total = self.form.rowBy(tag: "total") as! DecimalRow
        if total.value == nil || total.value == 0 {
            self.formValid = false
        }
        
    }
    
    // call this directly
    func changeValidationEvent() {
        self.checkFormValid()
        let submit = self.form.rowBy(tag: "submit")
        if submit != nil {
            submit?.evaluateDisabled()
            submit?.updateCell()
        }
    }
    
    func displayInt(d : Double?) -> String? {
        if (d == nil || d == 0) {
            return nil
        }
        return String(Int(d!))
    }
    
    func recalcSubtotal() {
        var orderSubtotal : Double = 0
        for food in self.quantities.keys {
            orderSubtotal += (self.prices[food] as! Double) * (self.quantities[food] as! Double)
        }
        let subtotalRow = self.form.rowBy(tag: "subtotal") as! DecimalRow
        subtotalRow.value = orderSubtotal
        subtotalRow.updateCell()
    }
    
    func recalcSavings() {
        var totalOrders : Double = 0
        for food in self.quantities.keys {
            totalOrders += self.quantities[food] as! Double
        }
        let savingsRow = self.form.rowBy(tag: "savings") as! DecimalRow
        savingsRow.value = totalOrders > 1 ? totalOrders - 1 : 0
        savingsRow.updateCell()
    }
    
    func recalcTotal() {
        let totalRow = self.form.rowBy(tag: "total") as! DecimalRow
        let subtotalRow = self.form.rowBy(tag: "subtotal") as! DecimalRow
        let savingsRow = self.form.rowBy(tag: "savings") as! DecimalRow
        totalRow.value = subtotalRow.value! - savingsRow.value!
        totalRow.updateCell()
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        initialize()
        
        form +++ Section("Contact Info")
            <<< TextRow("name"){ row in
                row.title = "Name"
                row.placeholder = "Name"
                row.add(rule: RuleRequired())
                row.validationOptions = .validatesOnChange
            }
            .cellUpdate { cell, row in
                if !row.isValid {
                    cell.titleLabel?.textColor = .red
                }
            }
            .onRowValidationChanged { row in
                self.changeValidationEvent()
            }
            <<< EmailRow("email"){
                $0.title = "Email"
                $0.placeholder = "Email"
                $0.add(rule: RuleEmail())
                $0.validationOptions = .validatesOnChange
            }
            .cellUpdate { cell, row in
                if !row.isValid {
                        cell.titleLabel?.textColor = .red
                }
            }
            .onRowValidationChanged { row in
                self.changeValidationEvent()
            }
            <<< PhoneRow("phone"){
                $0.title = "Phone"
                $0.placeholder = "Phone"
                $0.add(rule: RuleRequired())
                $0.validationOptions = .validatesOnChange
            }
            .cellUpdate { cell, row in
                if !row.isValid {
                    cell.titleLabel?.textColor = .red
                }
            }
            .onRowValidationChanged { row in
                self.changeValidationEvent()
            }
            <<< PickerInlineRow<String>("building"){
                $0.title = "Building"
                $0.options = []
                $0.add(rule: RuleRequired())
                $0.validationOptions = .validatesOnChange
            }.cellUpdate { cell, row in
                row.options = self.buildings
            }
            .onRowValidationChanged { row in
                self.changeValidationEvent()
            }
            <<< TextRow("entryway"){
                $0.title = "Entryway"
                $0.placeholder = "Entryway"
                $0.add(rule: RuleRequired())
                $0.validationOptions = .validatesOnChange
            }
            .onRowValidationChanged { row in
                self.changeValidationEvent()
            }
            .cellUpdate { cell, row in
                if !row.isValid {
                    cell.titleLabel?.textColor = .red
                }
            }
        
        readAPI()
        
    }
}
