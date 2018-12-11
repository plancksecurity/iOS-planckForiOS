//
//  ASLPriorityLevel.swift
//  CleanroomASL
//
//  Created by Evan Maloney on 3/17/15.
//  Copyright © 2015 Gilt Groupe. All rights reserved.
//

/**
The `ASLPriorityLevel` enum represents the documented `ASL_LEVEL_*` constant
values.
*/
public enum ASLPriorityLevel: Int32 // EnumerableEnum
{
    /// Represents the `ASL_LEVEL_EMERG` constant.
    case emergency  = 0

    /// Represents the `ASL_LEVEL_ALERT` constant.
    case alert      = 1

    /// Represents the `ASL_LEVEL_CRIT` constant.
    case critical   = 2

    /// Represents the `ASL_LEVEL_ERR` constant.
    case error      = 3

    /// Represents the `ASL_LEVEL_WARNING` constant.
    case warning    = 4

    /// Represents the `ASL_LEVEL_NOTICE` constant.
    case notice     = 5

    /// Represents the `ASL_LEVEL_INFO` constant.
    case info       = 6

    /// Represents the `ASL_LEVEL_DEBUG` constant.
    case debug      = 7

    /// Returns the `ASL_STRING_*` equivalent of the receiver.
    public var priorityString: String {
        get {
            switch self {
            case .emergency: return "Emergency"  // ASL_STRING_EMERG
            case .alert:     return "Alert"      // ASL_STRING_ALERT
            case .critical:  return "Critical"   // ASL_STRING_CRIT
            case .error:     return "Error"      // ASL_STRING_ERR
            case .warning:   return "Warning"    // ASL_STRING_WARNING
            case .notice:    return "Notice"     // ASL_STRING_NOTICE
            case .info:      return "Info"       // ASL_STRING_INFO
            case .debug:     return "Debug"      // ASL_STRING_DEBUG
            }
        }
    }

    /** Returns a filter mask for the receiver. This mask can be used to
    specify *only* those messages with the same priority as the receiver. */
    public var filterMask: Int32 {
        return 1 << self.rawValue
    }

    /** Returns a filter mask representing all priority levels up to and 
    including the receiver. This mask can be used to specify *all* messages
    whose priority is the same as or more severe than the receiver. */
    public var filterMaskUpTo: Int32 {
        return (1 << (self.rawValue + 1)) - 1
    }

    /**
    Returns all possible values of the `ASLPriorityLevel` enum.
    */
    public static func allValues()
        -> [ASLPriorityLevel]
    {
        return [
            .emergency,
            .alert,
            .critical,
            .error,
            .warning,
            .notice,
            .info,
            .debug
        ]
    }
}
