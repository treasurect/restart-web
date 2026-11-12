<script setup>
import { computed, nextTick, onBeforeUnmount, onMounted, ref, watch } from "vue";
import {
  deleteConversation,
  getConversationList,
  getMessageList,
  streamChat,
  updateConversationTitle,
  uploadAIImages
} from "@/api/ai";
import { BASE_URL } from "@/api/request";

defineOptions({
  name: "AiChatPage"
});

const CURRENT_CONVERSATION_KEY = "ai_current_conversation_id";

const messages = ref([]);
const conversations = ref([]);
const currentConversationId = ref(null);

const loading = ref(false);
const thinking = ref(false);
const loadingConversations = ref(false);
const loadingMessages = ref(false);
const conversationError = ref("");
const messageError = ref("");

const inputText = ref("");
const attachments = ref([]);
const fileInputRef = ref(null);
const messageListRef = ref(null);

const canSend = computed(() => {
  return !loading.value && (inputText.value.trim().length > 0 || attachments.value.length > 0);
});

let activeAbortController = null;
let isFirstToken = true;
let curAssistantId = null;

function formatTime(value) {
  if (!value) {
    return "";
  }

  let date;
  if (Array.isArray(value)) {
    const [year, month, day, hour, minute, second] = value;
    date = new Date(year, month - 1, day, hour ?? 0, minute ?? 0, second ?? 0);
  } else {
    date = new Date(value);
  }

  if (Number.isNaN(date.getTime())) {
    return String(value);
  }

  return date.toLocaleString("zh-CN", {
    month: "2-digit",
    day: "2-digit",
    hour: "2-digit",
    minute: "2-digit"
  });
}

function sortMessages(list) {
  return [...list].sort((a, b) => {
    const aTime = new Date(a.createdAt || 0).getTime();
    const bTime = new Date(b.createdAt || 0).getTime();
    return (aTime || 0) - (bTime || 0) || (a.id ?? 0) - (b.id ?? 0);
  });
}

function resolveFileUrl(url) {
  if (!url) {
    return "";
  }

  if (/^(https?:)?\/\//.test(url) || url.startsWith("data:") || url.startsWith("blob:")) {
    return url;
  }

  return `${BASE_URL.replace(/\/$/, "")}/${url.replace(/^\//, "")}`;
}

function parseMessageImageUrls(item) {
  if (!item?.extra) {
    return [];
  }

  try {
    const extra = typeof item.extra === "string" ? JSON.parse(item.extra) : item.extra;
    return Array.isArray(extra?.imageUrls) ? extra.imageUrls : [];
  } catch {
    return [];
  }
}

async function scrollToBottom() {
  await nextTick();
  if (messageListRef.value) {
    messageListRef.value.scrollTop = messageListRef.value.scrollHeight;
  }
}

function persistConversationId() {
  if (currentConversationId.value == null) {
    localStorage.removeItem(CURRENT_CONVERSATION_KEY);
  } else {
    localStorage.setItem(CURRENT_CONVERSATION_KEY, String(currentConversationId.value));
  }
}

function findMessageIndex(messageId) {
  if (messageId == null) {
    return -1;
  }

  return messages.value.findIndex((item) => item.id === messageId);
}

function setAssistantContent(messageId, content) {
  const index = findMessageIndex(messageId);
  if (index >= 0) {
    messages.value[index].content = content;
  }
}

function getAssistantMessage(messageId) {
  const index = findMessageIndex(messageId);
  return index >= 0 ? messages.value[index] : null;
}

function stopGenerate() {
  if (activeAbortController) {
    activeAbortController.abort();
    activeAbortController = null;
  }

  if (curAssistantId != null) {
    const message = getAssistantMessage(curAssistantId);
    if (message) {
      if (message.content === "AI 正在思考中...") {
        message.content = "已停止生成";
      }
      message.streaming = false;
    }
  }

  thinking.value = false;
  loading.value = false;
  curAssistantId = null;
}

async function loadConversations() {
  loadingConversations.value = true;
  conversationError.value = "";

  try {
    const result = await getConversationList();

    if (result.code === 200) {
      conversations.value = result.data || [];
    } else {
      conversationError.value = result.msg || "获取会话列表失败";
    }
  } catch (error) {
    conversationError.value = error.message || "获取会话列表失败";
  } finally {
    loadingConversations.value = false;
  }
}

