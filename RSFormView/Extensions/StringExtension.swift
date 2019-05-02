//
//  StringExtension.swift
//  RSFormView
//
//  Created by Germán Stábile on 4/30/19.
//  Copyright © 2019 Rootstrap. All rights reserved.
//

import Foundation

extension String {
  func isValid(type: ValidationType) -> Bool {
    switch type {
    case .email:
      return isEmailFormatted()
    case .numeric:
      return isInteger()
    case .usState:
      return AddressManager.validateState(state: self)
    case .phone:
      return isPhoneNumber()
    case .zip:
      return isZipCode()
    case .expiration:
      return isExpirationDate()
    case .none:
      return true
    default:
      return !isEmpty
    }
  }
  
  //Regex fulfill RFC 5322 Internet Message format
  func isEmailFormatted() -> Bool {
    let predicate = NSPredicate(format: "SELF MATCHES %@", "[A-Za-z0-9!#$%&'*+/=?^_`{|}~-]+(\\.[A-Za-z0-9!#$%&'*+/=?^_`{|}~-]+)*@([A-Za-z0-9]([A-Za-z0-9-]*[A-Za-z0-9])?\\.)+[A-Za-z0-9]([A-Za-z0-9-]*[A-Za-z0-9])?")
    return predicate.evaluate(with: self)
  }
  
  func isInteger() -> Bool {
    return Int(self) != nil
  }
  
  func isPhoneNumber() -> Bool {
    let phoneTest = NSPredicate(format: "SELF MATCHES %@", "^\\d{3}-\\d{3}-\\d{4}$")
    return phoneTest.evaluate(with: self)
  }
  
  func isZipCode() -> Bool {
    return isInteger() && count == 5
  }
  
  func isExpirationDate() -> Bool {
    guard count == 7 else { return false }
    guard let month = Int(prefix(2)),
      month <= 12 else { return false }
    guard let year = Int(suffix(4)),
      year >= Calendar.current.component(.year, from: Date()) else { return false }
    guard self[index(startIndex, offsetBy: 2)] == "/" else { return false }
    
    return true
  }
}
