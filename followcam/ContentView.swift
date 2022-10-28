import SwiftUI
import CoreLocation
import MapKit

struct ContentView: View {
    @StateObject var tracker = Tracker()
    @StateObject var motor = Motor ()
    @State private var msgfornano: String = "1"
    @State public var isSurfer = false
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
                    Text(String(format: "%.1f", tracker.trueNorth))
                    
                }
                HStack {
                    Text("Bearing surfer:")
                    Text(String(format: "%.1f", motor.bearingSurfer))
                }
                HStack {
                    Text("Turndegrees:")
                    Text(String(format: "%.1f", motor.turnDegrees))
                }
            }
            
            Group {
                
                HStack {
                    Text("Bluetooth device:")
                    Text(motor.bleDevices)
                }
                
                if !motor.bluetoothAllowed {
                    Button("ask for bluetooth permission") {
                        motor.startBluetooth()
                    }
                }
            
                Link("API", destination: URL(string: "https://surftracker-365018.ew.r.appspot.com/")!)
            }
            Group {
                
                Button("Send msg to nano") {
                    motor.sendStringtoNano()
                }.padding()
        
                if tracker.locationAuthorized {
                
                    Toggle("Start surfer",isOn: $isSurfer).padding().onChange(of: isSurfer) { newValue in
                        tracker.toggleLocationSending(newValue)
                    }.onAppear { UIApplication.shared.isIdleTimerDisabled = true }
                    

                    Toggle("Start camera",isOn: $isCamera).padding().onChange(of: isCamera) { newValue in
                        tracker.toggleLocationGetting(newValue)
                    }.onAppear { UIApplication.shared.isIdleTimerDisabled = true }
                    
                    //red means recording, blue means board
                    let markers = [Marker(location: MapMarker(coordinate: CLLocationCoordinate2D(latitude:tracker.surferLatitude , longitude:tracker.surferLongitude ), tint: .blue)),Marker(location: MapMarker(coordinate: CLLocationCoordinate2D(latitude:tracker.cameraLatitude , longitude:tracker.cameraLongitude ), tint: .red))]

                    
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


