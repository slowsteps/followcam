import SwiftUI
import AVKit
import Photos


struct RecordingView: View {
    @State private var timer = 5
    @State private var onComplete = false
    @State private var recording = false
    
    var body: some View {
        ZStack {

            
            VStack {

                Toggle("Record video", isOn: $recording).padding()
                
                VideoRecordingView(timeLeft: $timer, onComplete: $onComplete, recording: $recording)
            }

        }
    }
    
}

struct RecordingView_Previews: PreviewProvider {
    static var previews: some View {
        RecordingView()
    }
}


struct VideoRecordingView: UIViewRepresentable {
    
    @Binding var timeLeft: Int
    @Binding var onComplete: Bool
    @Binding var recording: Bool
    
    
    func makeUIView(context: UIViewRepresentableContext<VideoRecordingView>) -> PreviewView {
        let recordingView = PreviewView()
        return recordingView
    }
    
    func updateUIView(_ uiViewController: PreviewView, context: UIViewRepresentableContext<VideoRecordingView>) {
        print("updateUIView recording: \(recording)")
        
        if !recording { uiViewController.stopRecordingNow()}
        if recording { uiViewController.startRecording()}
    }


    
}

extension PreviewView: AVCaptureFileOutputRecordingDelegate{
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        
        print("recording stopped, trying to save to camera roll")
        print(outputFileURL.relativePath)
        
        if error != nil {
            print(error.debugDescription)
        }
 
        if UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(outputFileURL.relativePath) {
            print("file is compatible")
            UISaveVideoAtPathToSavedPhotosAlbum(outputFileURL.relativePath,nil,nil,nil)
        }
        else {
            print("file is not compatible")
        }
    }
}

class PreviewView: UIView {
    private var captureSession: AVCaptureSession?
    let videoFileOutput = AVCaptureMovieFileOutput()
    var recordingDelegate:AVCaptureFileOutputRecordingDelegate!
    
    
    init() {
        super.init(frame: .zero)
        
        print("status:")
        let status = PHPhotoLibrary.authorizationStatus()
        if status == PHAuthorizationStatus.authorized {
            print("authorized")
        }
        else if status == PHAuthorizationStatus.notDetermined {
            print("nonDetermined")
            //ask for permission
            PHPhotoLibrary.requestAuthorization({ (newStatus) in
                
                if (newStatus == PHAuthorizationStatus.authorized) {
                    print("authorized")
                }
                
                else {
                    print("unknown")
                }
            })
            
        }
        else if status == PHAuthorizationStatus.denied {
            print("denied")
        }
        else {
            print("unknown")
        }
        
        var allowedAccess = false
        let blocker = DispatchGroup()
        blocker.enter()
        AVCaptureDevice.requestAccess(for: .video) { flag in
            allowedAccess = flag
            blocker.leave()
        }
        blocker.wait()
        
        if !allowedAccess {
            print("access to camera for video not allowed")
            return
        }
        
        // setup session
        let session = AVCaptureSession()
        session.beginConfiguration()
        
        let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera,for: .video, position: .front)
        guard videoDevice != nil, let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice!), session.canAddInput(videoDeviceInput) else {print("no camera")
            return
        }
        session.addInput(videoDeviceInput)
        session.commitConfiguration()
        self.captureSession = session
        
    }
    
    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        return layer as! AVCaptureVideoPreviewLayer
    }
    
    //TODO move this to some general setup function, so that reording can happen without preview.
    override func didMoveToSuperview() {
        print("didMoveToSuperview - setting up session")
        super.didMoveToSuperview()
        recordingDelegate = self
        
        if nil != self.superview {
            self.videoPreviewLayer.session = self.captureSession
            self.videoPreviewLayer.videoGravity = .resizeAspectFill
            self.captureSession?.startRunning()
            self.captureSession?.addOutput(videoFileOutput)
        
        } else {
            self.captureSession?.stopRunning()
        }
    }
    
    func setupSession() {
        recordingDelegate = self
        self.videoPreviewLayer.session = self.captureSession
        self.videoPreviewLayer.videoGravity = .resizeAspect
        self.captureSession?.startRunning()
        self.captureSession?.addOutput(videoFileOutput)
    }
    
    public func stopRecordingNow() {
        print("trying to stop recording")
        
        videoFileOutput.stopRecording()
        
    }
    
    
    func startRecording() {
        print("startrecording")
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let filePath = documentsURL.appendingPathComponent("capture.mp4")
        
        videoFileOutput.startRecording(to: filePath, recordingDelegate: recordingDelegate)
    }
    
    
    

    
}
