//
//  NIMSessionParser.swift
//  flutter_nim
//
//  Created by GuiminChu on 2019/7/19.
//
//  Copyright (c) 2019 GuiminChu
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

import NIMSDK

struct NIMSessionParser {
    // 处理最近会话数据
    static func handleRecentSessionsData(recentSessions: [NIMRecentSession]) -> String {
        var result = ""
        
        var sessionDictArray = [[String: Any]]()
        for recentSession in recentSessions {
            var sessionDict = [String: Any]()
            sessionDict["sessionId"] = recentSession.session!.sessionId
            sessionDict["unreadCount"] = recentSession.unreadCount
            sessionDict["timestamp"] = recentSession.timestamp

            if let lastMessage = recentSession.lastMessage {
                let lastMessageDict = getMessageDict(message: lastMessage)
                sessionDict["messageContent"] = messageContent(lastMessage: lastMessage)
                sessionDict["lastMessage"] = lastMessageDict
            }
            
            var userInfoDict = [String: Any]()
            userInfoDict["nickname"] = recentSession.userInfo.nickName
            userInfoDict["avatarUrl"] = recentSession.userInfo.avatarUrl
            userInfoDict["userExt"] = recentSession.userInfo.ext
            sessionDict["userInfo"] = userInfoDict
            
            sessionDictArray.append(sessionDict)
        }
        
        let dict: [String: Any] = ["recentSessions": sessionDictArray]
        
        if let data = try? JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted),
            let jsonString = String(data: data, encoding: String.Encoding.utf8) {
            result = jsonString
        }
        
        return result
    }
    
    // 处理会话消息数据
    static func handleMessages(messages: [NIMMessage]) -> String {
        var result = ""
        
        var messageDictArray = [[String: Any]]()
        for message in messages {
            let messageDict = getMessageDict(message: message)
            messageDictArray.append(messageDict)
        }
        
        let dict: [String: Any] = ["messages": messageDictArray]
        
        if let data = try? JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted),
            let jsonString = String(data: data, encoding: String.Encoding.utf8) {
            result = jsonString
        }
        
        return result
    }
    
    // 可用的消息字典
    private static func getMessageDict(message: NIMMessage) -> [String: Any] {
        var messageDict = [String: Any]()
        
        messageDict["messageId"] = message.messageId
        messageDict["from"] = message.from
        messageDict["text"] = message.text
        messageDict["isOutgoingMsg"] = message.isOutgoingMsg
        messageDict["messageType"] = message.messageType.rawValue
        messageDict["deliveryState"] = message.deliveryState.rawValue
        messageDict["timestamp"] = Int(message.timestamp * 1000)
        
        if message.messageType == NIMMessageType.image {
            if let imageObject = message.messageObject as? NIMImageObject {
                var messageObjectDict = [String: Any]()
                messageObjectDict["url"] = imageObject.url
                messageObjectDict["thumbUrl"] = imageObject.thumbUrl
                messageObjectDict["thumbPath"] = imageObject.thumbPath
                messageObjectDict["path"] = imageObject.path
                messageObjectDict["width"] = Int(imageObject.size.width)
                messageObjectDict["height"] = Int(imageObject.size.height)
                
                messageDict["messageObject"] = messageObjectDict
            }
        } else if message.messageType == NIMMessageType.audio {
            if let audioObject = message.messageObject as? NIMAudioObject {
                var messageObjectDict = [String: Any]()
                messageObjectDict["url"] = audioObject.url
                messageObjectDict["path"] = audioObject.path
                messageObjectDict["duration"] = audioObject.duration
                messageObjectDict["isPlayed"] = message.isPlayed
                
                messageDict["messageObject"] = messageObjectDict
            }
        } else if message.messageType == NIMMessageType.video {
            if let videoObject = message.messageObject as? NIMVideoObject {
                var messageObjectDict = [String: Any]()
                messageObjectDict["url"] = videoObject.url
                messageObjectDict["coverUrl"] = videoObject.coverUrl
                messageObjectDict["path"] = videoObject.path
                messageObjectDict["duration"] = videoObject.duration
                messageObjectDict["width"] = Int(videoObject.coverSize.width)
                messageObjectDict["height"] = Int(videoObject.coverSize.height)
                
                messageDict["messageObject"] = messageObjectDict
            }
        } else if message.messageType == NIMMessageType.custom {
            if let customObject = message.messageObject as? NIMCustomObject, let attachment = customObject.attachment {
                messageDict["customMessageContent"] = attachment.encode()
            }
        }
        
        return messageDict
    }
}

