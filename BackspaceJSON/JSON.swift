import Foundation

public enum JSON {
  case dictionary([String: JSON])
  case array([JSON])
  case string(String)
  case number(NSNumber)
  case bool(Bool)
  case null
  case none

  fileprivate static let boolNumberType = type(of: NSNumber(value: true))

  public init(data: Data, options: JSONSerialization.ReadingOptions = .allowFragments) throws {
    self = try JSON(JSONSerialization.jsonObject(with: data, options: options))
  }

  public subscript(index: Int) -> JSON {
    guard case .array(let array) = self, index >= 0, index < array.count else {
      return .none
    }

    return array[index]
  }

  public subscript(key: String) -> JSON {
    guard case .dictionary(let dict) = self, let value = dict[key] else {
      return .none
    }

    return value
  }

  public var dictionary: [String: JSON]? {
    guard case let .dictionary(value) = self else {
      return nil
    }

    return value
  }

  public var array: [JSON]? {
    guard case let .array(value) = self else {
      return nil
    }

    return value
  }

  public var string: String? {
    guard case let .string(value) = self else {
      return nil
    }

    return value
  }

  public var number: NSNumber? {
    guard case let .number(value) = self else {
      return nil
    }

    return value
  }

  public var double: Double? {
    return number?.doubleValue
  }

  public var int: Int? {
    return number?.intValue
  }

  public var bool: Bool? {
    guard case let .bool(value) = self else {
      return nil
    }

    return value
  }

  public var exists: Bool {
    if case .none = self {
      return false
    }

    return true
  }

  public var existsNull: Bool {
    if case .null = self {
      return true
    }

    return false
  }

  public var existsNotNull: Bool {
    return self.exists && !self.existsNull
  }

  public func data(options: JSONSerialization.WritingOptions = []) -> Data {
    guard let object = self.object else {
      return Data()
    }

    return (try? JSONSerialization.data(withJSONObject: object, options: options)) ?? Data()
  }

  fileprivate init(_ object: Any) {
    switch object {
      case let dictionary as [String: Any]:
        self = .dictionary(dictionary.mapValues() { JSON($0) })
      case let array as [Any]:
        self = .array(array.map() { JSON($0) })
      case let string as String:
        self = .string(string)
      case let number as NSNumber:
        self = (type(of: number) == Self.boolNumberType) ? .bool(number != 0) : .number(number)
      case let bool as Bool:
        self = .bool(bool)
      case _ as NSNull:
        self = .null
      default:
        self = .none
    }
  }

  fileprivate var object: Any? {
    switch self {
      case .dictionary(let value): return value.mapValues() { $0.object }
      case .array(let value): return value.map() { $0.object }
      case .string(let value): return value
      case .number(let value): return value

      case .bool(let value): return value
      case .null: return NSNull()
      case .none: return nil
    }
  }
}

extension JSON: CustomDebugStringConvertible {
  public var debugDescription: String {
    guard let object = self.object else {
      return ""
    }

    return String(describing: object as AnyObject).replacingOccurrences(of: ";\n", with: "\n")
  }
}
