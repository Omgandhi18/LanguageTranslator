//
//  CameraVC.swift
//  LanguageTranslator
//
//  Created by Om Gandhi on 03/06/2024.
//

import UIKit
import AVFoundation
import CoreVideo
import MLKit
import MaterialComponents
private let boxWidth: CGFloat = 340.0
private let boxHeight: CGFloat = 100.0
private let boxWidthHalf = boxWidth / 2
private let boxHeightHalf = boxHeight / 2
private let hdWidth: CGFloat = 720  // AVCaptureSession.Preset.hd1280x720
private let hdHeight: CGFloat = 1280  // AVCaptureSession.Preset.hd1280x720
private let hdWidthHalf = hdWidth / 2
private let hdHeightHalf = hdHeight / 2
private let defaultMargin: CGFloat = 16
private let chipHeight: CGFloat = 32
private let chipHeightHalf = chipHeight / 2
private let customSelectedColor = UIColor(red: 0.10, green: 0.45, blue: 0.91, alpha: 1.0)
private let backgroundColor = UIColor(red: 0.91, green: 0.94, blue: 0.99, alpha: 1.0)

class CameraVC: UIViewController {

    @IBOutlet weak var lblTranslatedText: UILabel!
    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var lblDetectedText: UILabel!
    
  
    private var pendingRequestWorkItem: DispatchWorkItem?
    var detectedText = ""
    var captureSession = AVCaptureSession()
    var previewLayer = AVCaptureVideoPreviewLayer()
    private var cameraOverlayView: CameraOverlayView!
    private lazy var languageId = LanguageIdentification.languageIdentification()
    private lazy var sessionQueue = DispatchQueue(label: "com.google.mlkit.visiondetector.SessionQueue")
    private lazy var shapeGenerator: MDCRectangleShapeGenerator = {
        let gen = MDCRectangleShapeGenerator()
        gen.setCorners(MDCCornerTreatment.corner(withRadius: 4))
        return gen
      }()
    let containerScheme = MDCContainerScheme()
    private lazy var annotationOverlayView: UIView = {
       precondition(isViewLoaded)
       let annotationOverlayView = UIView(frame: .zero)
       annotationOverlayView.translatesAutoresizingMaskIntoConstraints = false
       return annotationOverlayView
     }()
    var cropX = 0
     var cropWidth = 0
     var cropY = 0
     var cropHeight = 0
    var detectedLanguage = TranslateLanguage.english
    var translator: Translator!
    override func viewDidLoad() {
        super.viewDidLoad()
        loadCamera()
        setUpCameraOverlayView()
        let ratio = hdWidth / cameraView.bounds.width
            cropX = Int(hdHeightHalf - (ratio * boxHeightHalf))
            cropWidth = Int(boxHeight * ratio)
            cropY = Int(hdWidthHalf - (ratio * boxWidthHalf))
            cropHeight = Int(boxWidth * ratio)
        
       setUpCaptureSessionOutput()
        setUpCaptureSessionInput()
        // Do any additional setup after loading the view.
    }
    override func viewDidAppear(_ animated: Bool) {
        if cameraOverlayView == nil {
              setUpCameraOverlayView()
            }
            startSession()
    }
    
