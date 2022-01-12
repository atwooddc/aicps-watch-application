//
//  ViewController.swift
//  QoE_companion
//
//  Created by David Atwood on 10/28/21.
//

import UIKit
import WatchConnectivity
import CoreData

class ViewController: UIViewController, WCSessionDelegate {

    @IBOutlet weak var dataReceived: UILabel!
    
    @IBOutlet weak var tableView: UITableView!
    
    var allData = [SensorData]()
    
    var nextID: Int16 = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
        
        self.dataReceived.isHidden = true
        
        // clear CoreData
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "SensorData")
        fetchRequest.includesPropertyValues = false
        do {
            let items = try context.fetch(fetchRequest) as! [NSManagedObject]
            for item in items {
                context.delete(item)
            }
            // Save Changes
            try context.save()
        } catch {
            print(error)
        }
        
        tableView.register(DataCell.nib(), forCellReuseIdentifier: DataCell.identifier)
        tableView.delegate = self
        tableView.dataSource = self
        
    }
    
//    
//    @IBAction func deleteButtonPressed(_ sender: Any) {
//        // clear CoreData
//        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "SensorData")
//        fetchRequest.includesPropertyValues = false
//        do {
//            let items = try context.fetch(fetchRequest) as! [NSManagedObject]
//            for item in items {
//                context.delete(item)
//            }
//            // Save Changes
//            try context.save()
//        } catch {
//            print(error)
//        }
//    }
    
    
    func session(_ session: WCSession, didReceive file: WCSessionFile) {
        print ("File with data received on iPhone!")
        
        let mutableData = NSMutableData(contentsOf: file.fileURL)
        
        let testData = mutableData?.copy() as! Data
    
        do {
            let unarchiver = try NSKeyedUnarchiver(forReadingFrom: testData)
            if let sensorOutputs = try unarchiver.decodeTopLevelDecodable([SensorOutput].self, forKey: NSKeyedArchiveRootObjectKey) {
                DispatchQueue.main.async { // in main thread

                    // save file to CoreData
                    let sensorData = SensorData (context: context)
                    sensorData.id = self.nextID
                    self.nextID += 1
                    sensorData.time = Date(timeIntervalSinceReferenceDate: sensorOutputs[0].timeStamp!)
                    sensorData.duration = Int16(sensorOutputs.last!.timeStamp! - sensorOutputs.first!.timeStamp!)
                    sensorData.selected = false
                    
                    for sensorOutput in sensorOutputs {
                        let dataPoint = DataPoint (context:context)
                        dataPoint.accX = sensorOutput.accX!
                        dataPoint.accY = sensorOutput.accY!
                        dataPoint.accZ = sensorOutput.accZ!
                        dataPoint.gyroX = sensorOutput.gyroX!
                        dataPoint.gyroY = sensorOutput.gyroY!
                        dataPoint.gyroZ = sensorOutput.gyroZ!
                        dataPoint.heartRate = sensorOutput.heartRate!
                        dataPoint.timestamp = sensorOutput.timeStamp!
                        sensorData.addToDatapoints(dataPoint)
                    }
                    
                    do {
                        try context.save()
                        self.dataReceived.isHidden = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                                self.dataReceived.isHidden = true
                            }
                    } catch {
                        print("error saving context")
                    }
                    self.fetchData()
                }
                
            }
        } catch {
            print("unarchiving failure: \(error)")
        }
    }
    
    func fetchData() {
        do {
            self.allData = try context.fetch(SensorData.fetchRequest())
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
        catch {
            print("table view failure: \(error)")
        }
    }
    
    @IBAction func exportButtonPressed(_ sender: Any) {
        
        // set up CSV
        let date = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let sessionDate = formatter.string(from: date)
        let fileName = "motion-sessions_\(sessionDate).csv"
        let path = NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)
        var csvText = "Timestamp,AccX,AccY,AccZ,GyroX,GyroY,GyroZ,HeartRate,SessionID,\n"
        
        // fetch data
        do {
            let data = try context.fetch(SensorData.fetchRequest())
            
            // if no data selected, export all
            // else, export only selected data
            
            var someSelected = false
            
            for sensorData in data {
                if sensorData.selected == true {
                    someSelected = true
                }
            }
            
            for sensorData in data { // for each SensorData object in database
                
                if someSelected && sensorData.selected || !someSelected {
                    
                    for dataPoint in sensorData.datapoints! {
                        
                        let hr = (dataPoint as! DataPoint).heartRate == -1 ? "NA" : String((dataPoint as! DataPoint).heartRate)
                        
                        let row = "\(String(describing: (dataPoint as! DataPoint).timestamp)),\(String((dataPoint as! DataPoint).accX)),\(String((dataPoint as! DataPoint).accY)),\(String((dataPoint as! DataPoint).accZ)),\(String((dataPoint as! DataPoint).gyroX)),\(String((dataPoint as! DataPoint).gyroY)),\(String((dataPoint as! DataPoint).gyroZ)),\(hr),\(String(sensorData.id)),\n"
                        
                        csvText.append(row)

                    }
                    
                }
            }
            
            do {
                try csvText.write(to: path!, atomically: true, encoding: String.Encoding.utf8)
            } catch {
                print("Failed to create file")
                print("\(error)")
            }
            print(path ?? "not found")
            
        } catch {
            print(error)
        }
        
        // sharing csv
        if let fileURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName) as URL? {
            let objectsToShare = [fileURL]
            let activityController = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
            let excludedActivities = [UIActivity.ActivityType.postToFlickr, UIActivity.ActivityType.postToWeibo, UIActivity.ActivityType.message, UIActivity.ActivityType.mail, UIActivity.ActivityType.print, UIActivity.ActivityType.copyToPasteboard, UIActivity.ActivityType.assignToContact, UIActivity.ActivityType.saveToCameraRoll, UIActivity.ActivityType.addToReadingList, UIActivity.ActivityType.postToFlickr, UIActivity.ActivityType.postToVimeo, UIActivity.ActivityType.postToTencentWeibo]
            
            activityController.excludedActivityTypes = excludedActivities
            present(activityController, animated: true, completion: nil)
        }
        
        // pop up with option to delete rows just exported?
        // move deselection to down here after pop up
        
    }
    
    // mandatory methods for WatchConnectivity
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
    }

}


