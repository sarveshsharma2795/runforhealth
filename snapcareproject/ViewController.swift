//
//  ViewController.swift
//  snapcareproject
//
//  Created by Sarvesh on 8/5/17.
//  Copyright © 2017 Sarvesh. All rights reserved.
//Credits: - Some of the code written has been inspired from Appcoda and Makeapppie.com

import UIKit
import CoreMotion
import HealthKit
class ViewController: UIViewController {
    
    //MARK: - colors for buttons
    let initalColor = UIColor(colorLiteralRed: 0.0, green: 1.0, blue: 0.0, alpha: 1.0)
    let finalColor = UIColor(colorLiteralRed: 1.0, green: 0.0, blue: 0.0, alpha: 1.0)
    
    //MARK: - data about the user
    var numberOfSteps : Int? = nil
    var distance : Double? = 1.0
    
    //pedometer initialization
    var pedometer = CMPedometer()
    
    //Mark: - Healthkit object initialization
     let healthKitStore: HKHealthStore = HKHealthStore()
    
    // Mark: - Timer variables
    var timer = Timer()
    var timeInterval = 1.0
    
    var timeElpased:TimeInterval = 0.0
    
    //MARK: - Outlets
    @IBOutlet weak var statusTitle: UILabel!
    @IBOutlet weak var stepsLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var startButton: UIButton!
    
    //MARK: - Action buttons
    @IBAction func shareData(_ sender: Any) {
        if let distance = self.distance{
        saveDistance(distanceRecorded: distance, date: NSDate())
        }
    }
    @IBAction func pausePressed(_ sender: Any) {
        if startButton.titleLabel?.text == "Start"{
        return
        }
        if ((sender as AnyObject).titleLabel??.text)! == "Pause"{
            (sender as AnyObject).setTitle("Continue ", for: .normal)
            pedometer.stopUpdates()
            stopTimer()
            statusTitle.text = "Pedometer Paused: " + timeFormatConvert(interval: timeElpased)
        }
        else{
            startTimer()
            pedometer.startUpdates(from: Date(), withHandler:{ (pedometerData, error) in
                if let pedData = pedometerData{
                    if let numberOfSteps = pedometerData?.numberOfSteps{
                        self.numberOfSteps = Int(numberOfSteps) + self.numberOfSteps!
                    }else{
                        self.numberOfSteps = nil
                        self.distance = nil
                    }
                    if let distance = pedData.distance{
                        self.distance = Double(distance) + self.distance!
                    }
                } else {
                    self.numberOfSteps = nil
                    self.distance = nil
                }
            })
            statusTitle.text = "Counting your steps"
            
            (sender as AnyObject).setTitle("Pause", for: .normal)
        }
           }
    @IBAction func startStopButton(_ sender: UIButton) {
    if sender.titleLabel?.text == "Start"{
        numberOfSteps = nil
        distance = nil
        startTimer()
        pedometer.startUpdates(from: Date(), withHandler:{ (pedometerData, error) in
            if let pedData = pedometerData{
                if let numberOfSteps = pedometerData?.numberOfSteps{
                self.numberOfSteps = Int(numberOfSteps)
                }else{
                    self.numberOfSteps = nil
                    self.distance = nil
                }
                if let distance = pedData.distance{
                    self.distance = Double(distance)
                }
            } else {
                self.numberOfSteps = nil
                self.distance = nil
            }
                    })
        statusTitle.text = "Counting your steps"
        sender.setTitle("Stop", for: .normal)
        sender.backgroundColor = finalColor
        
    }
    else {
        pedometer.stopUpdates()
        stopTimer()
        statusTitle.text = "Pedometer Off: " + timeFormatConvert(interval: timeElpased)
        sender.backgroundColor = initalColor
        sender.setTitle("Start", for: .normal)
        timeElpased = 0.0
        }

}
    //MARK: - Timer functions
    func startTimer(){
        if timer.isValid{
            timer.invalidate()
            }
            timer = Timer.scheduledTimer(timeInterval: timeInterval,target: self,selector: #selector(timerAction(timer:)) ,userInfo: nil,repeats: true)
    }
    func stopTimer(){
        timer.invalidate()
        displayData()
    }
    func timerAction(timer:Timer){
        displayData()
    }
    func displayData(){
        timeElpased += 1.0
        self.statusTitle.text = "On " + timeFormatConvert(interval: timeElpased)
        if let numberOfSteps = self.numberOfSteps{
            self.stepsLabel.text = "Steps: " + "\(numberOfSteps)"
        }else {
            stepsLabel.text = "Steps: N/A"
        }
        if let distance = self.distance{
            distanceLabel.text = "Distance: " + "\(Double(distance))" + "meters"
        } else {
            distanceLabel.text = "Distance: N/A"
        }
    }

    //MARK: - Format functions
    func timeFormatConvert(interval:TimeInterval)->String{
        var seconds = Int(interval + 0.5) //round up seconds
        let hours = seconds / 3600
        let minutes = (seconds / 60) % 60
        seconds = seconds % 60
        return String(format:"%02i:%02i:%02i",hours,minutes,seconds)
    }
    //Mark: - Healthkit authorization functions
    func authorizeHealthKit(completion: ((_ success: Bool, _ error: Error?) -> Void)!) {
        
        let healthDataToWrite = Set(arrayLiteral: HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.distanceWalkingRunning)!)
        if !HKHealthStore.isHealthDataAvailable() {
            print("Can't access HealthKit.")
        }
        healthKitStore.requestAuthorization(toShare: healthDataToWrite, read: nil) { (success, error) in
            if( completion != nil ) {
                completion(success, error)
            }
        }
    }
    func getHealthKitPermission() {
        
        authorizeHealthKit { (authorized,  error) -> Void in
            if authorized {
                
                print("Authorized to use HealthKit")
            } else {
                if error != nil {
                    print(error)
                }
                print("Permission denied.")
            }
        }
    }
    //Mark : - Distance sharing functions
    func saveDistance(distanceRecorded: Double, date: NSDate ) {
        
        // Set the quantity type to the running/walking distance.
        let distanceType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.distanceWalkingRunning)
        
        // Set the unit of measurement to meters.
        let distanceQuantity = HKQuantity(unit:  HKUnit.meter(), doubleValue: distanceRecorded)
        
        // Set the official Quantity Sample.
        let distance = HKQuantitySample(type: distanceType!, quantity: distanceQuantity, start: date as Date, end: date as Date)
        // Save the distance quantity sample to the HealthKit Store.
        healthKitStore.save(distance, withCompletion: { (success, error) -> Void in
            if( error != nil ) {
                print(error)
            } else {
                print("The distance has been recorded! Better go check!")
            }
        })
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        getHealthKitPermission()
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
