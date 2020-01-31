
//  ViewController.swift
//  Loaner Laptop CheckOut
//
//  Created by Bob Gendler on 1/16/19.
//  Copyright © 2019 Bob Gendler. All rights reserved.
//

import Cocoa

var jamfUser: String?
var jamfPassword: String?
var jamfURL: String?
var acsID: String?
var availabilityID: String?
var checkInID: String?
var checkOutID: String?

struct advancedSearch: Decodable {
    let advanced_computer_search: acs
    
    struct acs: Decodable {
        let computers: [computers]
        
        struct computers: Decodable {
            let name: String
            let id: Int
            let DateCheckedIn: String
            let DateCheckedOut: String
            let LoanerAvailability: String
            let Username: String
            let Department: String
        }
    }
}

class computerObject {
    var name: String
    var id: Int
    var DateCheckedIn: String
    var DateCheckedOut: String
    var LoanerAvailability: String
    var Username: String
    var Department: String
    
    init(name: String, id: Int, DateReturned: String, DateOut: String, Availability: String, Username: String, Department: String) {
        self.name = name
        self.id = id
        self.DateCheckedIn = DateReturned
        self.DateCheckedOut = DateOut
        self.LoanerAvailability = Availability
        self.Username = Username
        self.Department = Department
    }
    
}

class ViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource {
    //var currentLogin: jamfLogin?
    
