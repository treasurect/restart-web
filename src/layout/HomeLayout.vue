<script setup>
import { useRouter, useRoute, RouterView } from "vue-router";
import { removeToken } from "@/api/request";
import AppDownload from "@/components/AppDownload.vue";

const router = useRouter();
const route = useRoute();

const tabs = [
  { name: "首页", path: "/home" },
  { name: "朋友圈", path: "/moments" },
  { name: "图片", path: "/images" },
  { name: "我的", path: "/profile" }
];

function logout() {
  removeToken();
  router.push("/login");
}
</script>

<template>
  <div class="layout">
    <header class="header">
      <div class="logo">Treasure</div>

      <nav class="tabs">
        <RouterLink
          v-for="tab in tabs"
          :key="tab.path"
          :to="tab.path"
          class="tab"
          :class="{ active: route.path === tab.path }"
        >
          {{ tab.name }}
        </RouterLink>
      </nav>

      <AppDownload />
      
      <button class="logout" @click="logout">
        退出登录
      </button>
    </header>

    <main class="content">
      <RouterView />
    </main>
  </div>
</template>

<style scoped>
.layout {
  min-height: 100vh;
  background: #f5f6fa;
}

.header {
  height: 64px;
  padding: 0 32px;
  background: white;
  border-bottom: 1px solid #eee;
  display: flex;
  align-items: center;
  gap: 40px;
}

.logo {
  font-size: 22px;
  font-weight: bold;
  color: #333;
}

.tabs {
  display: flex;
  height: 100%;
  gap: 28px;
}

.tab {
  display: flex;
  align-items: center;
  padding: 0 4px;
  color: #666;
  text-decoration: none;
  border-bottom: 3px solid transparent;
}

.tab:hover {
  color: #409eff;
}

.tab.active {
  color: #409eff;
  border-bottom-color: #409eff;
}

.logout {
  margin-left: auto;
  padding: 8px 14px;
  border: 1px solid #ddd;
  border-radius: 6px;
  background: white;
  cursor: pointer;
}

.content {
  padding: 24px;
}

@media (max-width: 600px) {
  .header {
    height: auto;
    min-height: 60px;
    padding: 12px;
    gap: 12px;
    flex-wrap: wrap;
  }

  .tabs {
    gap: 16px;
    height: 44px;
    order: 3;
    width: 100%;
    overflow-x: auto;
  }

  .content {
    padding: 12px;
  }
}
</style>
