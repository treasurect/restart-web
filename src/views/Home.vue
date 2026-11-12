<script setup>
import { onActivated, onBeforeUnmount, onDeactivated, onMounted, ref } from "vue";
import { getCarouselList } from "@/api/ext";
import logoImage from "@/assets/images/logo_treasure.png";

defineOptions({
  name: "HomePage"
});

const BASE_URL = import.meta.env.VITE_API_BASE_URL || "";

const carouselList = ref([]);
const currentSlide = ref(0);
const loading = ref(false);
const errorMsg = ref("");

let timer = null;
let touchStartX = 0;

function resolveImageUrl(url) {
  if (!url) {
    return "";
  }

  if (/^(https?:)?\/\//.test(url) || url.startsWith("data:") || url.startsWith("blob:")) {
    return url;
  }

  const separator = url.startsWith("/") ? "" : "/";
  return `${BASE_URL}${separator}${url}`;
}

function changeSlide(index) {
  if (!carouselList.value.length) {
    return;
  }

  currentSlide.value = (index + carouselList.value.length) % carouselList.value.length;
}

function startAutoPlay() {
  stopAutoPlay();

  if (carouselList.value.length <= 1) {
    return;
  }

  timer = setInterval(() => {
    changeSlide(currentSlide.value + 1);
  }, 4000);
}

function stopAutoPlay() {
  if (timer) {
    clearInterval(timer);
    timer = null;
  }
}

function handleTouchStart(event) {
  touchStartX = event.changedTouches[0].clientX;
  stopAutoPlay();
}

function handleTouchEnd(event) {
  const touchEndX = event.changedTouches[0].clientX;
  const diff = touchEndX - touchStartX;

  if (Math.abs(diff) > 40) {
    changeSlide(currentSlide.value + (diff > 0 ? -1 : 1));
  }

  startAutoPlay();
}

async function loadCarousel() {
  loading.value = true;
  errorMsg.value = "";

  try {
    const result = await getCarouselList();

    if (result.code === 200) {
      carouselList.value = [...(result.data || [])].sort(
        (a, b) => (a.sort ?? 0) - (b.sort ?? 0)
      );
      currentSlide.value = 0;
      startAutoPlay();
    } else {
      errorMsg.value = result.msg || "获取轮播图失败";
    }
  } catch (error) {
    errorMsg.value = error.message || "获取轮播图失败";
  } finally {
    loading.value = false;
  }
}

onMounted(loadCarousel);
onActivated(startAutoPlay);
onDeactivated(stopAutoPlay);
onBeforeUnmount(stopAutoPlay);
</script>

<template>
  <div class="home-page">
    <section class="home-hero">
      <div class="brand">
        <img class="brand-logo" :src="logoImage" alt="Treasure Logo" />
        <div class="brand-copy">
          <h1>Treasure</h1>
          <p>记录、分享每一个值得珍藏的瞬间</p>
        </div>
      </div>

      <div
        v-if="loading"
        class="carousel carousel-state"
      >
        正在加载轮播图...
      </div>

      <div
        v-else-if="errorMsg"
        class="carousel carousel-state error"
      >
        {{ errorMsg }}
      </div>

      <div
        v-else-if="carouselList.length > 0"
        class="carousel"
        @mouseenter="stopAutoPlay"
        @mouseleave="startAutoPlay"
        @touchstart.passive="handleTouchStart"
        @touchend.passive="handleTouchEnd"
      >
        <div
          class="carousel-track"
          :style="{ transform: `translateX(-${currentSlide * 100}%)` }"
        >
          <div
            v-for="item in carouselList"
            :key="item.id"
            class="carousel-slide"
          >
            <img
              v-if="resolveImageUrl(item.imageUrl)"
              :src="resolveImageUrl(item.imageUrl)"
              :alt="item.momentContent || '轮播图'"
            />
            <div
              v-else
              class="slide-placeholder"
            >
              Treasure
            </div>

            <div class="slide-mask" />

            <div class="slide-info">
              <div
                v-if="item.createUserName"
                class="slide-author"
              >
                <img
                  v-if="resolveImageUrl(item.createUserAvatar)"
                  class="author-avatar"
                  :src="resolveImageUrl(item.createUserAvatar)"
                  alt=""
                />
                <span
                  v-else
                  class="author-avatar fallback"
                >
                  {{ item.createUserName?.charAt(0) || "T" }}
                </span>
                <span>{{ item.createUserName }}</span>
              </div>

              <p v-if="item.momentContent" class="slide-content">
                {{ item.momentContent }}
              </p>
            </div>
          </div>
        </div>

        <button
          v-if="carouselList.length > 1"
          class="carousel-arrow prev"
          type="button"
          aria-label="上一张"
          @click="changeSlide(currentSlide - 1)"
        >
          ‹
        </button>

        <button
          v-if="carouselList.length > 1"
          class="carousel-arrow next"
          type="button"
          aria-label="下一张"
          @click="changeSlide(currentSlide + 1)"
        >
          ›
        </button>

        <div
          v-if="carouselList.length > 1"
          class="carousel-dots"
        >
          <button
            v-for="(item, index) in carouselList"
            :key="item.id"
            type="button"
            class="carousel-dot"
            :class="{ active: currentSlide === index }"
            :aria-label="`第 ${index + 1} 张`"
            @click.stop="changeSlide(index)"
          />
        </div>
      </div>

      <div
        v-else
        class="carousel carousel-state"
      >
        暂无轮播内容
      </div>
    </section>
  </div>
