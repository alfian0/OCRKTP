//
//  OCRNIKController.swift
//  OCRKTP
//
//  Created by M. Alfiansyah Nur Cahya Putra on 28/10/22.
//

import UIKit
import AVFoundation
import Vision

public protocol OCRNIKControllerDelegate {
    func didSuccessParseKTP(data: DataNIKModel)
}

public class OCRNIKController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    private let captureSession = AVCaptureSession()
    private lazy var previewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
    private let videoDataOutput = AVCaptureVideoDataOutput()
    private var bBoxLayer = CAShapeLayer()
    private var isTapped = false
    public var delegate: OCRNIKControllerDelegate?
    
    private let image: UIImageView = {
        let v = UIImageView()
        v.layer.borderWidth = 2
        v.layer.borderColor = UIColor.white.cgColor
        v.layer.cornerRadius = 4
        v.backgroundColor = .black
        v.contentMode = .scaleAspectFill
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    
    private lazy var button: UIButton = {
        let v = UIButton()
        v.backgroundColor = .red
        v.layer.cornerRadius = 56/2
        v.setTitle(nil, for: .normal)
        v.addTarget(self, action: #selector(onTap(_:)), for: .touchUpInside)
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    
    private let camera: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    
    private let success: UIImageView = {
        let v = UIImageView()
        v.tintColor = .white
        v.isHidden = true
        v.image = UIImage(named: "checkmark", in: Bundle(for: OCRNIKController.self), compatibleWith: nil)
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    
    private let activityIndicator: UIActivityIndicatorView = {
        let v = UIActivityIndicatorView()
        v.hidesWhenStopped = true
        v.style = .medium
        v.isHidden = true
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    
    @objc
    private func onTap(_ sender: UIButton) {
        isTapped = true
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .black
        
        self.setCameraInput()
        self.showCameraFeed()
        self.setCameraOutput()
        
        button.widthAnchor.constraint(equalToConstant: 56).isActive = true
        button.heightAnchor.constraint(equalToConstant: 56).isActive = true
        button.addTarget(self, action: #selector(onTap(_:)), for: .touchUpInside)
        
        image.widthAnchor.constraint(equalToConstant: 56).isActive = true
        image.heightAnchor.constraint(equalToConstant: 56).isActive = true
        
        view.addSubview(camera)
        camera.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        camera.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        camera.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        camera.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        
        view.addSubview(button)
        button.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        button.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: view.safeAreaInsets.bottom-8).isActive = true
        
        view.addSubview(image)
        image.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 8).isActive = true
        image.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: view.safeAreaInsets.bottom-8).isActive = true
        
        image.addSubview(success)
        success.widthAnchor.constraint(equalToConstant: 24).isActive = true
        success.heightAnchor.constraint(equalToConstant: 24).isActive = true
        success.centerXAnchor.constraint(equalTo: image.centerXAnchor).isActive = true
        success.centerYAnchor.constraint(equalTo: image.centerYAnchor).isActive = true
        
        image.addSubview(activityIndicator)
        activityIndicator.centerXAnchor.constraint(equalTo: image.centerXAnchor).isActive = true
        activityIndicator.centerYAnchor.constraint(equalTo: image.centerYAnchor).isActive = true
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.previewLayer.frame = self.view.bounds
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        //session Start
        self.videoDataOutput.setSampleBufferDelegate(self, queue:DispatchQueue(label:"camera_frame_processing_queue"))
        self.captureSession.startRunning()
    }
    
    public override func viewDidDisappear(_ animated: Bool) {
      //session Stopped
      self.videoDataOutput.setSampleBufferDelegate(nil, queue: nil)
      self.captureSession.stopRunning()
    }
}

extension OCRNIKController {
    //Set the captureSession!
    private func setCameraInput() {
        guard let device = AVCaptureDevice.DiscoverySession(
        deviceTypes: [.builtInWideAngleCamera,
                    .builtInDualCamera,
                    .builtInTrueDepthCamera],
        mediaType: .video,
        position: .back).devices.first else {
        fatalError("No back camera device found.")
        }
        let cameraInput = try! AVCaptureDeviceInput(device: device)
        self.captureSession.addInput(cameraInput)
    }
    
    private func showCameraFeed() {
        self.previewLayer.videoGravity = .resizeAspectFill
        self.camera.layer.addSublayer(self.previewLayer)
        self.previewLayer.frame = self.view.frame
    }
    
    private func setCameraOutput() {
        self.videoDataOutput.videoSettings = [(kCVPixelBufferPixelFormatTypeKey as NSString) : NSNumber(value: kCVPixelFormatType_32BGRA)] as [String : Any]
        self.videoDataOutput.alwaysDiscardsLateVideoFrames = true
        self.videoDataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "camera_frame_processing_queue"))
        self.captureSession.addOutput(self.videoDataOutput)
        guard let connection = self.videoDataOutput.connection(with: AVMediaType.video),
        connection.isVideoOrientationSupported else { return }
        connection.videoOrientation = .portrait
    }
    
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let frame = CMSampleBufferGetImageBuffer(sampleBuffer) else {
           debugPrint("unable to get image from sample buffer")
           return
         }
         self.detectRectangle(in: frame)
    }
    
    private func detectRectangle(in image: CVPixelBuffer) {
        let request = VNDetectRectanglesRequest(completionHandler: { (request: VNRequest, error: Error?) in
            DispatchQueue.main.async {
                guard let results = request.results as? [VNRectangleObservation] else { return }
                    self.removeBoundingBoxLayer()
                //retrieve the first observed rectangle
                guard let rect = results.first else{return}
                //function used to draw the bounding box of the detected rectangle
                self.drawBoundingBox(rect: rect)
                
                //Handle the button action
                if self.isTapped{
                    self.isTapped = false
                    //Handle image correction and estraxtion
                    self.image.contentMode = .scaleAspectFit
                    self.image.image = self.imageExtraction(rect, from: image)
                    self.OCR(self.image.image!)
                }
            }
        })
        //Set the value for the detected rectangle
        request.minimumAspectRatio = VNAspectRatio(0.3)
        request.maximumAspectRatio = VNAspectRatio(0.9)
        request.minimumSize = Float(0.3)
        request.maximumObservations = 1
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: image, options: [:])
        try? imageRequestHandler.perform([request])
    }
    
    func drawBoundingBox(rect : VNRectangleObservation) {
        let transform = CGAffineTransform(scaleX: 1, y: -1).translatedBy(x: 0, y: -self.previewLayer.bounds.height)
        let scale = CGAffineTransform.identity.scaledBy(x: self.previewLayer.bounds.width, y:self.previewLayer.bounds.height)
        let bounds = rect.boundingBox
        .applying(scale).applying(transform)
        createLayer(in: bounds)
    }
    
    private func createLayer(in rect: CGRect) {
        bBoxLayer = CAShapeLayer()
        bBoxLayer.frame = rect
        bBoxLayer.cornerRadius = 10
        bBoxLayer.opacity = 1
        bBoxLayer.borderColor = UIColor.systemBlue.cgColor
        bBoxLayer.borderWidth = 6.0
        previewLayer.insertSublayer(bBoxLayer, at: 1)
    }
    
    func removeBoundingBoxLayer() {
        bBoxLayer.removeFromSuperlayer()
    }
    
    func imageExtraction(_ observation: VNRectangleObservation, from buffer: CVImageBuffer) -> UIImage {
        var ciImage = CIImage(cvImageBuffer: buffer)

        let topLeft = observation.topLeft.scaled(to: ciImage.extent.size)
        let topRight = observation.topRight.scaled(to: ciImage.extent.size)
        let bottomLeft = observation.bottomLeft.scaled(to: ciImage.extent.size)
        let bottomRight = observation.bottomRight.scaled(to: ciImage.extent.size)
        // pass filters to extract/rectify the image
        ciImage = ciImage.applyingFilter(
            "CIPerspectiveCorrection",
            parameters: [
                "inputTopLeft": CIVector(cgPoint: topLeft),
                "inputTopRight": CIVector(cgPoint: topRight),
                "inputBottomLeft": CIVector(cgPoint: bottomLeft),
                "inputBottomRight": CIVector(cgPoint: bottomRight),
            ]
        )
        let context = CIContext()
        let cgImage = context.createCGImage(ciImage, from: ciImage.extent)
        let output = UIImage(cgImage: cgImage!)
        //return image
        return output
    }
}

