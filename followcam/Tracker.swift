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
    public var myLatitude = 0.0
    public var myLongitude = 0.0
    public var cameraLatitude = 1.0
    public var cameraLongitude = 1.0
    public var surferLatitude = 0.0
    public var surferLongitude = 0.0
    public var cloudLocation = serverLocation()
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
        
        Task {
            try await getLocation()
        }
        
        
        
    }
    
    struct serverLocation: Codable {
        var latitude: Double = -1
        var longitude: Double = -1
        var speed: Double = -1
        var course: Double = -1
        var timesend: Double = -1
    }
    
    @objc func getDataFromCloud() {
        Task {
            try await getLocation()
        }
    }
    
    func getLocation() async throws {
        let url = URL(string: "https://surftracker-365018.ew.r.appspot.com/getlocation")!
        let urlRequest = URLRequest(url: url)
        let (data, response) = try await URLSession.shared.data(for: urlRequest)

        guard (response as? HTTPURLResponse)?.statusCode == 200 else { fatalError("Error while fetching data") }
        let decodedJson = try JSONDecoder().decode(serverLocation.self, from: data)
        
        surferLatitude = decodedJson.latitude
        surferLongitude = decodedJson.longitude
        print(decodedJson.timesend)
        
        DispatchQueue.main.async {
            self.serverResult = decodedJson.timesend.description
            self.region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: self.surferLatitude, longitude: self.surferLongitude), span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
        }
        
        //update camera loc as well
        cameraLatitude = myLatitude
        cameraLongitude = myLongitude

        
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        self.myLatitude = locations.first?.coordinate.latitude ?? 0
        self.myLongitude = locations.first?.coordinate.longitude ?? 0
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
            shareLocationTimer  = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(sendLocationToServer),userInfo: nil, repeats: true)
        }
        else {
            shareLocationTimer.invalidate()
        }
    }
    
    func toggleLocationGetting( _ isCamera : Bool) {
        if (isCamera) {
            getLocationTimer  = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(getDataFromCloud),userInfo: nil, repeats: true)
            modeIsCamera = true
        }
        else {
            getLocationTimer.invalidate()
            modeIsCamera = false
        }
    }
    
    @objc func sendLocationToServer() {
        
        let timesend = NSDate().timeIntervalSince1970
        let parameters: [String: Any] = ["longitude": myLongitude, "latitude": myLatitude,"speed":speed,"course":course,"timesend":timesend]
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
    
  
    

    
 
    
    
    
    
}

