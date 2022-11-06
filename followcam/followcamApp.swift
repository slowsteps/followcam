import SwiftUI

var myMainTracker = Tracker()
var myMainMotor = Motor()


@main



struct MyApp: App {
    
    
    
    init() {
        
    }
    
    var body: some Scene {
        WindowGroup {
            
            ContentView(amotor: myMainMotor, atracker: myMainTracker)
            
//            NavigationView {
//                List {
//                    NavigationLink("tracker") {
//                        ContentView(amotor: myMainMotor, atracker: myMainTracker)
//                    }
//
//                    NavigationLink("video") {
//                        RecordingView()
//                    }
//
//                }
//
//            }
            
            

        }
    }

    
}
