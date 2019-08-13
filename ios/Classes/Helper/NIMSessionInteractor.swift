//
//  NIMSessionInteractor.swift
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

class NIMSessionInteractor: NSObject {
    var session: NIMSession
    var flutterEventSink: FlutterEventSink?
    
    var nickName = ""
    var avatarUrl = ""
    
    var allMessages: [NIMMessage] = []
    
    // 录音时间
    var recordTime: TimeInterval = 0
    
    init(session: NIMSession, flutterEventSink: FlutterEventSink? = nil) {
        
        self.session = session
        self.flutterEventSink = flutterEventSink
        
        super.init()
        
        addListener()
        
        NIMSDK.shared().mediaManager.add(self)
        
        // 进入会话时，标记当前会话消息已读
        markRead()
        
        // 如果本地没有用户资料，去服务端同步一下
        getUserInfo();
    }
    
    private func getUserInfo () {
        // 获取云信用户信息
        if let userInfo = NIMSDK.shared().userManager.userInfo(session.sessionId)?.userInfo {
            self.nickName = userInfo.nickName ?? ""
            self.avatarUrl = userInfo.avatarUrl ?? ""
        } else {
            NIMSDK.shared().userManager.fetchUserInfos([session.sessionId]) { [weak self] (users, error) in
                guard let `self` = self else {
                    return
                }
                
                if let users = users, users.count > 0 {
                    self.nickName = users[0].userInfo?.nickName ?? ""
                    self.avatarUrl = users[0].userInfo?.avatarUrl ?? ""
                }
            }
        }
    }
    
    private func markRead() {
        NIMSDK.shared().conversationManager.markAllMessagesRead(in: session)
    }
    
    private func sendMessage(message: NIMMessage) {
        NIMSDK.shared().chatManager.send(message, to: session, completion: nil)
    }
    
    private func resendMessage(message: NIMMessage) {
        try? NIMSDK.shared().chatManager.resend(message)
    }
    
    private func refreshDataSource() {
        // 主动给 flutter 发消息
        if let eventSink = self.flutterEventSink {
            eventSink(NIMSessionParser.handleMessages(messages: self.allMessages))
        }
    }
    
    private func addListener() {
        NIMSDK.shared().chatManager.add(self)
    }
    
    private func removeListener() {
        NIMSDK.shared().chatManager.remove(self)
    }
    
    deinit {
        removeListener()
        
        NIMSDK.shared().mediaManager.remove(self)
    }
}

// MARK: - public

extension NIMSessionInteractor {
    
    func loadMessages(messageIndex: Int) {
        
        var message: NIMMessage?
        if messageIndex >= 0 {
            message = self.allMessages[messageIndex]
        }
        
        if let messages = NIMSDK.shared().conversationManager.messages(in: session, message: message, limit: 20) {
            self.allMessages.insert(contentsOf: messages, at: 0)
            refreshDataSource()
        }
    }
    
    func sendTextMessage(text: String) {
        let message = NIMMessage()
        message.text = text
        
        sendMessage(message: message)
    }
    
    func sendImageMessage(path: String) {
        let message = NIMMessage()
        let imageObject = NIMImageObject(filepath: path)
        message.messageObject = imageObject
        
        sendMessage(message: message)
    }
    
    func sendAudioMessage(filePath: String) {
        let message = NIMMessage()
        let audioObject = NIMAudioObject(sourcePath: filePath, scene: NIMNOSSceneTypeMessage)
        message.messageObject = audioObject
        sendMessage(message: message)
    }
    
    func sendVideoMessage(filePath: String) {
        let message = NIMMessage()
        let audioObject = NIMVideoObject(sourcePath: filePath, scene: NIMNOSSceneTypeMessage)
        message.messageObject = audioObject
        sendMessage(message: message)
    }
    
    func sendCustomMessage(customEncodeString: String, apnsContent: String) {
        let attachment = IMCustomAttachment()
        attachment.customEncodeString = customEncodeString;
        
        let message  = NIMMessage()
        let customObject = NIMCustomObject()
        customObject.attachment = attachment
        message.messageObject = customObject
        message.apnsContent = apnsContent
    
        sendMessage(message: message)
    }
    