// MARK: - Help Methods

extension NIMSessionParser {
    // 最近会话列表中显示的消息文本
    private static func messageContent(lastMessage: NIMMessage?) -> String {
        guard let lastMessage = lastMessage else {
            return ""
        }
        
        var text = ""
        switch lastMessage.messageType {
        case .text:
            text = lastMessage.text ?? ""
        case .image:
            text = "[图片]"
        case .audio:
            text = "[语音]"
        case .video:
            text = "[视频]"
        case .location:
            text = "[位置]"
        case .file:
            text = "[文件]"
        case .tip:
            text = lastMessage.text ?? ""
        case .notification:
            // FIXME: 省略
            text = ""
        case .robot:
            // FIXME: 省略
            text = ""
        case .custom:
            text = "[自定义消息]"
        default:
            text = ""
        }
        
        return text
    }
    
    // 最近会话排序
    static func sortRecentSessions(recentSessions: inout [NIMRecentSession]) {
        recentSessions.sort { (item1, item2) -> Bool in
            // 先判断是否有置顶标记
            var score1 = NIMSessionUtil.isRecentSessionMark(item1, type: NIMRecentSessionMarkType.markTypeTop) ? 10 : 0
            var score2 = NIMSessionUtil.isRecentSessionMark(item2, type: NIMRecentSessionMarkType.markTypeTop) ? 10 : 0

            if let message1 = item1.lastMessage, let message2 = item2.lastMessage {
                if message1.timestamp > message2.timestamp {
                    score1 += 1;
                } else {
                    score2 += 1;
                }
            }

            if score1 > score2 {
                return true
            } else {
                return false
            }
        }
    }
    
    // 计算新会话插入的位置
    static func findInsertPlace(_ recentSession: NIMRecentSession, in recentSessions: [NIMRecentSession]) -> Int {
        var matchIndex: Int = 0
        var find = false

        for (index, item) in recentSessions.enumerated() {
            if let itemLastMessage = item.lastMessage, let lastMessage = recentSession.lastMessage {
                if itemLastMessage.timestamp <= lastMessage.timestamp {
                    find = true
                    matchIndex = index
                    break
                }
            }
        }

        if find {
            return matchIndex
        } else {
            return recentSessions.count
        }
    }
}

extension NIMRecentSession {
    /// 元组：用户名、头像链接、用户额外信息
    var userInfo: (nickName: String, avatarUrl: String, ext: String) {
        guard let _session = self.session else {
            return ("", "", "")
        }
        
        if _session.sessionType == NIMSessionType.P2P {
            if let _userInfo = NIMSDK.shared().userManager.userInfo(_session.sessionId)?.userInfo {
                return (_userInfo.nickName ?? "", _userInfo.avatarUrl ?? "", _userInfo.ext ?? "")
            }
        } else {
            if let _team = NIMSDK.shared().teamManager.team(byId: _session.sessionId) {
                return (_team.teamName ?? "", _team.avatarUrl ?? "", "")
            }
        }
        
        return ("", "", "")
    }
    
    /// 最后一条消息时间戳，单位 ms
    var timestamp: Int {
        guard let _lastMessage = self.lastMessage else {
            return 0
        }
        
        return Int(_lastMessage.timestamp * 1000)
    }
}