    var computerList = [computerObject]()
    var resultComputer = [NSTableCellView]()
    var resultUser = [NSTableCellView]()
    var datePickerOut = [NSDatePicker]()
    var datePickerIn = [NSDatePicker]()
    var actionButton = [NSButton]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        
        if UserDefaults.standard.string(forKey: "availabilityID") != nil || UserDefaults.standard.string(forKey: "checkOutID") != nil || UserDefaults.standard.string(forKey: "checkInID") != nil || UserDefaults.standard.string(forKey: "ACSID") != nil || UserDefaults.standard.string(forKey: "jss_URL") != nil {
            
            availabilityID = UserDefaults.standard.string(forKey: "availabilityID")
            checkOutID = UserDefaults.standard.string(forKey: "checkOutID")
            checkInID = UserDefaults.standard.string(forKey: "checkInID")
            acsID = UserDefaults.standard.string(forKey: "ACSID")
            jamfURL = UserDefaults.standard.string(forKey: "jss_URL")
            
            let keychainVar = try? keychainlogin(server: jamfURL!)
            if keychainVar != nil {
                jamfUser = (keychainVar?.KCUsername)!
                jamfPassword = (keychainVar?.KCPassword)!
                getJamfData(url: "\(jamfURL!)JSSResource/advancedcomputersearches/id/\(acsID!)")
            }
        } else {
            errorOccured(typeOfError: "Preferences required to be setup.")
            self.performSegue(withIdentifier: "preferencesSegue", sender: self)
            
        }
        
    }
    
    
    override var representedObject: Any? {
        didSet {
            
        }
    }
    
    @IBOutlet var tableView: NSTableView!
    
    func getJamfData(url: String){
        let loginData = "\(jamfUser!):\(jamfPassword!)".data(using: String.Encoding.utf8)
        let base64LoginString = loginData!.base64EncodedString()
        let headers = ["Accept": "application/json",
                       "Authorization": "Basic \(String(describing: base64LoginString))"]
        
        let request = NSMutableURLRequest(url: NSURL(string: url)! as URL,
                                          cachePolicy: .useProtocolCachePolicy,
                                          timeoutInterval: 10.0)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = headers
        
        let session = URLSession.shared
        
        let dataTask = session.dataTask(with: request as URLRequest) {data,response,error in
            let httpResponse = response as? HTTPURLResponse
            let dataReturn = data
            
            if (error != nil) {
                DispatchQueue.main.async {
                    self.errorOccured(typeOfError: "An Error Occured")
                }
            } else {
                do {
                    switch httpResponse!.statusCode {
                    case 401:
                        DispatchQueue.main.async {
                            self.errorOccured(typeOfError: "Login Error")
                        }
                        
                    case 400:
                        DispatchQueue.main.async {
                            self.errorOccured(typeOfError: "Bad Request")
                        }
                    case 404:
                        DispatchQueue.main.async {
                            self.errorOccured(typeOfError: "404, something not found")
                        }
                        
                    case 200:
                        self.computerList.removeAll()
                        
                        let decoder = JSONDecoder()
                        let computerData = try decoder.decode(advancedSearch.self, from: dataReturn!)
                        
                        for entries in computerData.advanced_computer_search.computers {
                            self.computerList.append(computerObject(name: entries.name, id: entries.id, DateReturned: entries.DateCheckedIn, DateOut: entries.DateCheckedOut, Availability: entries.LoanerAvailability, Username: entries.Username, Department: entries.Department))
                            
                        }
                        DispatchQueue.main.async {
                            self.tableView.reloadData()
                        }
                    default:
                        DispatchQueue.main.async {
                            self.errorOccured(typeOfError: "Unknown Error Occured")
                        }
                    }
                    
                    
                } catch {
                    DispatchQueue.main.async {
                        self.errorOccured(typeOfError: "An Unknown Error Occured. I must quit now. Goodbye!")
                        NSApplication.shared.terminate(self)
                    }
                }
            }
        }
        dataTask.resume()
    }
    
    func putJamfData(jamfID: Int, date: String, availability: String, username: String) {
        var xmldata: String
        
        let requestURL = "\(jamfURL!)JSSResource/computers/id/\(jamfID)"
        
        if availability == "Yes" {
            xmldata = "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\"?><computer><location><username></username><real_name></real_name><email_address></email_address><department></department></location><extension_attributes><extension_attribute><id>\(availabilityID!)</id><value>" + availability + "</value></extension_attribute><extension_attribute><id>\(checkInID!)</id><value>" + date + "</value></extension_attribute></extension_attributes></computer>"
        } else {
            xmldata = "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\"?><computer><location><username>" + username + "</username><real_name></real_name><email_address></email_address><department></department></location><extension_attributes><extension_attribute><id>\(availabilityID!)</id><value>" + availability + "</value></extension_attribute><extension_attribute><id>\(checkOutID!)</id><value>" + date + "</value></extension_attribute></extension_attributes></computer>"
        }
        
        let loginData = "\(jamfUser!):\(jamfPassword!)".data(using: String.Encoding.utf8)
        let base64LoginString = loginData!.base64EncodedString()
        let postData = NSData(data: xmldata.data(using: String.Encoding.utf8)!)
        let headers = ["Content-Type": "text/xml", "Authorization": "Basic \(String(describing: base64LoginString))"]
        let request = NSMutableURLRequest(url: NSURL(string: requestURL)! as URL,cachePolicy: .useProtocolCachePolicy,timeoutInterval: 10.0)
        request.httpMethod = "PUT"
        request.allHTTPHeaderFields = headers
        request.httpBody = postData as Data
        
        
        let dispatchGroup = DispatchGroup()
        dispatchGroup.enter()
        
        let session = URLSession.shared
        let dataTask = session.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) -> Void in
            
            dispatchGroup.leave()
        }
        )
        
        dataTask.resume()
        
        dispatchGroup.wait()
        
    }
    
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return computerList.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView?{
        let UIAppearance = UserDefaults.standard.string(forKey: "AppleInterfaceStyle") ?? "Light"
        if tableColumn?.title == "Computer"{
            
            resultComputer.append(tableView.makeView(withIdentifier: tableColumn!.identifier, owner: self) as! NSTableCellView)
            resultComputer[row].textField?.stringValue = computerList[row].name
            if computerList[row].LoanerAvailability != "Yes" {
                resultComputer[row].textField?.drawsBackground = true
                if UIAppearance == "Light" {
                    resultComputer[row].textField?.backgroundColor = NSColor(red: 0.98, green: 0.99, blue: 0.76, alpha: 1.0)
                } else {
                    resultComputer[row].textField?.backgroundColor  = NSColor(red: 0.35, green: 0.32, blue: 0.33, alpha: 1.0)
                }
            
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat =  "yyyy-MM-dd"
                let dateOut = dateFormatter.date(from: computerList[row].DateCheckedOut)
                var dateComponent = DateComponents()
                let weekSelected = UserDefaults.standard.integer(forKey: "alert")
                dateComponent.day = (weekSelected + 1) * 7
                if let dateOut = dateOut {
                    let dateThreeWeeksOut = Calendar.current.date(byAdding: dateComponent, to: dateOut)
                    let date = NSDate()
                    if dateThreeWeeksOut?.compare(date as Date) == .orderedAscending {
                        resultComputer[row].textField?.stringValue = "🚨\(resultComputer[row].textField!.stringValue)🚨"
                    }
                    
                }
                
            } else {
                resultComputer[row].textField?.drawsBackground = false
            }
            
            resultComputer[row].textField?.tag = computerList[row].id
            
            return resultComputer[row]
        }
        else if tableColumn?.title == "Username"{
            
            resultUser.append(tableView.makeView(withIdentifier: tableColumn!.identifier, owner: self) as! NSTableCellView)
            if computerList[row].LoanerAvailability != "Yes" {
                resultUser[row].textField?.isEditable = false
                resultUser[row].textField?.drawsBackground = true
                if UIAppearance == "Light" {
                    resultUser[row].textField?.backgroundColor = NSColor(red: 0.98, green: 0.99, blue: 0.76, alpha: 1.0)
                } else {
                    resultUser[row].textField?.backgroundColor = NSColor(red: 0.35, green: 0.32, blue: 0.33, alpha: 1.0)
                }
                
                resultUser[row].textField?.stringValue = computerList[row].Username
            } else {
                resultUser[row].textField?.isEditable = true
                resultUser[row].textField?.drawsBackground = false
                resultUser[row].textField?.stringValue = ""
            }
            
            
            return resultUser[row]
            
        }
        else if tableColumn?.title == "Checked Out"{
            datePickerOut.append(tableView.makeView(withIdentifier: tableColumn!.identifier, owner: self) as! NSDatePicker)
            
            if computerList[row].LoanerAvailability == "Yes" {
                
                datePickerOut[row].dateValue = Date()
                datePickerOut[row].drawsBackground = false
                datePickerOut[row].isEnabled = true
                datePickerOut[row].datePickerStyle = .textFieldAndStepper
                datePickerOut[row].datePickerMode = .single
                datePickerOut[row].isBordered = true
                datePickerOut[row].isBezeled = true
            } else {
                datePickerOut[row].isEnabled = false
                datePickerOut[row].drawsBackground = true
                datePickerOut[row].datePickerElements = .yearMonthDay
                datePickerOut[row].datePickerMode = .single
                datePickerOut[row].datePickerStyle = .textField
                datePickerOut[row].isBordered = false
                datePickerOut[row].isBezeled = false
                if UIAppearance == "Light" {
                    datePickerOut[row].backgroundColor = NSColor(red: 0.98, green: 0.99, blue: 0.76, alpha: 1.0)
                } else {
                    datePickerOut[row].backgroundColor = NSColor(red: 0.35, green: 0.32, blue: 0.33, alpha: 1.0)
                }
                
                
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat =  "yyyy-MM-dd"
                
                if let date = dateFormatter.date(from: computerList[row].DateCheckedOut) {
                    datePickerOut[row].dateValue = date
                }
                
            }
            
            return datePickerOut[row]
            
        } else if tableColumn?.title == "Checked In"{
            datePickerIn.append(tableView.makeView(withIdentifier: tableColumn!.identifier, owner: self) as! NSDatePicker)
            
            if computerList[row].LoanerAvailability == "Yes" {
                
                datePickerIn[row].isEnabled = false
                datePickerIn[row].datePickerElements = .yearMonthDay
                datePickerIn[row].datePickerMode = .single
                datePickerIn[row].datePickerStyle = .textField
                datePickerIn[row].isBordered = false
                datePickerIn[row].isBezeled = false
                
                
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat =  "yyyy-MM-dd"
                
                if let date = dateFormatter.date(from: computerList[row].DateCheckedIn) {
                    datePickerIn[row].dateValue = date
                }
                
                
            } else {
                datePickerIn[row].isHidden = false
                datePickerIn[row].isBordered = true
                datePickerIn[row].isBezeled = true
                datePickerIn[row].dateValue = Date()
                datePickerIn[row].isEnabled = true
                datePickerIn[row].datePickerMode = .single
                datePickerIn[row].datePickerStyle = .textFieldAndStepper
            }
            
            return datePickerIn[row]
            
        } else {
            
            actionButton.append(tableView.makeView(withIdentifier: tableColumn!.identifier, owner: self) as! NSButton)
            if computerList[row].LoanerAvailability != "Yes" {
                actionButton[row].title = "Check In"
                
            } else {
                actionButton[row].title = "Check Out"
            }
            
            actionButton[row].isEnabled = false
            
            return actionButton[row]
        }
        
    }
    
    
    var lastSelected = -1
    func tableViewSelectionDidChange(_ notification: Notification) {
        if tableView.selectedRow != -1 {
            if lastSelected != -1 {
                actionButton[lastSelected].isEnabled = false
            }
            
            actionButton[tableView.selectedRow].isEnabled = true
            lastSelected = tableView.selectedRow
            
        }
    }
    
    
    var selectedRow = 0
    @IBAction func functionButton(_ sender: NSButtonCell) {
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        selectedRow = tableView.selectedRow
        if !actionButton.indices.contains(tableView.selectedRow) {
            
            return
        }
        if actionButton[tableView.selectedRow].title == "Check Out" {
            
            let dateOut = formatter.string(from: datePickerOut[tableView.selectedRow].dateValue)
            
            putJamfData(jamfID: (resultComputer[tableView.selectedRow].textField?.tag)!, date: dateOut, availability: "No", username: resultUser[selectedRow].textField!.stringValue)
            
            
        } else {
            
            resultComputer[tableView.selectedRow].textField?.drawsBackground = false
            resultUser[tableView.selectedRow].textField?.drawsBackground = false
            datePickerOut[tableView.selectedRow].drawsBackground = false
            
            let dateIn = formatter.string(from: datePickerIn[tableView.selectedRow].dateValue)
            
            putJamfData(jamfID: (resultComputer[tableView.selectedRow].textField?.tag)!, date: dateIn, availability: "Yes", username: "")
            
            
        }
        getJamfData(url: "\(jamfURL!)JSSResource/advancedcomputersearches/id/\(acsID!)")
        
    }
    
    @IBAction func preferencesMenuItemSelected(_ sender: Any) {
        
    }
    
    @IBAction func refreshMenuItemSelected(_ sender: Any) {
        
        if UserDefaults.standard.string(forKey: "availabilityID") != nil || UserDefaults.standard.string(forKey: "checkOutID") != nil || UserDefaults.standard.string(forKey: "checkInID") != nil || UserDefaults.standard.string(forKey: "ACSID") != nil || UserDefaults.standard.string(forKey: "jss_URL") != nil {
            
            availabilityID = UserDefaults.standard.string(forKey: "availabilityID")
            checkOutID = UserDefaults.standard.string(forKey: "checkOutID")
            checkInID = UserDefaults.standard.string(forKey: "checkInID")
            acsID = UserDefaults.standard.string(forKey: "ACSID")
            jamfURL = UserDefaults.standard.string(forKey: "jss_URL")
            
            if UserDefaults.standard.bool(forKey: "keychainCheck") == true {
                let keychainVar = try? keychainlogin(server: jamfURL!)
                if keychainVar != nil {
                    jamfUser = (keychainVar?.KCUsername)!
                    jamfPassword = (keychainVar?.KCPassword)!
                    getJamfData(url: "\(jamfURL!)JSSResource/advancedcomputersearches/id/\(acsID!)")
                    
                }
            } else {
                if jamfUser == nil || jamfPassword == nil {
                    errorOccured(typeOfError: "Username and Password Required")
                } else {
                    getJamfData(url: "\(jamfURL!)JSSResource/advancedcomputersearches/id/\(acsID!)")
                }
                
                
            }
            
        }
        
    }
    
    func errorOccured(typeOfError: String){
        let alert = NSAlert()
        alert.messageText = "Error"
        alert.informativeText = typeOfError
        alert.runModal()
    }
    func keychainlogin(server: String) throws -> (KCUsername: String, KCPassword: String) {
        let query: [String: Any] = [kSecClass as String: kSecClassInternetPassword,
                                    kSecAttrServer as String: server,
                                    kSecMatchLimit as String: kSecMatchLimitOne,
                                    kSecReturnAttributes as String: true,
                                    kSecReturnData as String: true]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status != errSecItemNotFound else { throw KeychainError.noPassword }
        guard status == errSecSuccess else { throw KeychainError.unhandledError(status: status) }
        
        guard let existingItem = item as? [String : Any],
            let passwordData = existingItem[kSecValueData as String] as? Data,
            let keychainpassword = String(data: passwordData, encoding: String.Encoding.utf8),
            let keychainaccount = existingItem[kSecAttrAccount as String] as? String
            else {
                throw KeychainError.unexpectedPasswordData
        }
        
        return(keychainaccount, keychainpassword)
    }
    
}


