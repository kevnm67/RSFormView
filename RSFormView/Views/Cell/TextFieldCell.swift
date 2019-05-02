//
//  FormViewCell.swift
//  Avinew
//
//  Created by Germán Stábile on 1/25/19.
//  Copyright © 2019 TopTier labs. All rights reserved.
//

import Foundation
import UIKit

protocol FormCellDelegate: class {
  func didUpdate(data: FormField)
}

protocol FormViewCell: class {
  func updateErrorState()
}

class TextFieldCell: UITableViewCell, FormViewCell {
  
  static let reuseIdentifier = "TextFieldCellIdentifier"
  
  @IBOutlet weak var textFieldView: TextFieldView!
  
  weak var delegate: FormCellDelegate?
  var fieldData: FormField?
  
  override func awakeFromNib() {
    textFieldView.delegate = self
  }
  
  func update(withData data: FormField) {
    fieldData = data
    textFieldView.update(withData: data)
  }
  
  func updateErrorState() {
    textFieldView.updateErrorState()
  }
  
  func focus() {
    textFieldView.textField.becomeFirstResponder()
  }
}

extension TextFieldCell: TextFieldDelegate {
  func didUpdate(textFieldView: TextFieldView, text: String) {
    fieldData?.value = text
    fieldData?.shouldDisplayError = true
    if let fieldData = fieldData {
      fieldData.isValid = fieldData.value.isValid(type: fieldData.validationType)
      update(withData: fieldData)
      delegate?.didUpdate(data: fieldData)
    }
  }
}