extension ViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section:Int) -> Int {
        return self.allData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let dataCell = tableView.dequeueReusableCell(withIdentifier: DataCell.identifier, for: indexPath) as! DataCell
        let sensorData = self.allData[indexPath.row]
        dataCell.configure(with: String(sensorData.id), time: sensorData.time!, duration: Int(sensorData.duration))
        return dataCell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Unselect the row, and instead, show the state with a checkmark.
        tableView.deselectRow(at: indexPath, animated: false)
        
        guard let cell = tableView.cellForRow(at: indexPath) else { return }
        
        // Update the selected item to indicate whether the user packed it or not.
        let item = self.allData[indexPath.row]
        item.selected = !item.selected
        
        // Show a check mark next to packed items.
        if item.selected {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }
    }
    
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let action = UIContextualAction(style: .destructive, title: "Delete") { (action, view, completionHandler) in
            
            let dataToRemove = self.allData[indexPath.row]
            
            context.delete(dataToRemove)
            
            do {
                try context.save()
            } catch {
                
            }
            
            self.fetchData()
        }
        
        return UISwipeActionsConfiguration(actions: [action])
    }
    
//    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        if let cell = tableView.cellForRow(at: indexPath) {
//            cell.accessoryType = .checkmark
//        }
//    }
//    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
//        if let cell = tableView.cellForRow(at: indexPath) {
//            cell.accessoryType = .none
//        }
//    }
}

