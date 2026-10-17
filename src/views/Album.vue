<script setup>
import { ref, onMounted } from 'vue';
import request from '@/api/request';
import { BASE_URL } from '@/api/request';

const albumList = ref([])
const loading = ref(false)
const errorMsg = ref("")
const curPhoto = ref(null)

const loadAlbum = async () => {
  loading.value = true
  errorMsg.value = ''

  try {
    const result = await request.get('api/album/list')
    console.log('album 接口返回', result)
    if(result.code === 200){
      albumList.value = result.data?.imageList || []
    } else {
      errorMsg.value = result.msg || '相册获取失败'
    }
  }catch(error){
    console.log('相册获取失败', error)
    errorMsg.value = error || '相册获取失败'
  } finally {
    loading.value = false
  }
}

const formatTime = (time) => {
  if(!time) return ''
  return moment(time).formatTime("YYYY-MM-DD HH:mm")
}

const openPhoto= (photo) => curPhoto.value = photo
const closePhoto = () => curPhoto.value = null

const handleKeyDown = (event) => {
  if(event.key = "Escape") closePhoto()
}

onMounted (() => {
  loadAlbum()
  window.addEventListener("keydown",handleKeyDown)
})
</script>
<template>
  <div class="album-page">
    <div class="album-header">
      <h1>相册</h1>
      <div class="album-count">
        共{{ albumList.length }}张图片
      </div>
    </div>
    <div class="state" v-if="loading">
      <div class="loading-spinner"></div>
      <div>正在加载。。。</div>
    </div>
    <div class="state error" v-else-if="errorMsg">
      <div>{{ errorMsg }}</div>
      <button class="retry-button" @click="loadAlbum">重试</button>
    </div>
    <div v-else-if="albumList.length === 0" class="tate">
      暂无照片
    </div>
    <div v-else class="photo-grid">
      <div
        v-for="photo in albumList"
        :key="photo.id"
        class="photo-card"
        @click="openPhoto(photo)">
        <img
          class="photo"
          :src="BASE_URL + photo.imageUrl"
          :alt="photo.createUserName || '图片'"
          loading="lazy"/>
        <div class="photo-info">
          <div class="user-info">
            <img
            v-if="photo.createUserAvatar"
            class="avatar"
            :src="BASE_URL + photo.createUserAvatar"/>
            <div v-else class="avatar avatar-default">
              {{ photo.createUserName?.charAt(0) || "?" }}
            </div>
          </div>
          <div class="user-text">
            <div class="username">{{ photo.createUserName || '未知用户' }}</div>
            <div class="time">{{ formatTime(photo.createAt) }}</div>
          </div>
        </div>
      </div>
    </div>
    <div class="preview-mask"
         v-if="curPhoto"
         @click.self="closePhoto">
         <div class="preview-container">
          <button class="close-button" @click="closePhoto">×</button>
          <img class="preview-image"
               :src="BASE_URL + curPhoto.imageUrl"
               :alt="curPhoto.createUserName || '图片'"/>
          <div class="preview-info">
          <div class="preview-user">
            <img
              v-if="curPhoto.createUserAvatar"
              class="avatar"
              :src="BASE_URL + curPhoto.createUserAvatar"/>
            <div v-else class="preview-avatar avatar-default">
              {{ curPhoto.createUserName?.charAt(0) || "?" }}
            </div>
          </div>
          <div>
            <div class="preview-username">{{ curPhoto.createUserName || '未知用户' }}</div>
            <div class="preview-time">{{ formatTime(curPhoto.createAt) }}</div>
          </div>
        </div>
         </div>
    </div>


  </div>
</template>

<style scoped>

/* ========================================
   页面
======================================== */

.album-page {
  width: 100%;
  max-width: 1400px;

  margin: 0 auto;

  padding: 24px;

  box-sizing: border-box;
}


/* ========================================
   标题
======================================== */

.album-header {
  display: flex;

  align-items: center;
  justify-content: space-between;

  margin-bottom: 24px;
}

.album-header h1 {
  margin: 0;

  font-size: 28px;
  font-weight: 600;

  color: #222;
}

.album-count {
  margin-top: 6px;

  font-size: 13px;

  color: #999;
}


/* ========================================
   宫格
======================================== */

.photo-grid {
  display: grid;

  grid-template-columns: repeat(4, 1fr);

  gap: 18px;
}


/* ========================================
   图片卡片
======================================== */

.photo-card {
  position: relative;

  width: 100%;

  aspect-ratio: 1 / 1;

  overflow: hidden;

  border-radius: 12px;

  background: #f2f2f2;

  cursor: pointer;
}


/* ========================================
   图片
======================================== */

.photo {
  position: absolute;

  inset: 0;

  width: 100%;
  height: 100%;

  object-fit: cover;

  z-index: 1;

  transition: transform 0.3s ease;
}


/* ========================================
   顶部信息
======================================== */

