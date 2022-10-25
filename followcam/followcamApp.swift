import SwiftUI

@main


struct MyApp: App {
    
    
    public var myTracker : Tracker
    public var myMotor : Motor
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
    
    init() {
        
        
        myTracker = Tracker()
        myMotor = Motor()
        myTracker.myMotor = myMotor
        myMotor.myTracker = myTracker
        
    }
    

    
}
