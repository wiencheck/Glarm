//
//  RadiusInputController.swift
//  Glarm
//
//  Created by Adam Wienconek on 18/07/2021.
//  Copyright © 2021 Adam Wienconek. All rights reserved.
//

import UIKit
import CoreLocation

protocol RadiusInputControllerDelegate: AnyObject {
    var radius: CLLocationDistance { get set }
    func radiusInputDidCommitRadius()
}

final class RadiusInputController: UIViewController {
    
    weak var delegate: RadiusInputControllerDelegate?
    
    private var lastValidRadius: CLLocationDistance = 0
    
    private lazy var numberFormatter: NumberFormatter = {
        let n = NumberFormatter()
        n.maximumFractionDigits = 1
        return n
    }()
        
    private lazy var textField: UITextField = {
        let t = UITextField()
        t.keyboardType = .numbersAndPunctuation
        t.text = delegate?.radius.readableRepresentation(addingSymbol: false)
        t.delegate = self
        return t
    }()
    
    private lazy var doneButton: UIButton = {
        let b = UIButton(type: .system)
        b.text = "Done"
        b.pressHandler = { [weak self] _ in
            self?.delegate?.radiusInputDidCommitRadius()
        }
        return b
    }()
    
    private lazy var unitButton: UIButton = {
        let b = BorderedButton()
        b.text = currentUnit.symbol
        b.menu = unitMenu
        b.showsMenuAsPrimaryAction = true
        return b
    }()
    
    private var observer: NSObjectProtocol!
    
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(observer!)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        observer = NotificationCenter.default.addObserver(forName: UITextField.textDidChangeNotification, object: textField, queue: nil) { [weak self] notification in
            let textField = notification.object as! UITextField
            self?.handleTextChanged(inTextField: textField)
        }
        
        setupView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        unitButton.text = currentUnit.symbol
        textField.text = delegate?.radius.readableRepresentation(addingSymbol: false)
        textField.becomeFirstResponder()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        textField.resignFirstResponder()
    }
    
    private func handleTextChanged(inTextField textField: UITextField) {
        lastValidRadius = delegate?.radius ?? 0
        guard let input = textField.text,
              let validRadius = translateInputToRadius(input, unit: currentUnit) else {
            return
        }
        delegate?.radius = validRadius
    }
}

extension RadiusInputController: UnitMenuSelectable, RadiusInputHandling {
    func handleUnitChanged(from oldUnit: UnitLength, to unit: UnitLength) {
        unitButton.menu = nil
        unitButton.menu = unitMenu
        unitButton.text = unit.symbol
        
        guard let input = textField.text,
              let validRadius = translateInputToRadius(input, unit: unit) else {
            return
        }
        delegate?.radius = validRadius
    }
}

extension RadiusInputController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let decimalPlaces = 1

        guard let oldText = textField.text,
              let r = Range(range, in: oldText) else {
            return true
        }

        let newText = oldText.replacingCharacters(in: r, with: string)
        let isNumeric = newText.isEmpty || (Double(newText) != nil)

//        guard let separator = newText.first(where: { char in
//            char.unicodeScalars.allSatisfy(CharacterSet.punctuationCharacters.contains(_:))
//        }) else {
//            return false
//        }
        let separator = "."

        let numberOfDots = newText.components(separatedBy: String(separator)).count - 1

        let numberOfDecimalDigits: Int
        if let dotIndex = newText.firstIndex(of: ".") {
            numberOfDecimalDigits = newText.distance(from: dotIndex, to: newText.endIndex) - 1
        } else {
            numberOfDecimalDigits = 0
        }

        let shouldReplace = isNumeric &&
            numberOfDots <= 1 &&
            numberOfDecimalDigits <= decimalPlaces
        return shouldReplace
    }
}

private extension RadiusInputController {
    func setupView() {
        let stack = UIStackView(arrangedSubviews: [textField, doneButton])
        stack.axis = .horizontal
        
        view.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.top.leading.equalTo(16)
            make.center.equalTo(view.safeAreaLayoutGuide)
        }
        
        view.addSubview(unitButton)
        unitButton.snp.makeConstraints { make in
            make.centerY.equalTo(stack)
            make.trailing.equalTo(textField).offset(-16)
        }
    }
}
