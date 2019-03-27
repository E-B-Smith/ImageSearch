/**
 @file          BNCLog.swift
 @package       Branch-SDK
 @brief         Swift bridge to the Branch logging functions.

 @author        Edward Smith
 @date          October 2016
 @copyright     Copyright © 2016 Branch. All rights reserved.
*/

import Foundation

/*!
* @param level      The log level for the message.
* @param message    The message to log.
* @param file       The source code file name for the log message. Defaults to the current file.
* @param line       The source code line number of the log message. Defaults to the current line number.
*/
func BNCLog(level: BNCLogLevel, message: String?, file: String = #file, line: Int = #line) {
    BNCLogWriteMessage(level, file, Int32(line), message ?? "")
}
