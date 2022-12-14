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
    
    
    
    @Published var trueNorth = 0.0
    public var myLatitude = 0.0
    public var myLongitude = 0.0
    public var cameraLatitude = 1.0
    public var cameraLongitude = 1.0
    public var surferLatitude = 0.0
    public var surferLongitude = 0.0
    @Published var speed = 0.0
    @Published var course = 0.0
    private var surferSpeed = 0.0
    private var surferCourse = 0.0
    @Published var serverResult = "no server result"
    @Published var locationAuthorized = false
    private let locationManager : CLLocationManager
    @Published var bearingSurfer : CGFloat = 0
    @Published var turnDegrees : CGFloat = 0
    private var shareLocationTimer : Timer
    private var getLocationTimer : Timer
    @Published var region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 51.507222, longitude: -0.1275), span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5))
    private var simplecounter = 0
    private var modeIsCamera = false
    private var isPredictingLocation = false
    
    
    override init() {
        
        locationManager = CLLocationManager()
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.activityType = CLActivityType.fitness
        shareLocationTimer = Timer()
        getLocationTimer = Timer()
        super.init()
        
        locationManager.delegate = self
        
        
        print("Tracker init done")
        
        
        
    }
    
    struct serverLocation: Codable {
        var latitude: Double = -1
        var longitude: Double = -1
        var speed: Double = -1
        var course: Double = -1
        var timesend: Double = -1
    }
    
    class myState : ObservableObject{
        var test = "hoi"
    }
    
    
    @objc func getDataFromCloud() {
        Task {
            try await getLocation()
        }
    }
    
    func getLocation() async throws {
        
        //print("getLocation cloud download")
        
        let url = URL(string: "https://surftracker-365018.ew.r.appspot.com/getlocation")!
        let urlRequest = URLRequest(url: url)
        let (data, response) = try await URLSession.shared.data(for: urlRequest)

        guard (response as? HTTPURLResponse)?.statusCode == 200 else { fatalError("Error while fetching data") }
        let decodedJson = try JSONDecoder().decode(serverLocation.self, from: data)
        
        surferLatitude = decodedJson.latitude
        surferLongitude = decodedJson.longitude
        surferSpeed = decodedJson.speed
        surferCourse = decodedJson.course
        
        //TODO is this in the right spot?
        if isPredictingLocation {
            let curLocation = CLLocation(latitude: surferLatitude, longitude: surferLongitude)
            //TODO make this 2 a variable
            print("speed: \(surferSpeed)")
            print("course: \(surferCourse)")
            let distance = CLLocationDistance(surferSpeed * 2)
            let direction = CLLocationDirection(surferCourse)
            print(distance)
            let predictedLocation = curLocation.destinationBy(distance, direction: direction)
            surferLatitude = predictedLocation.coordinate.latitude
            surferLongitude = predictedLocation.coordinate.longitude
        }
        
        print(decodedJson.timesend)
        
        DispatchQueue.main.async {
            self.serverResult = decodedJson.timesend.description
        }
        
        //update camera loc as well
        cameraLatitude = myLatitude
        cameraLongitude = myLongitude

        //update TurnDegrees
        updateBearing()
     
        //myMainMotor.turnMotor()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        self.myLatitude = locations.first?.coordinate.latitude ?? 0
        self.myLongitude = locations.first?.coordinate.longitude ?? 0
        speed = locations.first?.speed ?? 0
        course = locations.first?.course ?? 0
        
   
        
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
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
        print("toggle setting")
        if (isSurfer) {
            shareLocationTimer  = Timer.scheduledTimer(timeInterval: 2, target: self, selector: #selector(sendLocationToServer),userInfo: nil, repeats: true)
        }
        else {
            shareLocationTimer.invalidate()
        }
    }

    func toggleIsPredicting( _ isPredicting : Bool) {
        print("toggle predicting location: \(isPredicting)")
        isPredictingLocation = isPredicting
    }

    
    func centerMap() {
        
        region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: myLatitude, longitude: myLongitude), span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1))
    }
    
    func toggleLocationGetting( _ isCamera : Bool) {
        print("toggle getting location")
        if (isCamera) {
            centerMap()
            
            getLocationTimer  = Timer.scheduledTimer(timeInterval: 2, target: self, selector: #selector(getDataFromCloud),userInfo: nil, repeats: true)
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
    
    //get angle from camera to surfer measure as degree from north
    func updateBearing() {
        //print("in update bearing")
        let lat1 = myLatitude.inRadians()
        let lat2 = surferLatitude.inRadians()

        let diffLong = (surferLongitude - myLongitude).inRadians()
        
        let x = sin(diffLong) * cos(lat2)
        let y = cos(lat1) * sin(lat2) - (sin(lat1) * cos(lat2) * cos(diffLong))
        
        DispatchQueue.main.async {
            self.bearingSurfer = (atan2(x,y).inDegrees() + 360).truncatingRemainder(dividingBy: 360)
            self.turnDegrees =  self.bearingSurfer - self.trueNorth + 270
            //shortest route
            if self.turnDegrees > 180 {
                self.turnDegrees = self.turnDegrees - 360
            }
            
            if self.turnDegrees < -180 {
                self.turnDegrees = self.turnDegrees + 360
            }

            
            myMainMotor.turnMotor(inTurnDegrees: self.turnDegrees)
        }
    }

    
    
    
    
    
}

// Calculate destination location based on origin location, distance (meters) and direction (degrees from north).
// Playing: myOriginLocation.destinationBy(distance: 5.0, direction: 45.0)
// http://www.geomidpoint.com/destination/calculation.html (Spherical earth model)
extension CLLocation {
    func destinationBy(_ distance: CLLocationDistance, direction: CLLocationDirection) -> CLLocation {
        let earthRadius     = 6372.7976
        let angularDistance = (distance / 1000) / earthRadius
        let originLatRad    = self.coordinate.latitude * (.pi / 180)
        let originLngRad    = self.coordinate.longitude * (.pi / 180)
        let directionRad    = direction * (.pi / 180)
        
        let destinationLatRad = asin(
            sin(originLatRad) * cos(angularDistance) +
                cos(originLatRad) * sin(angularDistance) *
                cos(directionRad))
        
        let destinationLngRad = originLngRad + atan2(
            sin(directionRad) * sin(angularDistance) * cos(originLatRad),
            cos(angularDistance) - sin(originLatRad) * sin(destinationLatRad))
        
        let destinationLat: CLLocationDegrees = destinationLatRad * (180 / .pi)
        let destinationLng: CLLocationDegrees = destinationLngRad * (180 / .pi)
        
        return CLLocation(latitude: destinationLat, longitude: destinationLng)
    }
}
