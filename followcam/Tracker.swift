//
//  File.swift
//  tuto
//
//  Created by Peter Squla on 02/09/2022.
// get the sensor data (heading, GPS)

import Foundation
import CoreLocation
import SwiftUI
import MapKit



class Tracker : NSObject, ObservableObject, CLLocationManagerDelegate {
    
    
    @Published var counter = 1.0
    @Published var magneticHeading = 0.0
    @Published var trueNorth = 0.0
    @Published var cameraLatitude = 0.0
    @Published var cameraLongitude = 0.0
    @Published var surferLatitude = 0.0 //surfer
    @Published var surferLongitude = 0.0 //surfer
    @Published var speed = 0.0
    @Published var course = 0.0
    @Published var serverResult = "no server result"
    @Published var locationAuthorized = false
    private let locationManager : CLLocationManager
    public var myMotor : Motor?
    private var shareLocationTimer : Timer
    private var getLocationTimer : Timer
    @Published var region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 51.507222, longitude: -0.1275), span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5))
    private var simplecounter = 0
    private var modeIsCamera = false
    
    override init() {
        
        locationManager = CLLocationManager()
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.activityType = CLActivityType.fitness
        shareLocationTimer = Timer()
        getLocationTimer = Timer()
        super.init()
        locationManager.delegate = self

    }
    
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if (modeIsCamera) {
            cameraLatitude = locations.first?.coordinate.latitude ?? 0
            cameraLongitude = locations.first?.coordinate.longitude ?? 0
        }
        surferLatitude = locations.first?.coordinate.latitude ?? 0
        surferLongitude = locations.first?.coordinate.longitude ?? 0
        speed = locations.first?.speed ?? 0
        course = locations.first?.course ?? 0
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        magneticHeading = newHeading.magneticHeading
        trueNorth = newHeading.trueHeading
    }
    
    
    func requestPermission() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    func locationManagerDidChangeAuthorization(_ manager : CLLocationManager ) {
        
        if (manager.authorizationStatus == CLAuthorizationStatus.authorizedWhenInUse) {
            locationAuthorized = true
            locationManager.startUpdatingLocation()
            locationManager.startUpdatingHeading()
            
        }
    }
    
    func toggleLocationSending( _ isSurfer : Bool) {
        if (isSurfer) {
            shareLocationTimer  = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(sendLocationToServerJSON),userInfo: nil, repeats: true)
        }
        else {
            shareLocationTimer.invalidate()
        }
    }
    
    func toggleLocationGetting( _ isCamera : Bool) {
        if (isCamera) {
            getLocationTimer  = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(getLocationFromServer),userInfo: nil, repeats: true)
            modeIsCamera = true
        }
        else {
            getLocationTimer.invalidate()
            modeIsCamera = false
        }
    }
    
    @objc func sendLocationToServerJSON() {
        
        let timesend = NSDate().timeIntervalSince1970
        let parameters: [String: Any] = ["longitude": surferLongitude, "latitude": surferLatitude,"speed":speed,"course":course,"timesend":timesend]
        let url = URL(string: "https://surftracker-365018.ew.r.appspot.com/setlocation")! 

        let session = URLSession.shared
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
          
          do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted)
          } catch let error {
              print(error.localizedDescription)
            return
          }

        let task = session.dataTask(with: request) { data, response, error in
            
            if let error = error {
              print("Post Request Error: \(error.localizedDescription)")
              return
            }
            

          }
          task.resume()
        
        
        
    }
    
    @objc func getLocationFromServer() {
        //print(simplecounter)
        simplecounter = simplecounter + 1
        
        let url = URL(string: "https://surftracker-365018.ew.r.appspot.com/getlocation")!
        
        let task = URLSession.shared.dataTask(with: url) {(data, response, error) in

            if let error = error {
              print("Request Error: \(error.localizedDescription)")
              return
            }
            
            do {
                let json = try JSONSerialization.jsonObject(with: data!, options: [])
                if let obj = json as? [String: Any] {
                    if obj["longitude"] == nil {
                        print("no locations available")
                        return
                    }
                    DispatchQueue.main.async {
                        self.surferLatitude = obj["latitude"] as! CLLocationDegrees
                        self.surferLongitude = obj["longitude"] as! CLLocationDegrees
                    }
                }
            }
            catch {
                print(error.localizedDescription)
            }

            guard let data = data else { return }
            let result = (String(data: data, encoding: .utf8)!)
            
            //queue needs to be done otherwise vieuw does not pickup the binding serverresult
            DispatchQueue.main.async {
                self.serverResult = result
                self.region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: self.surferLatitude, longitude: self.surferLongitude), span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005))
            }

        }

        task.resume()
    }
    
 
    
    
    
    
}