    // 会话外发送自定义消息
    static func sendCustomMessageTo(sessionID: String, customEncodeString: String, apnsContent: String, result: @escaping FlutterResult) {
        let attachment = IMCustomAttachment()
        attachment.customEncodeString = customEncodeString;
        
        let message  = NIMMessage()
        let customObject = NIMCustomObject()
        customObject.attachment = attachment
        message.messageObject = customObject
        message.apnsContent = apnsContent
        
        NIMSDK.shared().chatManager.send(message, to: NIMSession(sessionID, type: NIMSessionType.P2P)) { (error) in
            if (error == nil) {
                result(true)
            } else {
                result(false)
            }
        }
    }
    
    /// 重发消息
    func resendMessage(messageId: String) {
        if let index = self.allMessages.map({ $0.messageId }).firstIndex(of: messageId) {
            let message = self.allMessages[index]
            resendMessage(message: message)
        }
    }
    
    /// 开始录音
    func onStartRecording() {
        let type = NIMAudioType.AAC
        // let duration = NIMKit.shared()!.config.recordMaxDuration
        let duration = 60.0
        
        NIMSDK.shared().mediaManager.record(type, duration: duration)
    }
    
    /// 结束录音
    func onStopRecording() {
        NIMSDK.shared().mediaManager.stopRecord()
    }
    
    /// 取消录音
    func onCancelRecording() {
        NIMSDK.shared().mediaManager.cancelRecord()
    }

    // 标记语音已读
    func markAudioMessageRead(messageId: String) {
        if let index = self.allMessages.map({ $0.messageId }).firstIndex(of: messageId) {
            let message = self.allMessages[index]
            message.isPlayed = true
        }
    }
}

// MARK: - NIMChatManagerDelegate

extension NIMSessionInteractor: NIMChatManagerDelegate {
    
    func willSend(_ message: NIMMessage) {
        if message.session == self.session {
            // 用来判断是否是发送失败重发
            var hasThisMessage = false
            for (index, msg) in allMessages.enumerated() {
                if msg.messageId == message.messageId {
                    allMessages[index] = message
                    hasThisMessage = true
                    break
                }
            }
            
            if !hasThisMessage {
                allMessages.append(message)
            }
            
            refreshDataSource()
        }
    }
    
    func send(_ message: NIMMessage, didCompleteWithError error: Error?) {
        if (error == nil) {
            if message.session == self.session {
                for (index, msg) in allMessages.enumerated() {
                    if msg.messageId == message.messageId {
                        allMessages[index] = message
                        break
                    }
                }
                refreshDataSource()
            }
        } else {
            print("FlutterNIM：消息发送失败")
        }
    }
    
    func onRecvMessages(_ messages: [NIMMessage]) {
        if let newMessage = messages.first {
            allMessages.append(newMessage)
            refreshDataSource()
            
            // 收到新消息时，标记已读
            markRead()
        }
    }
}

// MARK: - NIMMediaManagerDelegate

extension NIMSessionInteractor: NIMMediaManagerDelegate {
    // 开始录制音频的回调
    func recordAudio(_ filePath: String?, didBeganWithError error: Error?) {
        self.recordTime = 0
    }
    
    // 录制音频完成后的回调
    func recordAudio(_ filePath: String?, didCompletedWithError error: Error?) {
        if (error == nil && filePath != nil) {
            if (self.recordTime > 1) {
                sendAudioMessage(filePath: filePath!)
            } else {
                print("FlutterNIM：说话时间太短")
            }
        }
    }
    
    // 录音被取消的回调
    func recordAudioDidCancelled() {
        self.recordTime = 0
    }
    
    func recordAudioProgress(_ currentTime: TimeInterval) {
        self.recordTime = currentTime
    }
    
    func recordAudioInterruptionBegin() {
        NIMSDK.shared().mediaManager.cancelRecord()
    }
}
