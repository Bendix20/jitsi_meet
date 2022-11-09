import UIKit
import JitsiMeetSDK

class JitsiViewController: UIViewController {
    
    @IBOutlet weak var videoButton: UIButton?
    
    fileprivate var pipViewCoordinator: PiPViewCoordinator?
    fileprivate var jitsiMeetView: JitsiMeetView?
    
    var eventSink:FlutterEventSink? = nil
    var roomName:String? = nil
    var serverUrl:URL? = nil
    var subject:String? = nil
    var audioOnly:Bool? = false
    var audioMuted: Bool? = false
    var videoMuted: Bool? = false
    var token:String? = nil
    var featureFlags: Dictionary<String, Any>? = Dictionary();
    var webOptions: Dictionary<String, Any>? = Dictionary();
    var configOverrides: Dictionary<String, Any>? = Dictionary();
    
    var jistiMeetUserInfo = JitsiMeetUserInfo()
    
    override func loadView() {
        
        super.loadView()
    }
    
    @objc func openButtonClicked(sender : UIButton){
        
        //openJitsiMeetWithOptions();
    }
    
    @objc func closeButtonClicked(sender : UIButton){
        cleanUp();
        self.dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        
        //print("VIEW DID LOAD")
        self.view.backgroundColor = .black
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        openJitsiMeet();
    }
    
    override func viewWillTransition(to size: CGSize,
                                     with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        let rect = CGRect(origin: CGPoint.zero, size: size)
        pipViewCoordinator?.resetBounds(bounds: rect)
    }
    
    func openJitsiMeet() {
        cleanUp()
        // create and configure jitsimeet view
        let jitsiMeetView = JitsiMeetView()
        
        
        jitsiMeetView.delegate = self
        self.jitsiMeetView = jitsiMeetView
        let options = JitsiMeetConferenceOptions.fromBuilder { (builder) in
            builder.welcomePageEnabled = true
            builder.room = self.roomName
            builder.serverURL = self.serverUrl
            builder.subject = self.subject
            builder.userInfo = self.jistiMeetUserInfo
            builder.audioOnly = self.audioOnly ?? false
            builder.audioMuted = self.audioMuted ?? false
            builder.videoMuted = self.videoMuted ?? false
            builder.token = self.token
            
            self.featureFlags?.forEach{ key,value in
                builder.setFeatureFlag(key, withValue: value);
            }
            
        }
        
        jitsiMeetView.join(options)
        
        // Enable jitsimeet view to be a view that can be displayed
        // on top of all the things, and let the coordinator to manage
        // the view state and interactions
        pipViewCoordinator = PiPViewCoordinator(withView: jitsiMeetView)
        pipViewCoordinator?.configureAsStickyView(withParentView: view)
        
        // animate in
        jitsiMeetView.alpha = 0
        pipViewCoordinator?.show()
    }
    
    func closeJitsiMeeting(){
        jitsiMeetView?.leave()
    }
    
    fileprivate func cleanUp() {
        jitsiMeetView?.removeFromSuperview()
        jitsiMeetView = nil
        pipViewCoordinator = nil
        //self.dismiss(animated: true, completion: nil)
    }
}

extension JitsiViewController: JitsiMeetViewDelegate {

    func ready(toClose data: [AnyHashable : Any]) {
        DispatchQueue.main.async {
            self.pipViewCoordinator?.hide { _ in
                self.cleanUp()
                self.dismiss(animated: true, completion: nil)
            }
        }
    }

    func conferenceWillJoin(_ data: [AnyHashable : Any]!) {
        self.eventSink(["event": "conferenceWillJoin", "data": data])
    }
    
    func conferenceJoined(_ data: [AnyHashable : Any]!) {
        self.eventSink(["event": "conferenceJoined", "data": data])
    }
    
    func conferenceTerminated(_ data: [AnyHashable : Any]!) {
        self.eventSink(["event": "conferenceTerminated", "data": data])
        
        DispatchQueue.main.async {
            self.pipViewCoordinator?.hide() { _ in
                self.cleanUp()
                self.dismiss(animated: true, completion: nil)
            }
        }
        
    }
    
    func enterPicture(inPicture data: [AnyHashable : Any]!) {
        //        print("CONFERENCE PIP IN")
        var mutatedData = data
        mutatedData?.updateValue("onPictureInPictureWillEnter", forKey: "event")
        self.eventSink?(mutatedData)
        DispatchQueue.main.async {
            self.pipViewCoordinator?.enterPictureInPicture()
        }
    }
    
    func exitPictureInPicture() {
        //        print("CONFERENCE PIP OUT")
        var mutatedData : [AnyHashable : Any]
        mutatedData = ["event":"onPictureInPictureTerminated"]
        self.eventSink?(mutatedData)
    }

    func participantJoined(_ data: [AnyHashable : Any]) {
        self.eventSink(["event": "participantJoined", "data": data])
    }

    func participantLeft(_ data: [AnyHashable : Any]) {
        self.eventSink(["event": "participantLeft", "data": data])
    }

    func audioMutedChanged(_ data: [AnyHashable : Any]) {
        self.eventSink(["event": "audioMutedChanged", "data": data])
    }

    func endpointTextMessageReceived(_ data: [AnyHashable : Any]) {
        self.eventSink(["event": "endpointTextMessageReceived", "data": data])
    }

    func screenShareToggled(_ data: [AnyHashable : Any]) {
        self.eventSink(["event": "screenShareToggled", "data": data])
    }

    func chatMessageReceived(_ data: [AnyHashable : Any]) {
        self.eventSink(["event": "chatMessageReceived", "data": data])
    }

    func chatToggled(_ data: [AnyHashable : Any]) {
        self.eventSink(["event": "chatToggled", "data": data])
    }

    func videoMutedChanged(_ data: [AnyHashable : Any]) {
        self.eventSink(["event": "videoMutedChanged", "data": data])
    }
}

class AbsorbPointersView: UIView {
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
    }
}