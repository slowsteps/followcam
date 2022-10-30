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
            ContentView(amotor: myMainMotor, atracker: myMainTracker)
        }
    }

    
}
