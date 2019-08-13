//
//  SwiftFlutterNIMPlugin.swift
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

import Flutter
import UIKit
import NIMSDK

enum FlutterChannel: String {
    static let methodChannelName = "flutter_nim_method"
    static let eventChannelName = "flutter_nim_event"
    
    case imInit
    case imLogin
    case imAutoLoginH
    case imLogout
    case imRecentSessions
    case imDeleteRecentSession
    case imStartChat
    case imExitChat
    case imMessages
    case imSendText
    case imSendImage
    case imSendVideo
    case imSendAudio
    case imSendCustom
    case imSendCustomToSession
    case imResendMessage
    case imMarkAudioMessageRead
    case onStartRecording
    case onStopRecording
    case onCancelRecording
}

public class SwiftFlutterNIMPlugin: NSObject, FlutterPlugin {
    var eventSink: FlutterEventSink?
    var sessionInteractor: NIMSessionInteractor?
    
    var recentSessions: [NIMRecentSession] = []
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let methodChannel = FlutterMethodChannel(name: FlutterChannel.methodChannelName, binaryMessenger: registrar.messenger())
        let instance = SwiftFlutterNIMPlugin()
        registrar.addMethodCallDelegate(instance, channel: methodChannel)
        
        let eventChannel = FlutterEventChannel.init(name: FlutterChannel.eventChannelName, binaryMessenger: registrar.messenger())
        eventChannel.setStreamHandler(instance)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        // 获取 flutter 给到的参数
        // print(call.arguments)
        // print(call.method)
        