extension OCRNIKController {
    private func OCR(_ image: UIImage) {
        success.isHidden = true
        activityIndicator.startAnimating()
        guard let cgImage = image.cgImage else {
            activityIndicator.stopAnimating()
            return
        }
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        let request = VNRecognizeTextRequest { [weak self] request, error in
             guard let observations = request.results as? [VNRecognizedTextObservation],
                    error == nil else {
                 self?.activityIndicator.stopAnimating()
                 return
             }
            var dataNIK = DataNIKModel()
            dataNIK.nama = observations[safe: 5]?.topCandidates(1).first?.string
            for currentObservation in observations {
                let topCandidate = currentObservation.topCandidates(1)
                guard let recognizedText = topCandidate.first else {
                    self?.activityIndicator.stopAnimating()
                    continue
                }
                // MARK:
                // - Remove all ":" characther
                // - Remove whitespace
                let processedText = recognizedText.string
                    .replacingOccurrences(of: ":", with: " ")
                    .replacingOccurrences(of: ".", with: " ")
                    .replacingOccurrences(of: ",", with: "")
                    .trimmingCharacters(in: .whitespaces)
                
                if let validNIK = self?.filterKTP(processedText) {
                    dataNIK.nik = validNIK
                } else if let dob = self?.filterDob(processedText) {
                    dataNIK.pob = dob.0
                    dataNIK.dob = dob.1
                } else if let religion = self?.filterReligion(processedText) {
                    dataNIK.religion = religion
                } else if let validGender = self?.filterGender(processedText) {
                    dataNIK.gender = validGender
                } else if let marriedStatus = self?.filterMariedStatus(processedText) {
                    dataNIK.marriedStatus = marriedStatus
                } else if let job = self?.filterJob(processedText) {
                    dataNIK.job = job
                } else if let nation = self?.filterNation(processedText) {
                    dataNIK.nationality = nation
                }  else {
                    print(processedText)
                }
            }
            self?.activityIndicator.stopAnimating()
            self?.success.isHidden = (dataNIK.nik != nil)
            self?.dismiss(animated: true, completion: { [weak self] in
                self?.delegate?.didSuccessParseKTP(data: dataNIK)
            })
        }
        request.recognitionLanguages = ["id"]
        request.recognitionLevel = .accurate
        do {
            try handler.perform([request])
        } catch {
            activityIndicator.stopAnimating()
            print(error.localizedDescription)
        }
    }
    
