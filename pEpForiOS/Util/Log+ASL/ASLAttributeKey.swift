//
//  ASLAttributeKey.swift
//  CleanroomASL
//
//  Created by Evan Maloney on 3/17/15.
//  Copyright © 2015 Gilt Groupe. All rights reserved.
//

/**
The `ASLAttributeKey` enum represents the documented `ASL_KEY_*` constant
values.

These values can be used to set or retrieve attributes on `ASLObject`
instances.
*/
public enum ASLAttributeKey: String
{
    /// Represents the `ASL_KEY_TIME` constant.
    case time                   = "Time"

    /// Represents the `ASL_KEY_TIME_NSEC` constant.
    case timeNanoSec            = "TimeNanoSec"

    /// Represents the `ASL_KEY_HOST` constant.
    case host                   = "Host"

    /// Represents the `ASL_KEY_SENDER` constant.
    case sender                 = "Sender"

    /// Represents the `ASL_KEY_FACILITY` constant.
    case facility               = "Facility"

    /// Represents the `ASL_KEY_PID` constant.
    case pid                    = "PID"

    /// Represents the `ASL_KEY_UID` constant.
    case uid                    = "UID"

    /// Represents the `ASL_KEY_GID` constant.
    case gid                    = "GID"

    /// Represents the `ASL_KEY_LEVEL` constant.
    case level                  = "Level"

    /// Represents the `ASL_KEY_MSG` constant.
    case message                = "Message"

    /// Represents the `ASL_KEY_READ_UID` constant.
    case readUID                = "ReadUID"

    /// Represents the `ASL_KEY_READ_GID` constant.
    case readGID                = "ReadGID"

    /// Represents the `ASL_KEY_EXPIRE_TIME` constant.
    case aslExpireTime          = "ASLExpireTime"

    /// Represents the `ASL_KEY_MSG_ID` constant.
    case aslMessageID           = "ASLMessageID"

    /// Represents the `ASL_KEY_SESSION` constant.
    case session                = "Session"

    /// Represents the `ASL_KEY_REF_PID` constant.
    case refPID                 = "RefPID"

    /// Represents the `ASL_KEY_REF_PROC` constant.
    case refProc                = "RefProc"

    /// Represents the `ASL_KEY_AUX_TITLE` constant.
    case aslAuxTitle            = "ASLAuxTitle"

    /// Represents the `ASL_KEY_AUX_UTI` constant.
    case aslAuxUTI              = "ASLAuxUTI"

    /// Represents the `ASL_KEY_AUX_URL` constant.
    case aslAuxURL              = "ASLAuxURL"

    /// Represents the `ASL_KEY_AUX_DATA` constant.
    case aslAuxData             = "ASLAuxData"

    /// Represents the `ASL_KEY_OPTION` constant.
    case aslOption              = "ASLOption"

    /// Represents the `ASL_KEY_MODULE` constant.
    case aslModule              = "ASLModule"

    /// Represents the `ASL_KEY_SENDER_INSTANCE` constant.
    case senderInstance         = "SenderInstance"

    /// Represents the `ASL_KEY_SENDER_MACH_UUID` constant.
    case senderMachUUID         = "SenderMachUUID"

    /// Represents the `ASL_KEY_FINAL_NOTIFICATION` constant.
    case aslFinalNotification   = "ASLFinalNotification"

    /// Represents the `ASL_KEY_OS_ACTIVITY_ID` constant.
    case osActivityID           = "OSActivityID"
}