async function loadMessagesByCid(conversationId) {
  if (!conversationId) {
    currentConversationId.value = null;
    messages.value = [];
    persistConversationId();
    return;
  }

  currentConversationId.value = conversationId;
  persistConversationId();
  loadingMessages.value = true;
  messageError.value = "";

  try {
    const result = await getMessageList(conversationId);

    if (result.code === 200) {
      messages.value = sortMessages(result.data || []).map((item) => ({
        ...item,
        isUser: item.role === "user",
        imageUrls: parseMessageImageUrls(item)
      }));
      await scrollToBottom();
    } else {
      messageError.value = result.msg || "获取消息列表失败";
    }
  } catch (error) {
    messageError.value = error.message || "获取消息列表失败";
  } finally {
    loadingMessages.value = false;
  }
}

async function selectConversation(conversationId) {
  if (thinking.value) {
    stopGenerate();
  }

  if (currentConversationId.value === conversationId && !loadingMessages.value) {
    return;
  }

  await loadMessagesByCid(conversationId);
}

function newConversation() {
  if (loading.value) {
    return;
  }

  currentConversationId.value = null;
  messages.value = [];
  inputText.value = "";
  messageError.value = "";
  attachments.value.forEach((item) => URL.revokeObjectURL(item.previewUrl));
  attachments.value = [];
  persistConversationId();
}

async function renameConversation(conversation) {
  const title = window.prompt("修改会话标题", conversation.title || "");
  if (title == null) {
    return;
  }

  const nextTitle = title.trim();
  if (!nextTitle) {
    return;
  }

  try {
    const result = await updateConversationTitle(conversation.id, nextTitle);

    if (result.code === 200) {
      await loadConversations();
    } else {
      window.alert(result.msg || "修改失败");
    }
  } catch (error) {
    window.alert(error.message || "修改失败");
  }
}

async function removeConversation(conversation) {
  if (!window.confirm(`确定删除会话「${conversation.title || "未命名会话"}」吗？`)) {
    return;
  }

  try {
    const result = await deleteConversation(conversation.id);

    if (result.code === 200) {
      if (currentConversationId.value === conversation.id) {
        currentConversationId.value = null;
        messages.value = [];
        persistConversationId();
      }

      await loadConversations();
    } else {
      window.alert(result.msg || "删除失败");
    }
  } catch (error) {
    window.alert(error.message || "删除失败");
  }
}

function handleStreamEvent(event) {
  const eventName = event.event || event.type;

  if (event.conversationId != null) {
    currentConversationId.value = event.conversationId;
    persistConversationId();
  }

  if (eventName === "start") {
    return;
  }

  if (eventName === "token") {
    if (isFirstToken) {
      isFirstToken = false;
      if (curAssistantId != null) {
        setAssistantContent(curAssistantId, "");
      }
    }

    if (event.content) {
      const message = getAssistantMessage(curAssistantId);
      if (message) {
        message.content += event.content;
        scrollToBottom();
      }
    }
    return;
  }

  if (eventName === "complete") {
    if (curAssistantId != null) {
      const message = getAssistantMessage(curAssistantId);
      if (message) {
        message.streaming = false;
        if (event.messageId != null) {
          message.id = event.messageId;
        }
      }
    }
    return;
  }

  if (eventName === "error") {
    const content = event.content?.trim() || "AI 回复失败";
    if (curAssistantId == null || !getAssistantMessage(curAssistantId)) {
      messages.value.push({
        id: -Date.now(),
        role: "assistant",
        content,
        isUser: false,
        createdAt: new Date().toISOString()
      });
    } else {
      setAssistantContent(curAssistantId, content);
    }
  }
}

async function startStream(message, imageUrls, signal) {
  isFirstToken = true;
  const assistantId = -Date.now() - 1;
  curAssistantId = assistantId;

  messages.value.push({
    id: assistantId,
    role: "assistant",
    content: "AI 正在思考中...",
    isUser: false,
    streaming: true,
    createdAt: new Date().toISOString()
  });
  await scrollToBottom();

  try {
    await streamChat({
      conversationId: currentConversationId.value,
      message,
      imageUrls,
      signal,
      onEvent: handleStreamEvent
    });
  } catch (error) {
    if (error.name !== "AbortError") {
      setAssistantContent(assistantId, `请求失败：${error.message || "未知错误"}`);
    }
  } finally {
    const message = getAssistantMessage(curAssistantId);
    if (message) {
      message.streaming = false;
    }
    curAssistantId = null;
    await loadConversations();
    await scrollToBottom();
  }
}