    func loadCamera() {
            
        let device = AVCaptureDevice.default(.builtInTripleCamera, for: AVMediaType.video, position: .back)
            
            do {
                let input = try AVCaptureDeviceInput(device: device!)
                
                if captureSession.canAddInput(input) {
                    captureSession.addInput(input)
                    
                    previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
                    previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
                    previewLayer.connection?.videoOrientation = AVCaptureVideoOrientation.portrait
                    previewLayer.frame = cameraView.layer.frame
                    cameraView.layer.addSublayer(previewLayer)
                    captureSession.startRunning()
                    
                }
                
            } catch {
                print(error)
            }
        }
    private func setUpCameraOverlayView() {
        cameraOverlayView = CameraOverlayView(frame: cameraView.bounds)
        let rect = CGRect(
          x: cameraView.bounds.midX - boxWidthHalf,
          y: cameraView.bounds.midY - boxHeightHalf,
          width: boxWidth,
          height: boxHeight)
        cameraOverlayView.showBox(in: rect)
        cameraView.addSubview(cameraOverlayView)
        let chipY = cameraView.bounds.midY + boxHeightHalf + chipHeightHalf + defaultMargin
        cameraOverlayView.showMessage(
          "Center text in box and hold for a while",
          in: CGPoint(x: cameraView.bounds.midX, y: chipY))
      }
    private func setUpCaptureSessionOutput() {
        sessionQueue.async {
          self.captureSession.beginConfiguration()
          // When performing latency tests to determine ideal capture settings,
          // run the app in 'release' mode to get accurate performance metrics
          self.captureSession.sessionPreset = AVCaptureSession.Preset.hd1280x720

          let output = AVCaptureVideoDataOutput()
          output.videoSettings =
            [(kCVPixelBufferPixelFormatTypeKey as String): kCVPixelFormatType_32BGRA]
          let outputQueue = DispatchQueue(label: "com.google.mlkit.visiondetector.VideoDataOutputQueue")
          output.alwaysDiscardsLateVideoFrames = true
          output.setSampleBufferDelegate(self, queue: outputQueue)
          guard self.captureSession.canAddOutput(output) else {
            print("Failed to add capture session output.")
            return
          }
          self.captureSession.addOutput(output)
          self.captureSession.commitConfiguration()
        }
      }

      private func setUpCaptureSessionInput() {
        sessionQueue.async {
          let cameraPosition: AVCaptureDevice.Position = .back
          guard let device = self.captureDevice(forPosition: cameraPosition) else {
            print("Failed to get capture device for back camera position")
            return
          }
          do {
            self.captureSession.beginConfiguration()
            let currentInputs = self.captureSession.inputs
            for input in currentInputs {
              self.captureSession.removeInput(input)
            }

            let input = try AVCaptureDeviceInput(device: device)
            guard self.captureSession.canAddInput(input) else {
              print("Failed to add capture session input.")
              return
            }
            self.captureSession.addInput(input)
            self.captureSession.commitConfiguration()
          } catch {
            print("Failed to create capture device input: \(error.localizedDescription)")
          }
        }
      }
    private func captureDevice(forPosition position: AVCaptureDevice.Position) -> AVCaptureDevice? {
       if #available(iOS 10.0, *) {
         let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInTripleCamera],
           mediaType: .video,
           position: .unspecified
         )
         return discoverySession.devices.first { $0.position == position }
       }
       return nil
     }
    private func startSession() {
        sessionQueue.async {
          self.captureSession.startRunning()
        }
      }

      private func stopSession() {
        sessionQueue.async {
          self.captureSession.stopRunning()
        }
      }
    private func recognizeTextOnDevice(in image: VisionImage) {
        let textRecognizer = TextRecognizer.textRecognizer()
        let group = DispatchGroup()
        group.enter()
        textRecognizer.process(image) { text, error in
          group.leave()
//          self.removeDetectionAnnotations()

          guard error == nil, let text = text else {
            print(
              "On-Device text recognizer error: "
                + "\(error?.localizedDescription ?? "No results")")
            return
          }
          // Blocks.
          guard let block = text.blocks.first else { return }
          let detection = block.text
          if detection == self.detectedText {
            return
          }

          self.detectedText = detection
          DispatchQueue.main.async {
            self.lblDetectedText.text = detection
          }

          self.identifyLanguage(for: detection)
        }
        group.wait()
      }
    func translate(_ inputText: String) {
        //MARK: Insert language selected option
        let options = TranslatorOptions(
          sourceLanguage: detectedLanguage,
          targetLanguage: TranslateLanguage.english)
        translator = Translator.translator(options: options)

        let translatorForDownloading = self.translator!
        translatorForDownloading.downloadModelIfNeeded { error in
          guard error == nil else {
            self.startSession()
            print("Failed to ensure model downloaded with error \(error!)")
            return
          }
          if translatorForDownloading == self.translator {
            translatorForDownloading.translate(inputText) { result, error in
              self.startSession()
              self.lblTranslatedText.text = ""
              guard error == nil else {
                print("Failed with error \(error!)")
                  self.lblTranslatedText.text = ""
                return
              }
              if translatorForDownloading == self.translator {
                DispatchQueue.main.async {
                  self.lblTranslatedText.text = result
                }
              }
            }
          }
        }
      }
    private func identifyLanguage(for text: String) {
        self.pendingRequestWorkItem?.cancel()

        // Wrap our request in a work item
        let requestWorkItem = DispatchWorkItem { [weak self] in
          self?.languageId.identifyLanguage(for: text) { languageTag, error in
            if let error = error {
              print("Failed with error: \(error)")
              return
            }
            guard let languageTag = languageTag else {
              print("No language was identified.")
              return
            }
            let detectedLanguage = TranslateLanguage(rawValue: languageTag)
            guard TranslateLanguage.allLanguages().contains(detectedLanguage) else {
              return
            }
            if detectedLanguage != self?.detectedLanguage {
              self?.detectedLanguage = detectedLanguage
              DispatchQueue.main.async {
//                self?.detectedLanguageLabel.text = detectedLanguage.localizedName()
              }
            }
            self?.translate(text)
          }
        }

        // Save the new work item and execute it after 50 ms
        self.pendingRequestWorkItem = requestWorkItem
        DispatchQueue.main.asyncAfter(
          deadline: .now() + .milliseconds(50),
          execute: requestWorkItem)
      }
    
}
extension CameraVC: AVCaptureVideoDataOutputSampleBufferDelegate {

