//
//  ViewController.swift
//  KTPOCR
//
//  Created by M. Alfiansyah Nur Cahya Putra on 30/10/22.
//

import UIKit
import OCRKTP

class ViewController: UIViewController {

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
        print(data)
    }
}

