//
//  HistoryDataService.swift
//  PUSH_IT
//
//  Created by Katherine Reinhart on 1/25/18.
//  Copyright © 2018 reinhart.digital. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

class HistoryDataService {
    static let instance = HistoryDataService()
    
    var history = [Workout]()
    
    func fetchHistory() {
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy'-'MM'-'dd'T'HH':'mm':'ssZZZ"
        
        
        Alamofire.request(HISTORY_URL, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: BEARER_HEADER).responseJSON { (response) in
            if response.result.error == nil {
                guard let data = response.data else { return }
                let json = JSON(data: data).array
                for item in json! {
                    
                    let dateString = item["start_time"].string
                    let date = dateFormatter.date(from: dateString!)
                    
                    let rating = item["rating"].int
                    let comments = item["comments"].stringValue
                    
                    var newWorkout = Workout(exercises: [], date: date!, rating: rating!, comments: comments)
                    
                    let responseExercises = item["exercises"].array
                    
                    if responseExercises == nil {
                        self.history.append(newWorkout)
                        continue
                    }
                    
                    for ex in responseExercises! {
                        let exName = ex["exercise_name"].stringValue
                        let sets = ex["goal_sets"].intValue
                        let reps = ex["goal_reps_per_set"].intValue
                        let newExercise = Exercise(type: exName, goalWeight: 0, goalSets: sets, goalRepsPerSet: reps, sets: [])
                        
                        newWorkout.exercises.append(newExercise)
                    }
                    
                    
                    let responseSets = item["sets"].array
                    if responseSets == nil {
                        self.history.append(newWorkout)
                        continue
                    }
                    
                    for set in responseSets! {
                        
                        let exName = set["exercise"].stringValue
                        let exIndex = newWorkout.exercises.index(where: { (item) -> Bool in
                            return (item.type == exName)
                        })
                        
                        if exIndex == nil {
                            continue
                        }
                        
                        let repsAtt = set["reps_att"].intValue
                        let repsComp = set["reps_comp"].intValue
                        let weight = set["weight"].intValue
                        let newSet = Set(weight: weight, repsCompleted: repsComp, repsAttempted: repsAtt)
                        
                        newWorkout.exercises[exIndex!].sets.append(newSet)
                    }
                    
                    self.history.append(newWorkout)
                }
            }
        }
    }
}