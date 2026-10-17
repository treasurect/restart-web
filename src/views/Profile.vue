<script setup>
import { ref } from 'vue'
import { useRouter } from 'vue-router'

const router = useRouter()

const user = ref({
  username: '王哥',
  nickname: '枣山路·穆勒',
  avatar: ''
})

const goMoment = () => {
  router.push('/moments')
}

const goAlbum = () => {
  router.push('/album')
}

const goSetting = () => {
  alert('稍微一等！！！')
}
</script>

<template>
  <div class="mine-page">

    <!-- 用户信息 -->
    <div class="user-card">

      <div class="avatar">
        <img
          v-if="user.avatar"
          :src="user.avatar"
          alt="头像"
        />

        <span v-else>
          {{ user.username?.charAt(0) || '?' }}
        </span>
      </div>

      <div class="user-info">
        <div class="username">
          {{ user.nickname || user.username }}
        </div>

        <div class="account">
          @{{ user.username }}
        </div>
      </div>

    </div>


    <!-- 功能 -->
    <div class="menu">

      <div
        class="menu-item"
        @click="goMoment"
      >
        <div class="menu-left">
          <span class="icon">📝</span>
          <span>我的朋友圈</span>
        </div>

        <span class="arrow">›</span>
      </div>


      <div
        class="menu-item"
        @click="goAlbum"
      >
        <div class="menu-left">
          <span class="icon">🖼️</span>
          <span>我的相册</span>
        </div>

        <span class="arrow">›</span>
      </div>


      <div class="menu-item"
           @click="goSetting">
        <div class="menu-left">
          <span class="icon">⚙️</span>
          <span>设置</span>
        </div>

        <span class="arrow">›</span>
      </div>

    </div>

  </div>
</template>

<style scoped>
.mine-page {
  max-width: 900px;
  margin: 0 auto;
  padding: 24px;
}

/* 用户卡片 */
.user-card {
  display: flex;
  align-items: center;

  padding: 30px;

  border-radius: 16px;

  background: #fff;

  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.05);
}

/* 头像 */
.avatar {
  width: 80px;
  height: 80px;

  display: flex;
  align-items: center;
  justify-content: center;

  overflow: hidden;

  border-radius: 50%;

  background: #eee;

  color: #666;

  font-size: 28px;
  font-weight: 600;
}

.avatar img {
  width: 100%;
  height: 100%;

  object-fit: cover;
}

/* 用户信息 */
.user-info {
  margin-left: 20px;
}

.username {
  font-size: 22px;
  font-weight: 600;
  color: #222;
}

.account {
  margin-top: 6px;

  font-size: 14px;
  color: #999;
}


/* 菜单 */
.menu {
  margin-top: 20px;

  overflow: hidden;

  border-radius: 14px;

  background: #fff;

  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.05);
}

.menu-item {
  display: flex;
  align-items: center;
  justify-content: space-between;

  padding: 18px 20px;

  border-bottom: 1px solid #f2f2f2;

  cursor: pointer;

  transition: background 0.2s;
}

.menu-item:last-child {
  border-bottom: none;
}

.menu-item:hover {
  background: #f8f8f8;
}

.menu-left {
  display: flex;
  align-items: center;

  font-size: 15px;
  color: #333;
}

.icon {
  width: 30px;

  margin-right: 10px;

  font-size: 20px;
}

.arrow {
  font-size: 24px;
  color: #bbb;
}


/* 退出 */
.logout {
  width: 100%;

  margin-top: 25px;

  padding: 14px;

  border: none;

  border-radius: 10px;

  background: #fff;

  color: #f44336;

  font-size: 15px;

  cursor: pointer;

  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.05);
}

.logout:hover {
  background: #fff5f5;
}


/* 手机 */
@media (max-width: 600px) {
  .mine-page {
    padding: 12px;
  }

  .user-card {
    padding: 22px;
  }

  .avatar {
    width: 60px;
    height: 60px;

    font-size: 22px;
  }

  .username {
    font-size: 18px;
  }
}
</style>
