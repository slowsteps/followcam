import SwiftUI

var myMainTracker = Tracker()
var myMainMotor = Motor()


@main



struct MyApp: App {
    
    
    
    init() {
        
        
//        myMainTracker = Tracker()
//        myMainMotor = Motor()
        
    }
    
    var body: some Scene {
        WindowGroup {
            
            
            
            NavigationView {
                List {
                    NavigationLink("tracker") {
                        ContentView(amotor: myMainMotor, atracker: myMainTracker)
                    }
                    
                    NavigationLink("video") {
                        RecordingView()
                    }

                }
                
            }
            
            

        }
    }

    
}
