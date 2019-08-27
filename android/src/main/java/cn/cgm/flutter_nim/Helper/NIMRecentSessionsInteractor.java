package cn.cgm.flutter_nim.Helper;

import android.text.TextUtils;

import com.netease.nimlib.sdk.NIMClient;
import com.netease.nimlib.sdk.Observer;
import com.netease.nimlib.sdk.RequestCallback;
import com.netease.nimlib.sdk.RequestCallbackWrapper;
import com.netease.nimlib.sdk.msg.MsgService;
import com.netease.nimlib.sdk.msg.MsgServiceObserve;
import com.netease.nimlib.sdk.msg.constant.SessionTypeEnum;
import com.netease.nimlib.sdk.msg.model.RecentContact;
import com.netease.nimlib.sdk.uinfo.UserService;
import com.netease.nimlib.sdk.uinfo.model.NimUserInfo;

import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.List;

import io.flutter.plugin.common.EventChannel.EventSink;

public class NIMRecentSessionsInteractor {
    private EventSink eventSink;

    private List<RecentContact> recentSessions = new ArrayList<>();
    private List<String> recentSessionUserIds;

    public NIMRecentSessionsInteractor(EventSink eventSink) {

        this.eventSink = eventSink;

        registerObservers(true);
    }


    private void registerObservers(boolean register) {
        MsgServiceObserve service = NIMClient.getService(MsgServiceObserve.class);

        service.observeRecentContact(recentContactsObserver, register);
        service.observeRecentContactDeleted(recentContactDeletedObserver, register);
    }

    /**
     * 最近联系人列表变化观察者
     */
    private Observer<List<RecentContact>> recentContactsObserver = new Observer<List<RecentContact>>() {
        @Override
        public void onEvent(List<RecentContact> recentContacts) {
            if (recentContacts == null || recentContacts.isEmpty()) {
                return;
            }

            onRecentContactChanged(recentContacts);
        }
    };


    private void onRecentContactChanged(List<RecentContact> recentContacts) {
        if (recentSessions == null) {
            recentSessions = new ArrayList<>();
        }

        if (recentSessionUserIds == null) {
            recentSessionUserIds = new ArrayList<>();
        } else {
            recentSessionUserIds.clear();
        }

        // 记录用户信息是否有本地缓存
        boolean hasNullUser = false;

        int index;
        for (RecentContact r : recentContacts) {
            index = -1;
            for (int i = 0; i < recentSessions.size(); i++) {
                if (r.getContactId().equals(recentSessions.get(i).getContactId())
                        && r.getSessionType() == (recentSessions.get(i).getSessionType())) {
                    index = i;
                    break;
                }
            }

            if (index >= 0) {
                recentSessions.remove(index);
            }

            recentSessions.add(r);

            // 获取本地用户资料
            NimUserInfo userInfo = NIMClient.getService(UserService.class).getUserInfo(r.getContactId());

            if (userInfo == null) {
                recentSessionUserIds.add(r.getContactId());
                hasNullUser = true;
            }
        }

        // 本地无这些用户资料，从云端拉取一下
        if (hasNullUser) {
            NIMClient.getService(UserService.class).fetchUserInfo(recentSessionUserIds).setCallback(new RequestCallback<List<NimUserInfo>>() {
                @Override
                public void onSuccess(List<NimUserInfo> param) {
                    refreshMessages();
                }

                @Override
                public void onFailed(int code) {
                    refreshMessages();
                }

                @Override
                public void onException(Throwable exception) {

                }
            });
        } else {
            refreshMessages();
        }
    }

    private Observer<RecentContact> recentContactDeletedObserver = new Observer<RecentContact>() {
        @Override
        public void onEvent(RecentContact recentContact) {
            if (recentContact != null) {
                for (RecentContact item : recentSessions) {
                    if (TextUtils.equals(item.getContactId(), recentContact.getContactId())
                            && item.getSessionType() == recentContact.getSessionType()) {
                        recentSessions.remove(item);
                        refreshMessages();
                        break;
                    }
                }
            } else {
                recentSessions.clear();
                refreshMessages();
            }
        }
    };


    private void refreshMessages() {
        sortRecentContacts(recentSessions);

        // 主动给 flutter 发消息
        if (eventSink != null) {
            eventSink.success(NIMSessionParser.handleRecentSessionsData(recentSessions));
        }

    }

    /// 手动获取最近会话列表
    public void loadRecentSessions() {
        NIMClient.getService(MsgService.class).queryRecentContacts()
                .setCallback(new RequestCallbackWrapper<List<RecentContact>>() {
                    @Override
                    public void onResult(int code, List<RecentContact> recents, Throwable e) {
                        recentSessions = recents;

                        if (recentSessions == null || recentSessions.isEmpty()) {
                            return;
                        }

                        if (recentSessionUserIds == null) {
                            recentSessionUserIds = new ArrayList<>();
                        } else {
                            recentSessionUserIds.clear();
                        }

                        for (RecentContact r : recentSessions) {
                            recentSessionUserIds.add(r.getContactId());
                        }

                        // 手动获取最近会话不是频繁操作，可以在云端拉取一次用户信息
                        NIMClient.getService(UserService.class).fetchUserInfo(recentSessionUserIds).setCallback(new RequestCallback<List<NimUserInfo>>() {
                            @Override
                            public void onSuccess(List<NimUserInfo> param) {
                                refreshMessages();
                            }

                            @Override
                            public void onFailed(int code) {
                                refreshMessages();
                            }

                            @Override
                            public void onException(Throwable exception) {

                            }
                        });

                    }
                });
    }


    private int getItemIndex(String uuid) {
        for (int i = 0; i < recentSessions.size(); i++) {
            RecentContact item = recentSessions.get(i);
            if (TextUtils.equals(item.getRecentMessageId(), uuid)) {
                return i;
            }
        }

        return -1;
    }

    public void deleteRecentContact2(String account) {
        NIMClient.getService(MsgService.class).deleteRecentContact2(account, SessionTypeEnum.P2P);
    }

    /**
     * **************************** 排序 ***********************************
     */

    // 置顶功能可直接使用，也可作为思路，供开发者充分利用RecentContact的tag字段
    // 联系人置顶tag
    private final long RECENT_TAG_STICKY = 0x0000000000000001;

    private void sortRecentContacts(List<RecentContact> list) {
        if (list == null || list.isEmpty()) {
            return;
        }

        Collections.sort(list, comp);
    }

    private Comparator<RecentContact> comp = new Comparator<RecentContact>() {

        @Override
        public int compare(RecentContact o1, RecentContact o2) {
            // 先比较置顶tag
            long sticky = (o1.getTag() & RECENT_TAG_STICKY) - (o2.getTag() & RECENT_TAG_STICKY);
            if (sticky != 0) {
                return sticky > 0 ? -1 : 1;
            } else {
                long time = o1.getTime() - o2.getTime();
                return time == 0 ? 0 : (time > 0 ? -1 : 1);
            }
        }
    };

}
