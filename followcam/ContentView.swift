import SwiftUI
import CoreLocation
import MapKit

struct ContentView: View {
    @StateObject var tracker = Tracker()
    @StateObject var motor = Motor ()
    @State private var msgfornano: String = "1"
    @State private var isSurfer = false
    @State public var isCamera = false
    
    
    struct Marker: Identifiable {
        let id = UUID()
        var location: MapMarker
    }
    
    
    var body: some View {
        
        VStack{
            
            
            Group {
                HStack {
                    Text("True north:")
                    Text(tracker.trueNorth.debugDescription)
                }
               
            }
            
            Group {
                
                HStack {
                    Text("Bluetooth device:")
                    Text(motor.bleDevices)
                }

                Button("ask for bluetooth permission") {
                    motor.startBluetooth()
                }
                HStack {
                    Text("Turndegrees:")
                    Text(motor.turnDegrees.description)
                }
                Link("API", destination: URL(string: "https://surftracker-365018.ew.r.appspot.com/")!)
            }
            Group {
                
                Button("Send msg to nano") {
                    motor.sendStringtoNano()
                }.padding()
        
                if tracker.locationAuthorized {
                
                    Toggle("share location",isOn: $isSurfer).padding().onChange(of: isSurfer) { newValue in
                        tracker.toggleLocationSending(newValue)
                    }.onAppear { UIApplication.shared.isIdleTimerDisabled = true }
                    

                    Toggle("get location",isOn: $isCamera).padding().onChange(of: isCamera) { newValue in
                        tracker.toggleLocationGetting(newValue)
                    }.onAppear { UIApplication.shared.isIdleTimerDisabled = true }
                    
                    //red means recording, blue means board
                    let markers = [Marker(location: MapMarker(coordinate: CLLocationCoordinate2D(latitude:tracker.latitude , longitude:tracker.longitude ), tint: .blue)),Marker(location: MapMarker(coordinate: CLLocationCoordinate2D(latitude:tracker.cameraLatitude , longitude:tracker.cameraLongitude ), tint: .red))]

                    
                    Map(coordinateRegion:$tracker.region,annotationItems: markers){ marker in
                        marker.location
                    }.frame(width:400,height:200)
                    
                }
                
                else {
                    Button("ask for location permission") {
                        tracker.requestPermission()
                    }
                }
  
              
                
                
                if isCamera {
                    Text(tracker.serverResult).padding().fixedSize(horizontal: false, vertical: true).font(.system(size: 16)).textSelection(.enabled)
                }
                
                
                
            }
   
         }
    
    }
    
    

    
}