        switch call.method {
        case FlutterChannel.imInit.rawValue:
            imInit(arguments: call.arguments)
        case FlutterChannel.imLogin.rawValue:
            imLogin(arguments: call.arguments, result: result)
        case FlutterChannel.imLogout.rawValue:
            imLogout()
        case FlutterChannel.imRecentSessions.rawValue:
            imRecentSessions()
        case FlutterChannel.imDeleteRecentSession.rawValue:
            imDeleteRecentSessions(arguments: call.arguments)
        case FlutterChannel.imStartChat.rawValue:
            startChat(arguments: call.arguments, result: result)
        case FlutterChannel.imExitChat.rawValue:
            exitChat()
        case FlutterChannel.imMessages.rawValue:
            imMessages(arguments: call.arguments)
        case FlutterChannel.imSendText.rawValue:
            imSendText(arguments: call.arguments)
        case FlutterChannel.imSendImage.rawValue:
            imSendImage(arguments: call.arguments)
        case FlutterChannel.imSendVideo.rawValue:
            imSendVideo(arguments: call.arguments)
        case FlutterChannel.imSendAudio.rawValue:
            imSendAudio(arguments: call.arguments)
        case FlutterChannel.imSendCustom.rawValue:
            imSendCustom(arguments: call.arguments)
        case FlutterChannel.imSendCustomToSession.rawValue:
            imSendCustomToSession(arguments: call.arguments, result: result)
        case FlutterChannel.imResendMessage.rawValue:
            imResendMessage(arguments: call.arguments)
        case FlutterChannel.imMarkAudioMessageRead.rawValue:
            imMarkAudioMessageRead(arguments: call.arguments)
        case FlutterChannel.onStartRecording.rawValue:
            sessionInteractor?.onStartRecording()
        case FlutterChannel.onStopRecording.rawValue:
            sessionInteractor?.onStopRecording()
        case FlutterChannel.onCancelRecording.rawValue:
            sessionInteractor?.onCancelRecording()
        default:
            break
        }
    }
    
    private func imInit(arguments: Any?) {
        guard let arguments = arguments as? [String: String], let appKey = arguments["appKey"]  else {
            return
        }
        
        // 配置额外配置信息（需要在注册 appKey 前完成）
        // 是否需要多端同步未读数
        NIMSDKConfig.shared().shouldSyncUnreadCount = true
        // 自动登录重试次数
        NIMSDKConfig.shared().maxAutoLoginRetryTimes = 10
        //多端登录时，告知其他端，这个端的登录类型。
        NIMSDKConfig.shared().customTag = "\(NIMLoginClientType.typeiOS.rawValue)"
        NIMSDKConfig.shared().animatedImageThumbnailEnabled = true
        
        // appKey
        let options = NIMSDKOption(appKey: appKey)
        // 云信推送证书名称
        let apnsCername = arguments["apnsCername"]
        let apnsCernameDevelop = arguments["apnsCernameDevelop"]
        options.apnsCername = apnsCername
        #if DEBUG
        options.apnsCername = apnsCernameDevelop
        #else
        options.apnsCername = apnsCername
        #endif
        NIMSDK.shared().register(with: options)
        
        // 注册自定义消息解析器
        NIMCustomObject.registerCustomDecoder(IMCustomMessageAttachmentDecoder())
 
//        NIMSDK.shared().loginManager.add(self)
//        NIMSDK.shared().systemNotificationManager.add(self)
        NIMSDK.shared().conversationManager.add(self)
        
        if let account = arguments["imAccount"], let token = arguments["imToken"] {
            autoLogin(account: account, token: token)
        }
    }
    
    // 登录
    private func imLogin(arguments: Any?, result: @escaping FlutterResult) {
        if let arguments = arguments as? [String: String] {
            let account = arguments["imAccount"]!
            let token = arguments["imToken"]!
            NIMSDK.shared().loginManager.login(account, token: token) { (error) in
                if error == nil {
                    result(true)
                } else {
                    result(false)
                }
            }
        } else {
            result(false)
        }
    }
    
    // 自动登录
    private func autoLogin(account: String, token: String) {
        if account.isEmpty || token.isEmpty {
            return
        }
        
        let loginData = NIMAutoLoginData()
        loginData.account = account
        loginData.token = token
        loginData.forcedMode = true
        
        NIMSDK.shared().loginManager.autoLogin(loginData)
    }
    
    /// 退出登录
    private func imLogout() {
        NIMSDK.shared().loginManager.logout { (error) in
        }
    }
    
    /// 最近会话列表
    /// 注：获取最近会话只查询客户端本地信息。服务端接口无法获取最近会话。
    private func imRecentSessions() {
        if let recentSessions = NIMSDK.shared().conversationManager.allRecentSessions() {
            self.recentSessions = recentSessions

            // 手动获取最近会话不是频繁操作，可以在云端拉取一次用户信息
            let userIds = recentSessions.map({ $0.session!.sessionId})
            NIMSDK.shared().userManager.fetchUserInfos(userIds) { [weak self] (users, error) in
                guard let `self` = self else {
                    return
                }
                
                self.sendRecentSessionsEvent()
            }
        }
    }
    
    /// 删除某项最近会话
    private func imDeleteRecentSessions(arguments: Any?) {
        if let arguments = arguments as? [String: String], let sessionId = arguments["sessionId"] {
            self.recentSessions.forEach { (recentSession) in
                if (recentSession.session?.sessionId == sessionId) {
                    NIMSDK.shared().conversationManager.delete(recentSession)
                }
            }
        }
    }
    
    /// 开始会话
    private func startChat(arguments: Any?, result: @escaping FlutterResult) {
        if let arguments = arguments as? [String: String], let sessionId = arguments["sessionId"] {
            let session = NIMSession(sessionId, type: NIMSessionType.P2P)
            let sessionInteractor =  NIMSessionInteractor(session: session, flutterEventSink: eventSink)
            self.sessionInteractor = sessionInteractor
            result(true)
        } else {
            result(false)
        }
    }
    
    /// 结束会话
    private func exitChat() {
        self.sessionInteractor = nil
    }
    
    /// 会话消息
    private func imMessages(arguments: Any?) {
        guard let arguments = arguments as? [String: Int], let messageIndex = arguments["messageIndex"] else {
            return
        }
        
        sessionInteractor?.loadMessages(messageIndex: messageIndex)
    }
    
    /// 发送文本消息
    private func imSendText(arguments: Any?) {
        guard let arguments = arguments as? [String: String], let text = arguments["text"] else {
            return
        }
        
        sessionInteractor?.sendTextMessage(text: text)
    }
    
    /// 发送图片消息
    private func imSendImage(arguments: Any?) {
        guard let arguments = arguments as? [String: String], let imagePath = arguments["imagePath"] else {
            return
        }
        
        sessionInteractor?.sendImageMessage(path: imagePath)
    }
    
    /// 发送视频消息
    private func imSendVideo(arguments: Any?) {
        guard let arguments = arguments as? [String: String], let videoPath = arguments["videoPath"] else {
            return
        }
        
        sessionInteractor?.sendVideoMessage(filePath: videoPath)
    }
    
    /// 发送音频消息
    private func imSendAudio(arguments: Any?) {
        guard let arguments = arguments as? [String: String], let audioPath = arguments["audioPath"] else {
            return
        }
        
        sessionInteractor?.sendAudioMessage(filePath: audioPath)
    }
    
    /// 发送自定义消息
    private func imSendCustom(arguments: Any?) {
        guard let arguments = arguments as? [String: String], let customEncodeString = arguments["customEncodeString"], let apnsContent = arguments["apnsContent"] else {
            return
        }
        
        sessionInteractor?.sendCustomMessage(customEncodeString: customEncodeString, apnsContent: apnsContent)
    }
    
    /// 会话外发送自定义消息
    private func imSendCustomToSession(arguments: Any?, result: @escaping FlutterResult) {
        guard let arguments = arguments as? [String: String],
            let sessionId = arguments["sessionId"],
            let customEncodeString = arguments["customEncodeString"],
            let apnsContent = arguments["apnsContent"] else {
            return
        }
        
        NIMSessionInteractor.sendCustomMessageTo(sessionID: sessionId, customEncodeString: customEncodeString, apnsContent: apnsContent, result: result)
    }
    
    /// 重新发送失败的消息
    private func imResendMessage(arguments: Any?) {
        guard let arguments = arguments as? [String: String], let messageId = arguments["messageId"] else {
            return
        }
        
        sessionInteractor?.resendMessage(messageId: messageId)
    }
    
    /// 标记音频已读
    private func imMarkAudioMessageRead(arguments: Any?) {
        guard let arguments = arguments as? [String: String], let messageId = arguments["messageId"] else {
            return
        }
        
        sessionInteractor?.markAudioMessageRead(messageId: messageId)
    }
}

