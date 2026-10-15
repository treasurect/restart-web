<script setup>
import { ref } from 'vue';
import qrCodeImage from '@/assets/Images/apk-qrcode.png'

const BASE_URL = import.meta.env.VITE_API_BASE_URL || "";
const visible = ref(false);
const apkUrl = BASE_URL+"/downloads/apk/app-release.apk"

function downloadApk() {
  window.open(apkUrl,"_blank")
}
</script>

<template>
  <div
    class="app-download"
    @mouseenter="visible = true"
    @mouseleave="visible = false">
    <span class="download-text">
      下载 APP<span class="arrow">▾</span>
    </span>
    <div v-if="visible" class="download-dropdown">
      <div class="dropdown-title">手机扫码下载</div>
      <img
        class="qr-code"
        :src="qrCodeImage"
        alt="APK 下载二维码"/>
      <div class="dropdown-tip">Android 客户端</div>
      <button class="download-button" @click="downloadApk">下载 APK</button>
    </div>
  </div>
</template>

<style scoped>
.app-download {
  position: relative;
  display: inline-block;
  padding: 12px 16px;
  cursor: pointer;
  color: #333;
  font-size: 14px;
}

.download-text {
  display: flex;
  align-items: center;
  gap: 6px;
}

.app-download:hover .download-text {
  color: #6c5ce7;
}

.arrow {
  font-size: 12px;
}

.download-dropdown {
  position: absolute;
  z-index: 9999;
  top: 100%;
  left: 50%;
  right: 0;
  transform: translateX(-50%);
  margin-top: 8px;

  width: 220px;
  padding: 20px;
  box-sizing: border-box;
  text-align: center;
  background: #fff;
  border: 1px solid #eee;
  border-radius: 12px;
  box-shadow: 0 8px 30px rgba(0, 0, 0, 0.12);
}

.dropdown-title {
  margin-bottom: 14px;
  font-size: 15px;
  font-weight: 600;
}

.qr-code {
  display: block;
  width: 160px;
  height: 160px;
  margin: 0 auto;
  object-fit: contain;
}

.dropdown-tip {
  margin-top: 10px;
  color: #888;
  font-size: 12px;
}

.download-button {
  width: 100%;
  margin-top: 14px;
  padding: 10px;
  color: #fff;
  background: #6c5ce7;
  border: none;
  border-radius: 8px;
  cursor: pointer;
}

.download-button:hover {
  background: #5948d6;
}
</style>
