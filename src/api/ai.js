import request, { API_BASE_URL, getToken } from "./request";

export function getLLMModels() {
  return request.get("api/llm/models");
}

export function getConversationList() {
  return request.get("api/ai/conversation/list");
}

export function getMessageList(conversationId) {
  return request.get("api/ai/message/list", {
    params: { conversationId }
  });
}

export function updateConversationTitle(conversationId, title) {
  return request.put("api/ai/conversation/title", null, {
    params: { conversationId, title }
  });
}

export function deleteConversation(conversationId) {
  return request.delete("api/ai/conversation", {
    params: { conversationId }
  });
}

function getStreamBaseUrl() {
  return API_BASE_URL;
}

function getAuthHeaders(isFormData = false) {
  const headers = {};
  if (!isFormData) {
    headers["Content-Type"] = "application/json";
  }

  const token = getToken();
  if (token) {
    headers.Authorization = `Bearer ${token}`;
  }

  return headers;
}

export async function uploadAIImages(files, signal) {
  const formData = new FormData();
  for (const file of files) {
    formData.append("files", file);
  }

  const response = await fetch(`${getStreamBaseUrl()}/api/file/upload/ai/images`, {
    method: "POST",
    headers: getAuthHeaders(true),
    body: formData,
    signal
  });

  if (!response.ok) {
    const text = await response.text();
    throw new Error(text || "图片上传失败");
  }

  const result = await response.json();
  if (result.code !== 200) {
    throw new Error(result.msg || "图片上传失败");
  }

  return result.data || [];
}

function createSseEvent(eventName, data) {
  return {
    event: eventName || data?.type || "message",
    type: data?.type ?? null,
    content: data?.content ?? "",
    conversationId: data?.conversationId ?? null,
    messageId: data?.messageId ?? null
  };
}

export async function streamChat({
  conversationId,
  message,
  imageUrls = [],
  modelId,
  signal,
  onEvent
}) {
  const body = {
    conversationId,
    message,
    modelId,
    ...(imageUrls.length ? { imageUrls } : {})
  };

  const response = await fetch(`${getStreamBaseUrl()}/api/ai/chat/user/stream`, {
    method: "POST",
    headers: getAuthHeaders(),
    body: JSON.stringify(body),
    signal
  });

  if (!response.ok) {
    const text = await response.text();
    throw new Error(text || "AI 请求失败");
  }

  const reader = response.body?.getReader();
  if (!reader) {
    throw new Error("当前浏览器不支持流式响应");
  }

  const decoder = new TextDecoder("utf-8");
  let buffer = "";
  let currentEventName = "";

  while (true) {
    const { value, done } = await reader.read();
    if (done) {
      break;
    }

    buffer += decoder.decode(value, { stream: true });
    const lines = buffer.split(/\r?\n/);
    buffer = lines.pop() || "";

    for (const line of lines) {
      const trimmed = line.trim();
      if (!trimmed) {
        currentEventName = "";
        continue;
      }

      if (trimmed.startsWith("event:")) {
        currentEventName = trimmed.slice(6).trim();
        continue;
      }

      if (!trimmed.startsWith("data:")) {
        onEvent?.({
          event: "error",
          type: "error",
          content: trimmed,
          conversationId: null,
          messageId: null
        });
        continue;
      }

      const payload = trimmed.slice(5).trim();
      if (!payload) {
        continue;
      }

      try {
        const data = JSON.parse(payload);
        onEvent?.(createSseEvent(currentEventName, data));
      } catch {
        onEvent?.({
          event: "error",
          type: "error",
          content: `解析 SSE 数据失败：${payload}`,
          conversationId: null,
          messageId: null
        });
      }
    }
  }

  if (buffer) {
    const trimmed = buffer.trim();
    if (trimmed.startsWith("data:")) {
      const payload = trimmed.slice(5).trim();
      try {
        const data = JSON.parse(payload);
        onEvent?.(createSseEvent(currentEventName, data));
      } catch {
        onEvent?.({
          event: "error",
          type: "error",
          content: `解析 SSE 数据失败：${payload}`,
          conversationId: null,
          messageId: null
        });
      }
    }
  }
}
