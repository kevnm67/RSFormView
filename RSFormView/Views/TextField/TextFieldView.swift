//
//  TextFieldView.swift
//  Avinew
//
//  Created by Germán Stábile on 1/29/19.
//  Copyright © 2019 TopTier labs. All rights reserved.
//

import Foundation
import UIKit

protocol TextFieldDelegate: class {
  func didUpdate(textFieldView: TextFieldView,
                 text: String)
}

class TextFieldView: UIView {
  @IBOutlet weak var textField: UITextField!
  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var errorLabel: UILabel!
  @IBOutlet weak var bottomLine: UIView!
  
  static let dateFormat = "MM/dd/yyyy"
  
  var lastCursorPosition: Int?
  
  weak var delegate: TextFieldDelegate?
  var fieldData: FormField? {
    didSet {
      configureFormPicker()
      setKeyboardType()
    }
  }
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    configureViews()
  }
  
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    configureViews()
  }
  
  func configureViews() {
    _ = addNibView(inBundle: Constants.formViewBundle)
    
    textField.delegate = self
    textField.font = UIFont.systemFont(ofSize: 15)
    textField.textColor = UIColor.lightGray
    
    titleLabel.font = UIFont.systemFont(ofSize: 12)
    titleLabel.textColor = UIColor.darkGray
    
    errorLabel.font = UIFont.systemFont(ofSize: 13)
    errorLabel.textColor = UIColor.red
    
    let tapGesture = UITapGestureRecognizer(target: self,
                                            action: #selector(tappedView))
    addGestureRecognizer(tapGesture)
    updateErrorState()
  }
  
  func saveCursorPosition() {
    if let selectedRange = textField.selectedTextRange {
      lastCursorPosition = textField.offset(from: textField.beginningOfDocument,
                                            to: selectedRange.start)
    }
  }
  
  func setCursorPosition(isDeleting: Bool = false) {
    guard let lastCursorPosition = lastCursorPosition,
      fieldData?.validationType != .phone,
      fieldData?.validationType != .expiration,
      textField.selectedTextRange != nil else {
        self.lastCursorPosition = nil
        return
    }
    
    if let newPosition = textField.position(from: textField.beginningOfDocument,
                                            offset: lastCursorPosition + (isDeleting ? -1 : 1)) {
      textField.selectedTextRange = textField.textRange(from: newPosition, to: newPosition)
    }
    
    self.lastCursorPosition = nil
  }
  
  func updateErrorState() {
    guard let fieldData = fieldData else { return }
    textField.isEnabled = fieldData.isEnabled
    errorLabel.isHidden = !fieldData.shouldDisplayError || fieldData.isValid
    
    let isValid = !fieldData.shouldDisplayError || fieldData.isValid
    
    bottomLine.backgroundColor = isValid ?
      bottomLineValidColor() : UIColor.red
    titleLabel.textColor = isValid ?
      titleValidColor() : UIColor.red
    
    errorLabel.text = fieldData.oneTimeErrorMessage ?? fieldData.errorMessage
  }
  
  func titleValidColor() -> UIColor {
    return textField.isFirstResponder ?
      UIColor.blue : UIColor.darkGray
  }
  
  func bottomLineValidColor() -> UIColor {
    return textField.isFirstResponder ?
      UIColor.blue : UIColor.lightGray
  }
  
  fileprivate func setKeyboardType() {
    guard let fieldData = fieldData else { return }
    switch fieldData.validationType {
    case .numeric, .phone, .zip, .expiration:
      textField.keyboardType = .numberPad
    case .email:
      textField.keyboardType = .emailAddress
    default:
      textField.keyboardType = .default
    }
  }
  
  func configureFormPicker() {
    guard let fieldData = fieldData,
      fieldData.validationType == .date else {
        textField.inputView = nil
        return
    }
    
    let datePicker = UIDatePicker()
    
    if fieldData.value != "" {
      let dateFormatter = DateFormatter()
      dateFormatter.dateFormat = TextFieldView.dateFormat
      if let date = dateFormatter.date(from: fieldData.value) {
        datePicker.date = date
      }
    }
    datePicker.datePickerMode = .date
    datePicker.minimumDate = fieldData.minimunDate
    datePicker.maximumDate = fieldData.maximumDate
    datePicker.addTarget(self,
                         action: #selector(datePickerChangedValue),
                         for: .valueChanged)
    textField.inputView = datePicker
  }
  
  func update(withData data: FormField) {
    fieldData = data
    updatePlaceHolder(withText: data.placeholder)
    textField.isSecureTextEntry = data.isPasswordField
    textField.text = data.value
    titleLabel.text = data.name
    errorLabel.text = data.errorMessage
    titleLabel.isHidden = data.value.isEmpty
    if !data.value.isEmpty && data.oneTimeErrorMessage == nil {
      data.shouldDisplayError = true
      data.isValid = data.value.isValid(type: data.validationType)
    }
    updateErrorState()
  }
  
  func updatePlaceHolder(withText text: String) {
    let font = UIFont.systemFont(ofSize: 14)
    textField.attributedPlaceholder =
      NSAttributedString(string: text,
                         attributes: [
                          .foregroundColor: UIColor.darkGray,
                          .font: font
        ])
  }
  
  @objc func tappedView() {
    textField.becomeFirstResponder()
  }
  
  func propagateUpdates(previousText: String, updatedText: String, data: FormField) {
    var updatedText = updatedText
    updatedText = data.capitalizeValue ? updatedText.capitalized : updatedText
    updatedText = data.uppercaseValue ? updatedText.uppercased() : updatedText
    if data.validationType == .usState {
      updatedText = updatedText.count > 2 ? updatedText.capitalized : updatedText.uppercased()
    }
    let isDeleting = updatedText.count < previousText.count
    data.oneTimeErrorMessage = nil
    saveCursorPosition()
    delegate?.didUpdate(textFieldView: self, text: updatedText)
    setCursorPosition(isDeleting: isDeleting)
  }
  
  func expirationDate(previousText: String, updatedText: String) -> String {
    if updatedText.count < previousText.count {
      //if deleting we don't need to do any manipulation
      return updatedText
    }
    
    if previousText.isEmpty {
      //if first character is bigger than 1 put cero at the begginning
      //since its typing a month
      if Int(updatedText) == 1 {
        return updatedText
      }
      
      if Int(updatedText) ?? 0 > 1 {
        return "0\(updatedText)/"
      }
    }
    
    if previousText.count == 1 {
      if Int(updatedText) ?? 0 > 12 {
        return previousText
      } else {
        return "\(updatedText)/"
      }
    }
    
    return updatedText
  }
}

