
//  PrefsViewController.swift
//  Loaner Laptop CheckOut
//
//  Created by Robert Gendler on 2/2/19.
//  Copyright © 2019 Bob Gendler. All rights reserved.
//

import Cocoa

enum KeychainError: Error {
    case noPassword
    case unexpectedPasswordData
    case unhandledError(status: OSStatus)
}

class jssLogin {
    var username: String?
    var password: String?
    var keychain: Bool?
}

struct Preferences: Codable {
    var jss_URL:String
    var ACSID:String
    var checkInID:String
    var checkOutID:String
    var availabilityID:String
}

var keylogin: jssLogin?

class PrefsViewController: NSViewController {

    @IBOutlet var keychainCheckbox: NSButton!
    @IBOutlet var jamfURL: NSTextField!
    @IBOutlet var jamfUsername: NSTextField!
    @IBOutlet var jamfPasswordField: NSSecureTextField!
    @IBOutlet var ACSID: NSTextField!
    @IBOutlet var checkOutID: NSTextField!
    @IBOutlet var checkInID: NSTextField!
    @IBOutlet var availabilityID: NSTextField!
    @IBOutlet var alertSelector: NSPopUpButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        availabilityID.stringValue = UserDefaults.standard.string(forKey: "availabilityID") ?? ""
        checkOutID.stringValue = UserDefaults.standard.string(forKey: "checkOutID") ?? ""
        checkInID.stringValue = UserDefaults.standard.string(forKey: "checkInID") ?? ""
        ACSID.stringValue = UserDefaults.standard.string(forKey: "ACSID") ?? ""
        jamfURL.stringValue = UserDefaults.standard.string(forKey: "jss_URL") ?? ""
        keychainCheckbox.integerValue = UserDefaults.standard.integer(forKey: "keychainCheck")
        
        let keychainVar = try? keychainlogin(server: jamfURL.stringValue)
        if keychainVar != nil {
            jamfUsername.stringValue = (keychainVar?.KCUsername)!
            jamfPasswordField.stringValue = (keychainVar?.KCPassword)!
            keylogin?.username = (keychainVar?.KCUsername)!
            keylogin?.password = (keychainVar?.KCPassword)!
        } else {
            jamfUsername.stringValue = jamfUser ?? ""
            jamfPasswordField.stringValue = jamfPassword ?? ""
        }
        
    }
    
    @IBAction func saveButton(_ sender: Any) {
        let selectedAlert = alertSelector.indexOfSelectedItem
        
        UserDefaults.standard.set(selectedAlert, forKey: "alert")
        jamfPassword = jamfPasswordField.stringValue
        jamfUser = jamfUsername.stringValue
        
        if jamfUsername.stringValue !=  keylogin?.username || jamfPasswordField.stringValue != keylogin?.password {
            try! keychain_delete(server: jamfURL.stringValue)
        }
        
        if keychainCheckbox.integerValue == 1 {
            keychain_save(user: jamfUsername.stringValue, pass: jamfPasswordField.stringValue, server: jamfURL.stringValue)
            
        } else {
            try! keychain_delete(server: jamfURL.stringValue)
            
        }
        
        view.window?.close()
    }
    
    
    func keychain_delete(server: String) throws{
        
        let query: [String: Any] = [kSecClass as String: kSecClassInternetPassword,
                                    kSecAttrServer as String: server]
        
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else { throw KeychainError.unhandledError(status: status) }
        
        
        
    }
    
    func keychain_save(user: String, pass: String, server: String) {
        let password = pass.data(using: String.Encoding.utf8)!
        let query: [String: Any] = [kSecClass as String: kSecClassInternetPassword,
                                    kSecAttrAccount as String: user,
                                    kSecAttrServer as String: server,
                                    kSecValueData as String: password]
        
        _ = SecItemAdd(query as CFDictionary, nil)
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
