//
//  NIMSessionUtil.swift
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

import Foundation
import NIMSDK

// 最近会话本地扩展标记类型
enum NIMRecentSessionMarkType: String {
    // @ 标记
    case markTypeAt
    // 置顶标记
    case markTypeTop
}

struct NIMSessionUtil {
    
    /// 判断消息是否可以转发
    static func canMessageBeForwarded(_ message: NIMMessage) -> Bool {
        if message.isReceivedMsg || message.deliveryState == NIMMessageDeliveryState.failed {
            return false
        }

        if let messageObject = message.messageObject {

            if let object = messageObject as? NIMCustomObject, let attachment = object.attachment as? IMCustomAttachment {
                return attachment.canBeForwarded()
            }

            if messageObject is NIMNotificationObject {
                return false
            }

            if messageObject is NIMTipObject {
                return false
            }

            if messageObject is NIMRobotObject {
                return false
            }
        }

        return true
    }
    
    /// 判断消息是否可以撤回
    static func canMessageBeRevoked(_ message: NIMMessage) -> Bool {
        let canRevokeMessageByRole = self.canRevokeMessageByRole(message)
        let isDeliverFailed = !message.isReceivedMsg && message.deliveryState == NIMMessageDeliveryState.failed
        
        if !canRevokeMessageByRole || isDeliverFailed {
            return false
        }
        
        if let messageObject = message.messageObject {
            
            if let object = messageObject as? NIMCustomObject, let attachment = object.attachment as? IMCustomAttachment {
                return attachment.canBeRevoked()
            }
            
            if messageObject is NIMNotificationObject {
                return false
            }
            
            if messageObject is NIMTipObject {
                return false
            }
            
            if messageObject is NIMRobotObject {
                return false
            }
        }
        
        return true
    }

    /// 判断撤回规则
    static func canRevokeMessageByRole(_ message: NIMMessage) -> Bool {
        let isFromMe = message.from! == NIMSDK.shared().loginManager.currentAccount()
        let isToMe = message.session!.sessionId == NIMSDK.shared().loginManager.currentAccount()
        let isTeamManager = false
        let isRobotMessage = false
        
        // 我发出去的消息并且不是发给我的电脑的消息并且不是机器人的消息，可以撤回
        // 群消息里如果我是管理员可以撤回以上所有消息(暂未判断)
        return (isFromMe && !isToMe && !isRobotMessage) || isTeamManager
    }
    
    static func tipOnMessageRevoked(_ notification: NIMRevokeMessageNotification?) -> String {
        var tip = ""
        
        if let notification = notification {
            let session = notification.session
            if session.sessionType == NIMSessionType.team {
                // TODO: 群组撤回
            } else {
                tip = tipTitleFromMessageRevokeNotificationP2P(notification)
            }
        } else {
            tip = "你"
        }
        
        return "\(tip)撤回了一条消息"
    }
    
    static func tipTitleFromMessageRevokeNotificationP2P(_ notification: NIMRevokeMessageNotification) -> String {
        let fromUid = notification.messageFromUserId
        if fromUid == NIMSDK.shared().loginManager.currentAccount() {
            return "你"
        } else {
            return "对方"
        }
    }
    
    // 添加标记
    static func addRecentSessionMark(_ session: NIMSession, type: NIMRecentSessionMarkType) {
        guard let recent = NIMSDK.shared().conversationManager.recentSession(by: session) else {
            return
        }
        
        var localExt = recent.localExt ?? [:]
        localExt[type.rawValue] = true
        NIMSDK.shared().conversationManager.updateRecentLocalExt(localExt, recentSession: recent)
    }
    
    // 移除标记
    static func removeRecentSessionMark(_ session: NIMSession, type: NIMRecentSessionMarkType) {
        guard let recent = NIMSDK.shared().conversationManager.recentSession(by: session) else {
            return
        }
        
        var localExt = recent.localExt
        localExt?.removeValue(forKey: type.rawValue)
        NIMSDK.shared().conversationManager.updateRecentLocalExt(localExt, recentSession: recent)
    }
    // 判断是否标记过某种类型
    static func isRecentSessionMark(_ session: NIMRecentSession, type: NIMRecentSessionMarkType) -> Bool {
        let localExt = session.localExt
        if let value = localExt?[type.rawValue] as? Bool {
            return value
        } else {
            return false
        }
    }
    
}
