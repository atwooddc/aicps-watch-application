//
//  InterfaceController.swift
//  QoE_companion WatchKit Extension
//
//  Created by David Atwood on 10/28/21.
//

import WatchKit
import Foundation
import CoreMotion
import HealthKit
import WatchConnectivity

class InterfaceController: WKInterfaceController, WCSessionDelegate {

    enum Status {
        case waiting
        case recording
    }
    
    var status: Status = Status.waiting {
        willSet(newStatus) {
            
            switch(newStatus) {
            case .waiting:
                waiting()
                break
                
            case .recording:
                recording()
                break
            }
        }
        didSet {
            
        }
    }
    
    func waiting() {
        timer.stop()
    }
    
    func recording() {
        timer.setDate(Date(timeIntervalSinceNow: 0.0))
        timer.start()
    }
    
    override func awake(withContext context: Any?) {
        status = .waiting
        
        // configure WC stuff
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
        
        authorizeHealthKit()
        
        startToMeasureHR()
        
    }
    
    
    @IBOutlet weak var timer: WKInterfaceTimer!
    
    @IBOutlet weak var countdown: WKInterfaceTimer!
    
    @IBOutlet weak var transferSuccess: WKInterfaceLabel!
    
    @IBOutlet weak var recordingStatus: WKInterfaceLabel!
    
    let motion = CMMotionManager()
    
    let currentFrequency = 50.0
    
    var sensorOutputs = [SensorOutput]()
    
    var session: HKWorkoutSession?
    
    private var healthStore = HKHealthStore()
    
    var heartRate = -1
        
    private let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)
    
    private let heartRateUnit = HKUnit(from: "count/min")

    @IBAction func startButtonPressed() {
        if status == Status.recording { return }
        
        timer.setDate(Date(timeIntervalSinceNow: 0.0))
        self.countdown.setDate(Date(timeIntervalSinceNow: 3.5))
        self.countdown.setHidden(false)
        self.countdown.start()
        // initialize countdown
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.8) {

            self.countdown.setHidden(true)
            WKInterfaceDevice.current().play(.start)
            // vibration
            self.startGettingData()
            self.status = .recording
        }

    

    }
    
    @IBAction func stopButtonPressed() {
        if status == Status.waiting { return }
        
        stopGettingData()
        status = .waiting
    }
    
    func startGettingData() {

        self.recordingStatus.setHidden(false)
        
        // If we have already started the workout, then do nothing.
        if (session != nil) {
            return
        }
        
        // Configure the workout session.
        let workoutConfiguration = HKWorkoutConfiguration()
        workoutConfiguration.activityType = .walking
        workoutConfiguration.locationType = .outdoor
        
        do {
//          session = try HKWorkoutSession(configuration: workoutConfiguration)
            session = try HKWorkoutSession(healthStore: healthStore, configuration: workoutConfiguration)
        } catch {
            fatalError("Unable to create the workout session!")
        }
        
        // Start the workout session and device motion updates.
        session?.startActivity(with: Date.now)
        
        if !motion.isDeviceMotionAvailable {
            print("Device Motion is not available.")
            return
        }
        
        motion.deviceMotionUpdateInterval = 1.0 / Double(currentFrequency)
        motion.startDeviceMotionUpdates(to: OperationQueue.current!) { (deviceMotion: CMDeviceMotion?, error: Error?) in
            if error != nil {
                print("Encountered error: \(error!)")
            }
            
            if deviceMotion != nil {
                
                let AccX = deviceMotion!.gravity.x + deviceMotion!.userAcceleration.x;
                let AccY = deviceMotion!.gravity.y + deviceMotion!.userAcceleration.y;
                let AccZ = deviceMotion!.gravity.z + deviceMotion!.userAcceleration.z;
                
                let GyroX = deviceMotion!.rotationRate.x
                let GyroY = deviceMotion!.rotationRate.y
                let GyroZ = deviceMotion!.rotationRate.z
                
                let sensorOutput = SensorOutput()
                
                sensorOutput.timeStamp = Double(Date().timeIntervalSinceReferenceDate) // since 00:00:00 UTC 1 Jan 2001
                sensorOutput.accX = AccX
                sensorOutput.accY = AccY
                sensorOutput.accZ = AccZ
                sensorOutput.gyroX = GyroX
                sensorOutput.gyroY = GyroY
                sensorOutput.gyroZ = GyroZ
                sensorOutput.heartRate = Int16(self.heartRate)
                
                self.sensorOutputs.append(sensorOutput)
                
            }
        }
    }
    
    // heart rate and blood ox functions
    func authorizeHealthKit() {
          // Used to define the identifiers that create quantity type objects.
            let healthKitTypes: Set = [
            HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate)!]
         // Requests permission to save and read the specified data types.
            healthStore.requestAuthorization(toShare: healthKitTypes, read: healthKitTypes) { _, _ in }
    }

    // Start to measure the heart rate.
    func startToMeasureHR() {
        self.healthStore.execute(self.createStreamingQuery())
    }

    // Create a query to receive new heart rate data from the HealthKit store.
    private func createStreamingQuery() -> HKQuery {
        let predicate = HKQuery.predicateForSamples(withStart: Date(), end: nil, options: [])

        let query = HKAnchoredObjectQuery(type: self.heartRateType!, predicate: predicate, anchor: nil, limit: Int(HKObjectQueryNoLimit)) {
            (query, samples, deletedObjects, anchor, error) -> Void in
            self.formatHRSamples(samples: samples)
        }

        query.updateHandler = { (query, samples, deletedObjects, anchor, error) -> Void in
            self.formatHRSamples(samples: samples)
        }
        return query
    }

    // Format the samples received from HealthKit.
    private func formatHRSamples(samples: [HKSample]?) {
        guard let samples = samples as? [HKQuantitySample] else { return }
        guard let quantity = samples.last?.quantity else { return }
        self.heartRate = Int(quantity.doubleValue(for: heartRateUnit))
    }
    
   
    func stopGettingData() {
        
        self.recordingStatus.setHidden(true)
        
        motion.stopDeviceMotionUpdates()
        
        // archive data
        let archiver = NSKeyedArchiver(requiringSecureCoding: true)
        try! archiver.encodeEncodable(sensorOutputs, forKey: NSKeyedArchiveRootObjectKey)
        archiver.finishEncoding()
        let data = archiver.encodedData

        // Saving data to file
        let sourceURL = self.getDocumentDirectory().appendingPathComponent("saveFile")
        try? data.write(to: sourceURL)
        print ("Saved file")
        
        // send file, clear sensorOutputs
        let session = WCSession.default
        if session.activationState == .activated {

            print ("Starting sending file")
            // the file exists now; send it across the session
            session.transferFile(sourceURL, metadata: nil)
            
            // replace with "Sending data..." until iphone responds, then say "Data received on iPhone"
            self.transferSuccess.setHidden(false)
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                self.transferSuccess.setHidden(true)
            }
        }
        self.sensorOutputs.removeAll()
        
        // Stop the device motion updates and workout session.
        motion.stopDeviceMotionUpdates()
        self.session?.end()
        print("Ended health session")
        self.session = nil
    }
    
    func getDocumentDirectory() -> URL {
           let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
           return paths[0]
       }

    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {

    }
    
    override func willActivate() {
        super.willActivate()
    }
    
    override func didDeactivate() {
        super.didDeactivate()
    }

}