//Date picker related methods
extension TextFieldView {
  @objc func datePickerChangedValue(sender: UIDatePicker) {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = TextFieldView.dateFormat
    
    let dateString = dateFormatter.string(from: sender.date)
    textField.text = dateString
    delegate?.didUpdate(textFieldView: self, text: dateString)
  }
}

extension TextFieldView: UITextFieldDelegate {
  func textField(_ textField: UITextField,
                 shouldChangeCharactersIn range: NSRange,
                 replacementString string: String) -> Bool {
    guard let data = fieldData,
      data.validationType != .date else {
        return false
    }
    
    if let text = textField.text,
      let textRange = Range(range, in: text) {
      var updatedText = text.replacingCharacters(in: textRange,
                                                 with: string)
      
      if data.validationType == .phone &&
        textField.text?.count ?? 0 < updatedText.count &&
        [3, 7].contains(updatedText.count) {
        updatedText += "-"
      }
      
      if data.validationType == .expiration {
        updatedText = expirationDate(previousText: text, updatedText: updatedText)
      }
      
      propagateUpdates(previousText: text, updatedText: updatedText, data: data)
    }
    
    return false
  }
  
  func textFieldShouldClear(_ textField: UITextField) -> Bool {
    delegate?.didUpdate(textFieldView: self, text: "")
    return true
  }
  
  func textFieldDidBeginEditing(_ textField: UITextField) {
    titleLabel.textColor = UIColor.blue
    bottomLine.backgroundColor = UIColor.blue
    textField.placeholder = ""
    titleLabel.isHidden = false
  }
  
  func textFieldDidEndEditing(_ textField: UITextField) {
    titleLabel.isHidden = fieldData?.value ?? "" == ""
    updatePlaceHolder(withText: fieldData?.placeholder ?? "")
    updateErrorState()
  }
}