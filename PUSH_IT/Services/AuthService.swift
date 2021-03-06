//
//  AuthService.swift
//  PUSH_IT
//
//  Created by Katherine Reinhart on 1/19/18.
//  Copyright © 2018 reinhart.digital. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON


class AuthService {
    
    static let instance = AuthService()
    
    let defaults = UserDefaults.standard
    
    var isLoggedIn : Bool {
        get {
            return defaults.bool(forKey: LOGGED_IN_KEY)
        }
        
        set {
            defaults.set(newValue, forKey: LOGGED_IN_KEY)
        }
    }
    
    var authToken : String {
        get {
            return defaults.string(forKey: TOKEN_KEY) as! String
        }
        set {
            defaults.set(newValue, forKey: TOKEN_KEY)
        }
    }
    
    var userEmail : String {
        get {
            return defaults.string(forKey: USER_EMAIL) as! String
        }
        set {
            defaults.set(newValue, forKey: USER_EMAIL)
        }
    }
    
    var name : String {
        get {
            return defaults.string(forKey: USER_NAME)!
        }
        set {
            defaults.set(newValue, forKey: USER_NAME)
        }
    }
    
    var id : Int {
        get {
            return defaults.integer(forKey: USER_ID)
        }
        set {
            defaults.set(newValue, forKey: USER_ID)
        }
    }
    
    func registerUser(email: String, password: String, completion: @escaping CompletionHandler) {
        
        let lowerCaseEmail = email.lowercased()
        
        let body: [String: Any] = [
            "email": lowerCaseEmail,
            "password": password
        ]
        
        Alamofire.request(REGISTER_URL, method: .post, parameters: body, encoding: JSONEncoding.default, headers: HEADER).responseJSON { (response) in
            if response.result.error != nil {
                debugPrint(response.result.error as Any)
                completion(false)
                return
            }
            guard let data = response.data else { return }
            let json = JSON(data: data)
            self.userEmail = json["email"].stringValue
            self.authToken = json["token"].stringValue
            
            self.isLoggedIn = true
            completion(true)
        }
    }
    
    func loginUser(email: String, password: String, completion: @escaping CompletionHandler) {
        let lowerCaseEmail = email.lowercased()
        
        let body: [String: Any] = [
            "email": lowerCaseEmail,
            "password": password
        ]
        
        Alamofire.request(LOGIN_URL, method: .post, parameters: body, encoding: JSONEncoding.default, headers: HEADER).responseJSON { (response) in
            
            if response.result.error != nil {
                debugPrint(response.result.error as Any)
                completion(false)
                return
            }
            
            guard let data = response.data else { return }
            self.setUserInfo(data: data)
            completion(true)
        }
    }
    
    func submitOnboardingData(name: String, level: String, goal: String, completion: @escaping CompletionHandler) {
        
        let body: [String: Any] = [
            "email": userEmail,
            "name": name,
            "level": level,
            "goal": goal
        ]
        
        let header = self.bearerHeader()
        
        Alamofire.request(SET_INFO_URL, method: .post, parameters: body, encoding: JSONEncoding.default, headers: header).responseJSON { (response) in
            if response.result.error != nil {
                completion(false)
                return
            }
            guard let data = response.data else { return }
            
            self.setUserInfo(data: data)
                
            completion(true)
        }
    }
    
    func setUserInfo(data: Data) {
        let json = JSON(data: data)
        let id = json["id"].stringValue
        let email = json["email"].stringValue
        let name = json["name"].stringValue
        let expLevel = json["level"].stringValue
        let primaryGoal = json["goal"].stringValue
        let token = json["token"].stringValue
        
        self.authToken = token
        self.isLoggedIn = true
        self.userEmail = email
        self.id = Int(id)!
        self.name = name
        UserDataService.instance.setUserDataOnLogin(id: id, email: email, name: name, primaryGoal: primaryGoal, expLevel: expLevel)
        
    }
    
    func logUserOut() {
        isLoggedIn = false
        userEmail = ""
        authToken = ""
        id = 0
        debugPrint("user logged out")
    }
    
    func bearerHeader() -> Dictionary<String, String>  {
        return [
            "authorization": "Bearer \(self.authToken)",
            "Content-Type": "application/json; charset=utf-8"
        ]
        
    }
}
