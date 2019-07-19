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

    /**
     Responds to the view loading. We setup landscape orientation here.
     */
    override func viewDidLoad() {
        super.viewDidLoad()
        let value = UIInterfaceOrientation.landscapeRight.rawValue
        UIDevice.current.setValue(value, forKey: "orientation")
    }
    
    /**
     View will appear. We get the drone and setup the interfaces to it. If
     the drone disconnects, we push back to the home viewcontroller.
     */
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
    
    /**
     Sets the deviceUid to the current connected drones identifier.
     
     - Parameter uid:   The uid of the drone
     */
    func setDeviceUid(_ uid: String) {
        droneUid = uid
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscapeRight
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    /**
     Sends us back to the home viewcontroller.
     
     - Parameter sender: the caller fo this function.
     */
    @IBAction func dismiss(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    /**
     Initializes the interfaces to our drone. In this case, we only setup the manual
     piloting interface, but in the future we could add additional interfaces here.
     (Such as follow me, automated flight, etc.)
     
     - Parameter drone: The drone we are connected to
     */
    private func initDroneRefs(_ drone: Drone) {
        pilotingItf = drone.getPilotingItf(PilotingItfs.manualCopter) { [unowned self] pilotingItf in
            self.updateTakeoffLandButton(pilotingItf)
        }
    }
    
    /**
     Responds to the takeoffLand button click action. The drone will automatically takeoff
     if grounded or land if in flight.
     
     - Parameter sender: The takeoffLand button on the Hud viewcontroller.
     */
    @IBAction func takeOffLand(_ sender: Any) {
        if let pilotingItf = pilotingItf?.value {
            pilotingItf.smartTakeOffLand()
        }
    }
    
    /**
     This function is called by the piloting interface on the event of a new
     smartTakeOffLand action being performed on the drone. This updates the image
     of the takeoffLand button dynamically to represent the action being performed.
     
     - Parameter pilotingItf: The piloting interface used for manual flight.
     */
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
    
    /**
     Responds to the Left Joystick. Updates the pitch and roll of the drone in real time.
     
     - Parameter sender: The left joystick on the Hud viewcontroller.
     */
    @IBAction func leftJoystickUpdate(_ sender: JoystickView) {
        if let pilotingItf = pilotingItf?.value, pilotingItf.state == .active {
            pilotingItf.set(pitch: -sender.value.y)
            pilotingItf.set(roll: sender.value.x)
        }
    }
    
    /**
     Responds to the Right Joystick. Updates the vertical speed and yaw rotation in real time.
     
     - Parameter sender: The right joystick on the Hud viewcontroller.
     */
    @IBAction func rightJoystickUpdate(_ sender: JoystickView) {
        if let pilotingItf = pilotingItf?.value, pilotingItf.state == .active {
            pilotingItf.set(verticalSpeed: sender.value.y)
            pilotingItf.set(yawRotationSpeed: sender.value.x)
        } 
    }
}