    private func filterKTP(_ text: String) -> String? {
        let texts = text.components(separatedBy: " ")
        return texts.compactMap { text in
            guard text.regex(with: "^[A-Za-z0-9]{16}+$") else { return nil }
            var processedNIK = text
            for i in 0..<NIKWordDic.count {
                guard let dict = NIKWordDic[i].first else { continue }
                processedNIK = text.replacingOccurrences(of: dict.key, with: dict.value)
            }
            guard processedNIK.regex(with: "^((1[1-9])|(21)|([37][1-6])|(5[1-4])|(6[1-5])|([8-9][1-2]))[0-9]{2}[0-9]{2}(([0-6][0-9])|(7[0-1]))((0[1-9])|(1[0-2]))([0-9]{2})[0-9]{4}$") else {
                return nil
            }
            return processedNIK
        }.first
    }
    
    private func filterGender(_ text: String) -> GenderType? {
        var result: GenderType? = nil
        for status in GenderType.allCases {
            if text.contains(status.rawValue) {
                result = status
                break
            }
        }
        return result
    }
    
    private func filterMariedStatus(_ text: String) -> MarriedStatusType? {
        var result: MarriedStatusType? = nil
        for status in MarriedStatusType.allCases {
            if text.contains(status.rawValue) {
                result = status
                break
            }
        }
        return result
    }
    
    private func filterReligion(_ text: String) -> ReligionType? {
        var result: ReligionType? = nil
        for status in ReligionType.allCases {
            if text.contains(status.rawValue) {
                result = status
                break
            }
        }
        return result
    }
    
    private func filterJob(_ text: String) -> JobType? {
        var result: JobType? = nil
        for status in JobType.allCases {
            if text.contains(status.rawValue) {
                result = status
                break
            }
        }
        return result
    }
    
    private func filterNation(_ text: String) -> NationalityType? {
        var result: NationalityType? = nil
        for status in NationalityType.allCases {
            if text.contains(status.rawValue) {
                result = status
                break
            }
        }
        return result
    }
    
    private func filterDob(_ text: String) -> (String?, Date)? {
        let texts = text.components(separatedBy: " ")
        guard texts.count > 1, let dob = texts.compactMap({ text in
            return text.toDate(dateFormat: "dd-MM-yyyy")
        }).first else { return nil }
        return (texts[safe: texts.count-2]?.replacingOccurrences(of: ",", with: ""), dob)
    }
}