async function sendCurrentMessage() {
  const content = inputText.value.trim();
  const hasAttachments = attachments.value.length > 0;
  if ((!content && !hasAttachments) || loading.value) {
    return;
  }

  const imageFiles = attachments.value.map((item) => item.file);
  inputText.value = "";
  attachments.value.forEach((item) => URL.revokeObjectURL(item.previewUrl));
  attachments.value = [];

  loading.value = true;
  thinking.value = true;
  activeAbortController = new AbortController();

  try {
    const imageUrls = imageFiles.length
      ? (await uploadAIImages(imageFiles, activeAbortController.signal)).map(resolveFileUrl)
      : [];

    const userMessage = {
      id: -Date.now(),
      role: "user",
      content,
      imageUrls,
      conversationId: currentConversationId.value || 0,
      isUser: true,
      createdAt: new Date().toISOString()
    };
    messages.value.push(userMessage);
    await scrollToBottom();
    await startStream(content, imageUrls, activeAbortController.signal);
  } catch (error) {
    if (error.name !== "AbortError") {
      messages.value.push({
        id: -Date.now(),
        role: "assistant",
        content: `请求失败：${error.message || "未知错误"}`,
        isUser: false,
        createdAt: new Date().toISOString()
      });
    }
  } finally {
    loading.value = false;
    thinking.value = false;
    activeAbortController = null;
    await scrollToBottom();
  }
}

function sendSuggestion(text) {
  if (!text || loading.value) {
    return;
  }

  inputText.value = text;
  sendCurrentMessage();
}

function handleFileChange(event) {
  const files = Array.from(event.target.files || []);
  for (const file of files) {
    if (!file.type.startsWith("image/")) {
      continue;
    }

    attachments.value.push({
      id: `${Date.now()}-${Math.random()}`,
      file,
      previewUrl: URL.createObjectURL(file)
    });
  }

  event.target.value = "";
}

function removeAttachment(index) {
  const item = attachments.value[index];
  if (item) {
    URL.revokeObjectURL(item.previewUrl);
  }
  attachments.value.splice(index, 1);
}

watch(currentConversationId, () => {
  persistConversationId();
});

onMounted(async () => {
  const savedConversationId = Number(localStorage.getItem(CURRENT_CONVERSATION_KEY) || 0);

  if (savedConversationId) {
    await loadConversations();
    await loadMessagesByCid(savedConversationId);
  } else {
    await loadConversations();
  }
});

onBeforeUnmount(() => {
  if (activeAbortController) {
    activeAbortController.abort();
  }
  attachments.value.forEach((item) => URL.revokeObjectURL(item.previewUrl));
});
</script>

<template>
  <div class="ai-chat-page">
    <aside class="conversation-panel">
      <div class="panel-header">
        <span>会话</span>
        <button class="new-button" type="button" @click="newConversation">
          + 新建对话
        </button>
      </div>

      <div class="conversation-list">
        <div v-if="loadingConversations" class="panel-state">
          正在加载会话...
        </div>

        <div v-else-if="conversationError" class="panel-state error">
          {{ conversationError }}
        </div>

        <div v-else-if="conversations.length === 0" class="panel-state">
          暂无会话
        </div>

        <div
          v-for="conversation in conversations"
          :key="conversation.id"
          class="conversation-item"
          :class="{ active: currentConversationId === conversation.id }"
          @click="selectConversation(conversation.id)"
        >
          <div class="conversation-main">
            <div class="conversation-title">
              {{ conversation.title || "新对话" }}
            </div>
            <div class="conversation-time">
              {{ formatTime(conversation.updatedAt || conversation.createdAt) }}
            </div>
          </div>

          <div class="conversation-actions">
            <button
              class="icon-button"
              type="button"
              title="重命名"
              @click.stop="renameConversation(conversation)"
            >
              ✎
            </button>
            <button
              class="icon-button danger"
              type="button"
              title="删除"
              @click.stop="removeConversation(conversation)"
            >
              ×
            </button>
          </div>
        </div>
      </div>
    </aside>

    <section class="chat-panel">
      <div v-if="messages.length === 0 && !loading" class="chat-empty">
        <div class="empty-icon">✦</div>
        <h2>开始新的对话</h2>
        <p>在下方输入内容，或从左侧选择一个会话</p>

        <div class="suggestions">
          <button type="button" @click="sendSuggestion('构建一个Python的学习计划')">
            构建一个Python的学习计划
          </button>
          <button type="button" @click="sendSuggestion('一句话描述一下唐朝的历史')">
            一句话描述一下唐朝的历史
          </button>
          <button type="button" @click="sendSuggestion('描述一下Android开发的可拓展方向')">
            描述一下Android开发的可拓展方向
          </button>
        </div>
      </div>

      <div v-else ref="messageListRef" class="message-list">
        <div v-if="loadingMessages" class="panel-state">
          正在加载消息...
        </div>

        <div v-else-if="messageError" class="panel-state error">
          {{ messageError }}
        </div>

        <div
          v-for="(message, index) in messages"
          :key="message.id || `${message.role}-${index}`"
          class="message-row"
          :class="message.isUser || message.role === 'user' ? 'from-user' : 'from-assistant'"
        >
          <div class="message-bubble">
            <div v-if="message.imageUrls && message.imageUrls.length" class="message-images">
              <img
                v-for="imageUrl in message.imageUrls"
                :key="imageUrl"
                :src="resolveFileUrl(imageUrl)"
                alt="聊天图片"
              />
            </div>

            <div v-if="message.content" class="message-text">
              {{ message.content }}
            </div>

            <div class="message-meta">
              <span v-if="message.streaming" class="streaming-cursor" />
              <span>{{ formatTime(message.createdAt) }}</span>
            </div>
          </div>
        </div>
      </div>

      <footer class="composer">
        <div v-if="attachments.length" class="attachment-list">
          <div v-for="(item, index) in attachments" :key="item.id" class="attachment-item">
            <img :src="item.previewUrl" alt="待发送图片" />
            <button type="button" @click="removeAttachment(index)">×</button>
          </div>
        </div>

        <div class="composer-row">
          <button
            class="attach-button"
            type="button"
            title="添加图片"
            @click="fileInputRef?.click()"
          >
            ＋
          </button>

          <textarea
            v-model="inputText"
            rows="1"
            placeholder="输入消息，Enter 发送，Shift + Enter 换行"
            @keydown.enter.exact.prevent="sendCurrentMessage"
          />

          <button
            v-if="thinking"
            class="send-button stop"
            type="button"
            @click="stopGenerate"
          >
            停止
          </button>
          <button
            v-else
            class="send-button"
            type="button"
            :disabled="!canSend"
            @click="sendCurrentMessage"
          >
            发送
          </button>
        </div>

        <input
          ref="fileInputRef"
          class="hidden-input"
          type="file"
          accept="image/*"
          multiple
          @change="handleFileChange"
        />
      </footer>
    </section>
  </div>
