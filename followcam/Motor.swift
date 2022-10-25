//
//  File.swift
//  tuto
//
//  Created by Peter Squla on 03/09/2022.
// connects to Nano via bluetooth

import Foundation
import CoreBluetooth
import CoreGraphics



class Motor : NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    @Published var bleDevices = "none"
    var centralManager: CBCentralManager!
    var nano : CBPeripheral!
    var characteristicTurnMotor : CBCharacteristic!
    var characteristicDegree : CBCharacteristic!
    public var myTracker : Tracker = Tracker()
    @Published var turnDegrees : CGFloat = 0
    
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
        print("trying to send teststring to nano: trueNorth: ")
        //loop through list of testlocations on every click
        //TODO lat and long seem reversed with station
        let surfer = CGPoint(x:myTracker.latitude,y:myTracker.longitude)
        turnDegrees =  getBearing(surfer) - myTracker.trueNorth
        //turnDegrees =  getBearing(targetlocations[curlocation]) - myTracker.trueNorth
        
        if(nano != nil) {
            nano.writeValue((turnDegrees.description.data(using: String.Encoding.utf8)!), for: characteristicDegree, type: .withResponse)
        }
    }
    
//    func setupTargetLocations() {
//        targetlocations.append(CGPoint(x:52.31218777103457,y:5.044288849771811)) //station
//        targetlocations.append(CGPoint(x:52.33655965,y:5.067187006)) //westbatterij
//        targetlocations.append(CGPoint(x:52.33519890317027,y:5.022494705810035)) //maxi
//        targetlocations.append(CGPoint(x:52.315075090648946,y:5.046573824530786)) //aartje de vos
//    }
    
    func getBearing(_ pointB : CGPoint) -> CGFloat {
        
        
        
        let pointA = CGPoint(x:myTracker.latitude,y:myTracker.longitude) //home
        print("home gps")
        //let pointB = CGPoint(x:52.33655965,y:5.067187006) //westbatterij
        //let pointB = CGPoint(x:52.33519890317027,y:5.022494705810035) //maxis
        //let pointB = CGPoint(x:52.315075090648946,y:5.046573824530786) //aartje de vos
        //let pointB = CGPoint(x:52.31218777103457,y:5.044288849771811) //station
        
        
        
        let lat1 = pointA.x.inRadians()
        let lat2 = pointB.x.inRadians()

        let diffLong = (pointB.y - pointA.y).inRadians()
        
        let x = sin(diffLong) * cos(lat2)
        let y = cos(lat1) * sin(lat2) - (sin(lat1) * cos(lat2) * cos(diffLong))

        var initial_bearing = atan2(x, y)

        initial_bearing = initial_bearing.inDegrees()
        
        let compass_bearing = (initial_bearing + 360).truncatingRemainder(dividingBy: 360)
        

        return(compass_bearing)
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
