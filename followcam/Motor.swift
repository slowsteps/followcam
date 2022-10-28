//
//  File.swift
//  tuto
//
//  Created by Peter Squla on 03/09/2022.
// connects to Nano via bluetooth

import Foundation
import CoreBluetooth
import CoreGraphics
import CoreLocation



class Motor : NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    @Published var bleDevices = "none"
    var centralManager: CBCentralManager!
    var nano : CBPeripheral!
    var characteristicTurnMotor : CBCharacteristic!
    var characteristicDegree : CBCharacteristic!
    public var myTracker : Tracker = Tracker()
    @Published var turnDegrees : CGFloat = 0
    @Published var bearingSurfer : CGFloat = 0
    @Published var bluetoothAllowed = false
    
    override init() {
        super.init()
        startBluetooth()
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print("state \(central.state)")
        
        switch central.state  {
        
        case CBManagerState.poweredOn :
            print("poweredOn")
            centralManager.scanForPeripherals(withServices: nil,options: nil)
            bluetoothAllowed = true
        case CBManagerState.poweredOff :
            print("poweredOff")
        case CBManagerState.unknown :
            print("unknown")
        case CBManagerState.unauthorized :
            print("unauthorized")
        case CBManagerState.resetting :
            print("unauthorized")
        case CBManagerState.unsupported :
            print("unsupported")
        default :
            print("fell through case")
        }
    
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
            //print("scanning for Nano")
        if (peripheral.name != nil) {
            if (peripheral.name!.contains("Nano") || peripheral.name!.contains("Arduino") ) {
                nano = peripheral
                bleDevices = nano.name!
                central.stopScan()
                centralManager.connect(peripheral)
            }
        }
        
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        let unknowdevicename = "unknown"
        print("connected to: \(peripheral.name ?? unknowdevicename)")
        peripheral.discoverServices(nil)
        peripheral.delegate = self
    }
    
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        
        print("services")
        print(peripheral.services.debugDescription)
        for service in peripheral.services! {
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let charac = service.characteristics {
            for characteristic in charac {
                if (characteristic.uuid.debugDescription.contains("1A57")) { characteristicDegree = characteristic }
                if (characteristic.uuid.debugDescription.contains("2A57")) { characteristicTurnMotor = characteristic }
                }
            }
    }
    
    
    func sendStringtoNano() {
        print("trying to send teststring to nano: ")
   
        print("myLatitude: \(myTracker.myLatitude)")
        print("myLongitude: \(myTracker.myLongitude)")
        print("surferLatitude: \(myTracker.surferLatitude)")
        print("surferLongitude: \(myTracker.surferLongitude)")
        
        turnDegrees =  getBearing() - myTracker.trueNorth
                
        if(nano != nil) {
            nano.writeValue((turnDegrees.description.data(using: String.Encoding.utf8)!), for: characteristicDegree, type: .withResponse)
        }
    }
    

    
    func getBearing() -> CGFloat {
        
        
        let lat1 = myTracker.myLatitude.inRadians()
        let lat2 = myTracker.surferLatitude.inRadians()

        let diffLong = (myTracker.surferLongitude - myTracker.myLongitude).inRadians()
        
        let x = sin(diffLong) * cos(lat2)
        let y = cos(lat1) * sin(lat2) - (sin(lat1) * cos(lat2) * cos(diffLong))

        var initial_bearing = atan2(x, y)

        initial_bearing = initial_bearing.inDegrees()

        bearingSurfer = (initial_bearing + 360).truncatingRemainder(dividingBy: 360)
        

        return(bearingSurfer)
    }
    
    func startBluetooth() {
        print("trying to start bluetooth")
        centralManager = CBCentralManager(delegate: self, queue: nil)
    
    }
    
    
    
    func startScanning() {
        print("trying to start scanning")
        centralManager.scanForPeripherals(withServices: nil,options: nil)
    }
 
    
    
}

extension BinaryFloatingPoint {
    func inRadians() -> Self {
        return self * .pi / 180
    }
}

extension BinaryFloatingPoint {
    func inDegrees() -> Self {
        return self * 180 / .pi
    }
}

extension FloatingPoint {

    var degreesToRadians: Self { return self * .pi / 180 }
    var radiansToDegrees: Self { return self * 180 / .pi }
}



   

