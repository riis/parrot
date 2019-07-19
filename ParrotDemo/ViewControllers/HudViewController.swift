//
//  HudViewController.swift
//  ParrotDemo
//
//  Created by ian timmis on 7/18/19.
//  Copyright © 2019 RIIS. All rights reserved.
//

import UIKit
import GroundSdk

class HudViewController: UIViewController {
    
    private let groundSdk = GroundSdk()
    private var droneUid: String?
    private var drone: Drone?
    @IBOutlet weak var takeoffLandButton: UIButton!
    
    let takeOffButtonImage = UIImage(named: "ic_flight_takeoff_48pt")
    let landButtonImage = UIImage(named: "ic_flight_land_48pt")
    let handButtonImage = UIImage(named: "ic_flight_hand_48pt")
    
    private var pilotingItf: Ref<ManualCopterPilotingItf>?

    override func viewDidLoad() {
        super.viewDidLoad()
        let value = UIInterfaceOrientation.landscapeRight.rawValue
        UIDevice.current.setValue(value, forKey: "orientation")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        // get the drone
        if let droneUid = droneUid {
            drone = groundSdk.getDrone(uid: droneUid) { [unowned self] _ in
                self.dismiss(self)
            }
        }
        
        if let drone = drone {
            initDroneRefs(drone)
        } else {
            dismiss(self)
        }
    }
    
    func setDeviceUid(_ uid: String) {
        droneUid = uid
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscapeRight
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    @IBAction func dismiss(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    private func initDroneRefs(_ drone: Drone) {
        pilotingItf = drone.getPilotingItf(PilotingItfs.manualCopter) { [unowned self] pilotingItf in
            self.updateTakeoffLandButton(pilotingItf)
        }
    }
    
    @IBAction func takeOffLand(_ sender: Any) {
        if let pilotingItf = pilotingItf?.value {
            pilotingItf.smartTakeOffLand()
        }
    }
    
    private func updateTakeoffLandButton(_ pilotingItf: ManualCopterPilotingItf?) {
        if let pilotingItf = pilotingItf, pilotingItf.state == .active {
            takeoffLandButton.isHidden = false
            let smartAction = pilotingItf.smartTakeOffLandAction
            switch smartAction {
            case .land:
                takeoffLandButton.setImage(landButtonImage, for: .normal)
            case .takeOff:
                takeoffLandButton.setImage(takeOffButtonImage, for: .normal)
            case .thrownTakeOff:
                takeoffLandButton.setImage(handButtonImage, for: .normal)
            case .none:
                ()
            }
            takeoffLandButton.isEnabled = smartAction != .none
        } else {
            takeoffLandButton.isEnabled = false
            takeoffLandButton.isHidden = true
        }
    }
    
    @IBAction func leftJoystickUpdate(_ sender: JoystickView) {
        if let pilotingItf = pilotingItf?.value, pilotingItf.state == .active {
            pilotingItf.set(pitch: -sender.value.y)
            pilotingItf.set(roll: sender.value.x)
        }
    }
    
    @IBAction func rightJoystickUpdate(_ sender: JoystickView) {
        if let pilotingItf = pilotingItf?.value, pilotingItf.state == .active {
            pilotingItf.set(verticalSpeed: sender.value.y)
            pilotingItf.set(yawRotationSpeed: sender.value.x)
        } 
    }
}