extension SwiftFlutterNIMPlugin {
    private func sendRecentSessionsEvent() {
        if let eventSink = self.eventSink {
            eventSink(NIMSessionParser.handleRecentSessionsData(recentSessions: self.recentSessions))
        }
    }
}

extension SwiftFlutterNIMPlugin: FlutterStreamHandler {
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        eventSink = events
        return nil
    }
    
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        eventSink = nil
        return nil
    }
}

// MARK: - NIMConversationManagerDelegate 会话管理器回调

extension SwiftFlutterNIMPlugin: NIMConversationManagerDelegate {
    
    // 当新增一条消息，并且本地不存在该消息所属的会话时，会触发此回调。
    // 初次打开应用时，如果之前云端有最近会话记录，会出发此回调。
    public func didAdd(_ recentSession: NIMRecentSession, totalUnreadCount: Int) {
        self.recentSessions.append(recentSession)
        NIMSessionParser.sortRecentSessions(recentSessions: &recentSessions)
        
        if let userInfo = NIMSDK.shared().userManager.userInfo(recentSession.session!.sessionId)?.userInfo {
            self.sendRecentSessionsEvent()
        } else {
            // 本地无此用户资料缓存，从云端拉取一下
            let userId = recentSession.session!.sessionId

            NIMSDK.shared().userManager.fetchUserInfos([userId]) { [weak self] (users, error) in
                guard let `self` = self else {
                    return
                }
                
                self.sendRecentSessionsEvent()
            }
        }
    }
    
    // 触发条件包括:
    // 1. 当新增一条消息，并且本地存在该消息所属的会话。
    // 2. 所属会话的未读清零。
    // 3. 所属会话的最后一条消息的内容发送变化。(例如成功发送后，修正发送时间为服务器时间)
    // 4. 删除消息，并且删除的消息为当前会话的最后一条消息。
    public func didUpdate(_ recentSession: NIMRecentSession, totalUnreadCount: Int) {
        for (index, _recentSession) in recentSessions.enumerated() {
            if _recentSession.session?.sessionId == recentSession.session?.sessionId {
                self.recentSessions.remove(at: index)
                break
            }
        }

        let index =  NIMSessionParser.findInsertPlace(recentSession, in: recentSessions)
        self.recentSessions.insert(recentSession, at: index)

        sendRecentSessionsEvent()
    }
    
    // 删除最近会话的回调
    public func didRemove(_ recentSession: NIMRecentSession, totalUnreadCount: Int) {
        for (index, _recentSession) in recentSessions.enumerated() {
            if _recentSession.session?.sessionId == recentSession.session?.sessionId {
                self.recentSessions.remove(at: index)
                break
            }
        }

        sendRecentSessionsEvent()
    }
    
    // 单个会话里所有消息被删除的回调
    public func messagesDeleted(in session: NIMSession) {
        if let allRecentSessions = NIMSDK.shared().conversationManager.allRecentSessions() {
            self.recentSessions = allRecentSessions
        } else {
            self.recentSessions.removeAll()
        }

        sendRecentSessionsEvent()
    }
    
    // 所有消息被删除的回调
    public func allMessagesDeleted() {
        if let allRecentSessions = NIMSDK.shared().conversationManager.allRecentSessions() {
            self.recentSessions = allRecentSessions
        } else {
            self.recentSessions.removeAll()
        }

        sendRecentSessionsEvent()
    }
    
    // 所有消息已读的回调
    public func allMessagesRead() {
        if let allRecentSessions = NIMSDK.shared().conversationManager.allRecentSessions() {
            self.recentSessions = allRecentSessions
        } else {
            self.recentSessions.removeAll()
        }

        sendRecentSessionsEvent()
    }
}

class IMCustomAttachment: NSObject, NIMCustomAttachment {
    var customEncodeString = ""
    
    func encode() -> String {
        return customEncodeString;
    }
    
    /// 是否可被撤回
    func canBeRevoked() -> Bool {
        return false;
    }
    
    /// 是否可转发
    func canBeForwarded() -> Bool {
        return false;
    }
}

class IMCustomMessageAttachmentDecoder: NSObject, NIMCustomAttachmentCoding {
    func decodeAttachment(_ content: String?) -> NIMCustomAttachment? {
        if let value = content, let data = value.data(using: .utf8) {
            let attachment = IMCustomAttachment()
            attachment.customEncodeString = value
            return attachment
        }
        return nil
    }
}