</template>

<style scoped>
.home-page {
  width: 100%;
}

.home-hero {
  width: 100%;
  max-width: 1100px;
  margin: 0 auto;
}

.brand {
  display: flex;
  align-items: center;
  gap: 18px;
  margin-bottom: 28px;
}

.brand-logo {
  width: 68px;
  height: 68px;
  object-fit: contain;
  filter: drop-shadow(0 8px 18px rgb(28 43 89 / 18%));
}

.brand-copy h1 {
  margin: 0;
  color: #2f3542;
  font-size: 30px;
  line-height: 1.2;
}

.brand-copy p {
  margin: 8px 0 0;
  color: #8a94a6;
  font-size: 14px;
}

.carousel {
  position: relative;
  width: 100%;
  aspect-ratio: 21 / 9;
  overflow: hidden;
  background: linear-gradient(120deg, #4776e6, #7559c9);
  border-radius: 18px;
  box-shadow: 0 16px 40px rgb(58 73 121 / 18%);
}

.carousel-state {
  display: flex;
  align-items: center;
  justify-content: center;
  color: #fff;
  font-size: 15px;
}

.carousel-state.error {
  background: linear-gradient(120deg, #6b7280, #4b5563);
}

.carousel-track {
  display: flex;
  height: 100%;
  transition: transform 0.45s ease;
}

.carousel-slide {
  position: relative;
  flex: 0 0 100%;
  height: 100%;
}

.carousel-slide > img,
.slide-placeholder {
  display: block;
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.slide-placeholder {
  display: flex;
  align-items: center;
  justify-content: center;
  color: rgb(255 255 255 / 85%);
  background: linear-gradient(120deg, #4776e6, #7559c9);
  font-size: 28px;
  font-weight: 700;
  letter-spacing: 2px;
}

.slide-mask {
  position: absolute;
  inset: 0;
  background: linear-gradient(
    90deg,
    rgb(15 20 35 / 62%) 0%,
    rgb(15 20 35 / 18%) 55%,
    rgb(15 20 35 / 8%) 100%
  );
}

.slide-info {
  position: absolute;
  inset: auto 54px 42px 42px;
  color: #fff;
}

.slide-author {
  display: flex;
  align-items: center;
  gap: 10px;
  font-size: 14px;
  font-weight: 600;
}

.author-avatar {
  flex: 0 0 32px;
  width: 32px;
  height: 32px;
  object-fit: cover;
  border: 2px solid rgb(255 255 255 / 75%);
  border-radius: 50%;
}

.author-avatar.fallback {
  display: flex;
  align-items: center;
  justify-content: center;
  color: #fff;
  background: rgb(255 255 255 / 22%);
}

.slide-content {
  display: -webkit-box;
  max-width: 68%;
  margin: 14px 0 0;
  overflow: hidden;
  color: rgb(255 255 255 / 92%);
  font-size: 15px;
  line-height: 1.7;
  text-shadow: 0 2px 10px rgb(0 0 0 / 25%);
  -webkit-box-orient: vertical;
  -webkit-line-clamp: 2;
}

.carousel-arrow {
  position: absolute;
  z-index: 2;
  top: 50%;
  width: 38px;
  height: 52px;
  color: #fff;
  background: rgb(255 255 255 / 14%);
  border: none;
  border-radius: 8px;
  font-size: 34px;
  line-height: 1;
  cursor: pointer;
  transform: translateY(-50%);
  transition: background 0.2s ease;
}

.carousel-arrow:hover {
  background: rgb(255 255 255 / 26%);
}

.carousel-arrow.prev {
  left: 18px;
}

.carousel-arrow.next {
  right: 18px;
}

.carousel-dots {
  position: absolute;
  right: 0;
  bottom: 16px;
  left: 0;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
}

.carousel-dot {
  display: block;
  width: 8px;
  height: 8px;
  padding: 0;
  background: rgb(255 255 255 / 45%);
  border: 0;
  border-radius: 50%;
  cursor: pointer;
  transition:
    width 0.25s ease,
    background 0.25s ease;
}

.carousel-dot:hover {
  background: rgb(255 255 255 / 75%);
}

.carousel-dot.active {
  width: 26px;
  background: #fff;
  border-radius: 10px;
}

@media (max-width: 700px) {
  .brand-logo {
    width: 52px;
    height: 52px;
  }

  .brand-copy h1 {
    font-size: 24px;
  }

  .carousel {
    aspect-ratio: 16 / 10;
    border-radius: 14px;
  }

  .slide-info {
    inset: auto 38px 24px 18px;
  }

  .slide-content {
    max-width: 100%;
    margin-top: 10px;
    font-size: 13px;
  }

  .carousel-arrow {
    width: 30px;
    height: 42px;
    font-size: 28px;
  }

  .carousel-arrow.prev {
    left: 8px;
  }

  .carousel-arrow.next {
    right: 8px;
  }
}
</style>
