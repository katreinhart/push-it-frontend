//
//  UserDataService.swift
//  PUSH_IT
//
//  Created by Katherine Reinhart on 1/19/18.
//  Copyright © 2018 reinhart.digital. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

class UserDataService {
    
    static let instance = UserDataService()
    
    public private(set) var id = ""
    public private(set) var email = ""
    public private(set) var name = ""
    
    public private(set) var primaryGoal = ""
    public private(set) var expLevel = ""
    public private(set) var secondaryGoal1 : Goal?
    public private(set) var secondaryGoal2 : Goal?
    
    
    func setUserDataOnLogin(id: String, email: String, name: String, primaryGoal: String, expLevel: String) {
        self.id = id
        self.email = email
        self.name = name
        self.primaryGoal = primaryGoal
        self.expLevel = expLevel
    }
    
    func getSecondaryGoals(completion: @escaping CompletionHandler) {
        
        Alamofire.request(SECONDARY_GOALS_URL, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: BEARER_HEADER).responseJSON { (response) in
            if response.result.error == nil {
                debugPrint("data fetched from server")
                guard let data = response.data else { return }
                let json = JSON(data: data)
                let responseData = json["data"]
                
                debugPrint(responseData)
                
                let df = DateFormatter()
                df.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
                
                let ex1 = responseData[0]["exercise"].string!
                let ex2 = responseData[1]["exercise"].string!
                
                let ds1 = responseData[0]["goal_date"].string
                let ds2 = responseData[1]["goal_date"].string
                
                guard let date1 = df.date(from: ds1!) else {return}
                debugPrint(date1 as Any)
                guard let date2 = df.date(from: ds2!) else {return}
                debugPrint(date2 as Any)
                
                let gw1 = responseData[0]["goal_weight"].int64!
                let gw2 = responseData[1]["goal_weight"].int64!
                
                let goal1 = Goal(exercise: ex1, weight: gw1, date: date1)
                let goal2 = Goal(exercise: ex2, weight: gw2, date: date2)
                
                self.secondaryGoal1 = goal1
                self.secondaryGoal2 = goal2
                
                completion(true)
    
            } else {
                debugPrint("did goals not get found?")
                completion(false)
            }
        }
    }

    func setSecondaryGoals(sg1: Goal, sg2: Goal, completion: @escaping CompletionHandler) {
        debugPrint("set secondary goals")
        
        self.secondaryGoal1! = sg1
        self.secondaryGoal2! = sg2
        debugPrint(sg1)
        debugPrint(sg2)
        
        let body: [String: [String: Any]] = [
            "goal1": [
                "goal_date": DateFormatter.veryLongStringDateFormatter.string(from: sg1.date),
                "goal_weight": String(sg1.weight),
                "exercise": sg1.exercise
            ],
            "goal2": [
                "goal_date": DateFormatter.veryLongStringDateFormatter.string(from: sg2.date),
                "goal_weight": String(sg2.weight),
                "exercise": sg2.exercise
            ]
        ]
        debugPrint(body)
        
        Alamofire.request(SECONDARY_GOALS_URL, method: .post, parameters: body, encoding: JSONEncoding.default, headers: BEARER_HEADER).responseJSON { (response) in
            if response.result.error == nil {
                guard let data = response.data else { return }
                
                let json = JSON(data: data)
                let message = json["message"]
                if message == "Goals added successfully" {
                    completion(true)
                }
            } else {
                completion(false)
            }
            debugPrint("Secondary goals posted to db")
        }
    }
    
    func updateUserGoal(goal: String, completion: @escaping CompletionHandler) {
        self.primaryGoal = goal
        
        let body = [
            "goal": goal
        ]
        
        Alamofire.request(UPDATE_PRIMARY_GOAL_URL, method: .post, parameters: body, encoding: JSONEncoding.default, headers: BEARER_HEADER).responseJSON {
            (response) in
            if response.result.error != nil {
                completion(false)
            } else {
                debugPrint("pgoal successfully updated")
            }
        }
    }
    
    func logoutUser() {
        id = ""
        email = ""
        name = ""
        primaryGoal = ""
        expLevel = ""
        
        AuthService.instance.isLoggedIn = false
        AuthService.instance.userEmail = ""
        AuthService.instance.authToken = ""
        
        WorkoutDataService.instance.workouts = [Workout]()
        HistoryDataService.instance.history = [Workout]()
    }
}