  func captureOutput(
    _ output: AVCaptureOutput,
    didOutput sampleBuffer: CMSampleBuffer,
    from connection: AVCaptureConnection
  ) {

    guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
    let newBuffer = resizePixelBuffer(
      imageBuffer, cropX: cropX, cropY: cropY, cropWidth: cropWidth, cropHeight: cropHeight)

    var sampleTime = CMSampleTimingInfo()
    sampleTime.duration = CMSampleBufferGetDuration(sampleBuffer)
    sampleTime.presentationTimeStamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
    sampleTime.decodeTimeStamp = CMSampleBufferGetDecodeTimeStamp(sampleBuffer)
    var videoInfo: CMVideoFormatDescription?
      CMVideoFormatDescriptionCreateForImageBuffer(allocator: kCFAllocatorDefault, imageBuffer: newBuffer!, formatDescriptionOut: &videoInfo)

    // Creates `CMSampleBufferRef`.
    var resultBuffer: CMSampleBuffer? = nil
    CMSampleBufferCreateForImageBuffer(
        allocator: kCFAllocatorDefault, imageBuffer: newBuffer!, dataReady: true, makeDataReadyCallback: nil, refcon: nil, formatDescription: videoInfo!, sampleTiming: &sampleTime, sampleBufferOut: &resultBuffer)

    let visionImage = VisionImage.init(buffer: resultBuffer!)
      let orientation = CameraVC.imageOrientation(
      fromDevicePosition: .back
    )

    visionImage.orientation = orientation

    self.recognizeTextOnDevice(in: visionImage)

  }
    public static func imageOrientation(
        fromDevicePosition devicePosition: AVCaptureDevice.Position = .back
    ) -> UIImage.Orientation {
        var deviceOrientation = UIDevice.current.orientation
        if deviceOrientation == .faceDown || deviceOrientation == .faceUp
          || deviceOrientation == .unknown
        {
          deviceOrientation = currentUIOrientation()
        }
        switch deviceOrientation {
        case .portrait:
          return devicePosition == .front ? .leftMirrored : .right
        case .landscapeLeft:
          return devicePosition == .front ? .downMirrored : .up
        case .portraitUpsideDown:
          return devicePosition == .front ? .rightMirrored : .left
        case .landscapeRight:
          return devicePosition == .front ? .upMirrored : .down
        case .faceDown, .faceUp, .unknown:
          return .up
        @unknown default:
            print("error")
            return .up
        }
      }
    private static func currentUIOrientation() -> UIDeviceOrientation {
       let deviceOrientation = { () -> UIDeviceOrientation in
         switch UIApplication.shared.statusBarOrientation {
         case .landscapeLeft:
           return .landscapeRight
         case .landscapeRight:
           return .landscapeLeft
         case .portraitUpsideDown:
           return .portraitUpsideDown
         case .portrait, .unknown:
           return .portrait
         @unknown default:
             print("error")
             return .unknown
         }
       }
       guard Thread.isMainThread else {
         var currentOrientation: UIDeviceOrientation = .portrait
         DispatchQueue.main.sync {
           currentOrientation = deviceOrientation()
         }
         return currentOrientation
       }
       return deviceOrientation()
     }
   


}
