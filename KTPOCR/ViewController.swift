//
//  ViewController.swift
//  KTPOCR
//
//  Created by M. Alfiansyah Nur Cahya Putra on 30/10/22.
//

import UIKit
import OCRKTP

class ViewController: UIViewController {
    @IBOutlet weak var nikLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var pobLabel: UILabel!
    @IBOutlet weak var nationalityLabel: UILabel!
    @IBOutlet weak var marriedStatusLabel: UILabel!
    @IBOutlet weak var religionLabel: UILabel!
    @IBOutlet weak var genderLabel: UILabel!
    @IBOutlet weak var dobLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let viewController = OCRNIKController()
        viewController.delegate = self
        present(viewController, animated: true)
    }
}

extension ViewController: OCRNIKControllerDelegate {
    func didSuccessParseKTP(data: DataNIKModel) {
        nikLabel.text = data.nik
        nameLabel.text = data.nama
        pobLabel.text = data.pob
//        dobLabel.text = data.dob
        genderLabel.text = data.gender?.rawValue
        religionLabel.text = data.religion?.rawValue
        marriedStatusLabel.text = data.marriedStatus?.rawValue
        nationalityLabel.text = data.nationality?.rawValue
    }
}