</template>

<style scoped>
.ai-chat-page {
  display: flex;
  width: 100%;
  height: calc(100vh - 64px - 48px);
  min-height: 560px;
  overflow: hidden;
  background: #fff;
  border: 1px solid #eef0f5;
  border-radius: 16px;
  box-shadow: 0 12px 32px rgb(31 42 78 / 8%);
}

.conversation-panel {
  display: flex;
  flex: 0 0 280px;
  flex-direction: column;
  background: #fafbfd;
  border-right: 1px solid #eef0f5;
}

.panel-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 18px 16px 12px;
  font-size: 15px;
  font-weight: 600;
  color: #2f3542;
}

.new-button {
  padding: 7px 10px;
  color: #4776e6;
  background: #eef4ff;
  border: none;
  border-radius: 8px;
  cursor: pointer;
}

.conversation-list {
  flex: 1;
  padding: 4px 10px 14px;
  overflow-y: auto;
}

.panel-state {
  padding: 24px 12px;
  color: #8a94a6;
  font-size: 13px;
  text-align: center;
}

.panel-state.error {
  color: #e5484d;
}

.conversation-item {
  position: relative;
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 6px;
  padding: 12px;
  color: #333;
  border: 1px solid transparent;
  border-radius: 12px;
  cursor: pointer;
  transition: background 0.2s ease;
}

.conversation-item:hover {
  background: #f0f3f8;
}

.conversation-item.active {
  background: #eaf1ff;
  border-color: #cddefc;
}

.conversation-main {
  min-width: 0;
}