.photo-info {
  position: absolute;

  top: 0;
  left: 0;
  right: 0;

  padding: 14px;

  z-index: 10;

  /*
   * 顶部渐变
   * 让文字在各种图片上都清晰
   */
  background: linear-gradient(
    to bottom,
    rgba(0, 0, 0, 0.7),
    rgba(0, 0, 0, 0)
  );
}


/* ========================================
   用户信息
======================================== */

.user-info {
  display: flex;

  align-items: center;

  color: #fff;
}


/* ========================================
   头像
======================================== */

.avatar {
  width: 38px;
  height: 38px;

  flex-shrink: 0;

  border-radius: 50%;

  object-fit: cover;

  border: 1px solid rgba(255, 255, 255, 0.7);

  box-sizing: border-box;
}

.avatar-default {
  display: flex;

  align-items: center;
  justify-content: center;

  background: rgba(255, 255, 255, 0.25);

  backdrop-filter: blur(5px);

  color: #fff;

  font-size: 14px;

  font-weight: 600;
}


/* ========================================
   用户文字
======================================== */

.user-text {
  margin-left: 10px;

  min-width: 0;
}

.username {
  max-width: 180px;

  overflow: hidden;

  text-overflow: ellipsis;

  white-space: nowrap;

  font-size: 14px;

  font-weight: 600;

  color: #fff;

  text-shadow:
    0 1px 3px rgba(0, 0, 0, 0.6);
}

.time {
  margin-top: 3px;

  font-size: 11px;

  color: rgba(255, 255, 255, 0.85);

  text-shadow:
    0 1px 3px rgba(0, 0, 0, 0.6);
}


/* ========================================
   Hover
======================================== */

.photo-card:hover .photo {
  transform: scale(1.05);
}


/* ========================================
   加载 / 空状态
======================================== */

.state {
  display: flex;

  flex-direction: column;

  align-items: center;
  justify-content: center;

  min-height: 300px;

  color: #999;

  font-size: 14px;
}

.error {
  color: #f44336;
}


/* ========================================
   Loading
======================================== */

.loading-spinner {
  width: 30px;
  height: 30px;

  margin-bottom: 15px;

  border: 3px solid #eee;

  border-top-color: #999;

  border-radius: 50%;

  animation: loading 0.8s linear infinite;
}

@keyframes loading {
  to {
    transform: rotate(360deg);
  }
}


/* ========================================
   重试
======================================== */

.retry-button {
  margin-top: 15px;

  padding: 7px 18px;

  border: none;

  border-radius: 6px;

  background: #333;

  color: #fff;

  cursor: pointer;
}


/* ========================================
   图片预览
======================================== */

.preview-mask {
  position: fixed;

  inset: 0;

  z-index: 9999;

  display: flex;

  align-items: center;
  justify-content: center;

  padding: 30px;

  box-sizing: border-box;

  background: rgba(0, 0, 0, 0.85);
}


/* ========================================
   预览容器
======================================== */

.preview-container {
  position: relative;

  max-width: 90vw;
  max-height: 90vh;

  display: flex;

  flex-direction: column;

  align-items: center;
}


/* ========================================
   预览图片
======================================== */

.preview-image {
  display: block;

  max-width: 90vw;

  max-height: 78vh;

  object-fit: contain;

  border-radius: 6px;
}


/* ========================================
   关闭按钮
======================================== */

.close-button {
  position: absolute;

  top: -45px;
  right: -45px;

  width: 36px;
  height: 36px;

  border: none;

  border-radius: 50%;

  background: rgba(255, 255, 255, 0.15);

  color: #fff;

  font-size: 28px;

  line-height: 36px;

  cursor: pointer;
}


/* ========================================
   预览信息
======================================== */

.preview-info {
  width: 100%;

  margin-top: 12px;

  padding: 10px 14px;

  box-sizing: border-box;

  border-radius: 8px;

  background: rgba(0, 0, 0, 0.6);

  color: #fff;
}

.preview-user {
  display: flex;

  align-items: center;
}

.preview-avatar {
  width: 36px;
  height: 36px;

  margin-right: 10px;

  border-radius: 50%;

  object-fit: cover;
}

.preview-username {
  font-size: 14px;

  font-weight: 600;
}

.preview-time {
  margin-top: 3px;

  font-size: 11px;

  color: #aaa;
}


/* ========================================
   平板
======================================== */

@media (max-width: 900px) {

  .photo-grid {
    grid-template-columns: repeat(2, 1fr);
  }

}


/* ========================================
   手机
======================================== */

@media (max-width: 600px) {

  .album-page {
    padding: 12px;
  }

  .photo-grid {
    grid-template-columns: repeat(2, 1fr);

    gap: 8px;
  }

  .photo-card {
    border-radius: 8px;
  }

  .photo-info {
    padding: 9px;
  }

  .avatar {
    width: 30px;
    height: 30px;
  }

  .username {
    max-width: 100px;

    font-size: 12px;
  }

  .time {
    font-size: 9px;
  }

  .close-button {
    top: -40px;
    right: 0;
  }

}

</style>