.conversation-title {
  overflow: hidden;
  color: #333;
  font-size: 14px;
  font-weight: 500;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.conversation-time {
  margin-top: 5px;
  color: #a2a9b6;
  font-size: 12px;
}

.conversation-actions {
  display: none;
  align-items: center;
  gap: 4px;
}

.conversation-item:hover .conversation-actions {
  display: flex;
}

.icon-button {
  width: 26px;
  height: 26px;
  color: #7b8494;
  background: transparent;
  border: none;
  border-radius: 6px;
  cursor: pointer;
}

.icon-button:hover {
  color: #4776e6;
  background: #fff;
}

.icon-button.danger:hover {
  color: #e5484d;
}

.chat-panel {
  position: relative;
  display: flex;
  flex: 1;
  min-width: 0;
  flex-direction: column;
}

.chat-empty {
  flex: 1;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-direction: column;
  padding: 40px 24px;
  color: #8a94a6;
}

.empty-icon {
  margin-bottom: 14px;
  color: #b8c7e8;
  font-size: 48px;
}

.chat-empty h2 {
  margin: 0;
  color: #4c5666;
  font-size: 20px;
}

.chat-empty p {
  margin: 10px 0 0;
  font-size: 13px;
}

.suggestions {
  display: grid;
  gap: 10px;
  width: 100%;
  max-width: 520px;
  margin-top: 30px;
}

.suggestions button {
  min-height: 48px;
  padding: 10px 16px;
  color: #424242;
  background: #f7f8fb;
  border: 1px solid #eef0f5;
  border-radius: 10px;
  cursor: pointer;
  text-align: left;
}

.suggestions button:hover {
  color: #4776e6;
  background: #eef4ff;
}

.message-list {
  flex: 1;
  padding: 24px 28px;
  overflow-y: auto;
  background: #fff;
}

.message-row {
  display: flex;
  margin-bottom: 18px;
}

.message-row.from-user {
  justify-content: flex-end;
}

.message-row.from-assistant {
  justify-content: flex-start;
}

.message-bubble {
  max-width: 72%;
  padding: 12px 14px;
  background: #f3f5f9;
  border-radius: 6px 14px 14px 14px;
}

.from-user .message-bubble {
  color: #fff;
  background: #4776e6;
  border-radius: 14px 6px 14px 14px;
}

.message-text {
  color: #333;
  font-size: 14px;
  line-height: 1.7;
  white-space: pre-wrap;
  word-break: break-word;
}

.from-user .message-text {
  color: #fff;
}

.message-images {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
  margin-bottom: 10px;
}

.message-images img {
  width: 120px;
  height: 120px;
  object-fit: cover;
  border-radius: 10px;
}

.message-meta {
  display: flex;
  align-items: center;
  justify-content: flex-end;
  gap: 6px;
  margin-top: 7px;
  color: #a2a9b6;
  font-size: 11px;
}

.from-user .message-meta {
  color: rgb(255 255 255 / 70%);
}

.streaming-cursor {
  display: inline-block;
  width: 6px;
  height: 14px;
  background: #4776e6;
  animation: blink 1s step-end infinite;
}

@keyframes blink {
  50% {
    opacity: 0;
  }
}

.composer {
  padding: 14px 18px 18px;
  background: #fff;
  border-top: 1px solid #eef0f5;
}

.attachment-list {
  display: flex;
  gap: 10px;
  padding-bottom: 12px;
  overflow-x: auto;
}

.attachment-item {
  position: relative;
  flex: 0 0 72px;
  width: 72px;
  height: 72px;
}

.attachment-item img {
  width: 100%;
  height: 100%;
  object-fit: cover;
  border-radius: 10px;
}

.attachment-item button {
  position: absolute;
  top: -6px;
  right: -6px;
  display: flex;
  align-items: center;
  justify-content: center;
  width: 20px;
  height: 20px;
  color: #fff;
  background: rgb(0 0 0 / 60%);
  border: none;
  border-radius: 50%;
  cursor: pointer;
}

.composer-row {
  display: flex;
  align-items: flex-end;
  gap: 10px;
}

.attach-button {
  flex: 0 0 44px;
  height: 44px;
  color: #4776e6;
  background: #f2f6ff;
  border: 1px solid #e2ebfb;
  border-radius: 12px;
  cursor: pointer;
  font-size: 22px;
  line-height: 1;
}

.composer textarea {
  flex: 1;
  max-height: 140px;
  min-height: 44px;
  padding: 12px 14px;
  resize: none;
  color: #333;
  background: #f7f8fb;
  border: 1px solid #e5e8ef;
  border-radius: 12px;
  font: inherit;
  line-height: 1.5;
  outline: none;
}

.composer textarea:focus {
  background: #fff;
  border-color: #4776e6;
}

.send-button {
  min-width: 76px;
  height: 44px;
  color: #fff;
  background: #4776e6;
  border: none;
  border-radius: 12px;
  cursor: pointer;
}

.send-button:disabled {
  cursor: not-allowed;
  opacity: 0.55;
}

.send-button.stop {
  background: #8a94a6;
}

.hidden-input {
  display: none;
}

@media (max-width: 760px) {
  .ai-chat-page {
    height: calc(100vh - 60px - 24px);
    min-height: 480px;
    border-radius: 12px;
  }

  .conversation-panel {
    flex-basis: 220px;
  }

  .message-bubble {
    max-width: 86%;
  }

  .message-images img {
    width: 92px;
    height: 92px;
  }
}
</style>
