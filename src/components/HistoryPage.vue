<script setup>
import {
  ref,
  computed,
  nextTick,
  onMounted,
  onUnmounted,
} from 'vue'

import { useRoute, useRouter } from 'vue-router'
import logo from "@/assets/images/logo_treasure.png"

const props = defineProps({
  title: {
    type: String,
    required: true,
  },

  tag: {
    type: String,
    default: 'HISTORY',
  },

  loadData: {
    type: Function,
    required: true,
  },
})

const router = useRouter()
const route = useRoute()

// =========================
// 基础状态
// =========================

const searchText = ref('')
const submittedKeyword = ref('')

const slides = ref([])
const currentSlide = ref(0)

const loading = ref(true)
const errorMessage = ref('')

const promptRefs = ref([])

let timer = null
let touchStartX = 0

// =========================
// 历史分类
// =========================

const categories = [
  {
    key: 'china',
    name: '中国历史',
    path: '/home',
  },
  {
    key: 'europe',
    name: '欧洲历史',
    path: '/history/europe',
  },
  {
    key: 'usa',
    name: '美国历史',
    path: '/history/usa',
  },
  {
    key: 'russia',
    name: '俄罗斯历史',
    path: '/history/russia',
  },
]

// =========================
// 当前分类
// =========================

const activeCategory = computed(() => {
  return categories.find(
    item => item.path === route.path
  ) || "/home"
})

// =========================
// 搜索结果
// =========================

const filteredPrompts = computed(() => {
  const keyword = submittedKeyword.value
    .trim()
    .toLowerCase()

  if (!keyword) {
    return slides.value
  }

  return slides.value.filter(item => {
    return `
      ${item.title || ''}
      ${item.description || ''}
      ${item.content || ''}
    `
      .toLowerCase()
      .includes(keyword)
  })
})

// =========================
// 轮播数量
// =========================

const slideCount = computed(() => {
  return slides.value.length
})

// =========================
// 切换轮播
// =========================

function changeSlide(index) {
  if (slideCount.value <= 0) {
    return
  }

  currentSlide.value =
    (index + slideCount.value) %
    slideCount.value
}

// =========================
// 自动播放
// =========================

function startAutoPlay() {
  stopAutoPlay()

  if (slideCount.value <= 1) {
    return
  }

  timer = setInterval(() => {
    changeSlide(currentSlide.value + 1)
  }, 4000)
}

function stopAutoPlay() {
  if (timer) {
    clearInterval(timer)
    timer = null
  }
}

// =========================
// 触摸滑动
// =========================

function handleTouchStart(event) {
  touchStartX =
    event.changedTouches[0].clientX

  stopAutoPlay()
}

function handleTouchEnd(event) {
  const touchEndX =
    event.changedTouches[0].clientX

  const distance =
    touchEndX - touchStartX

  if (Math.abs(distance) > 50) {
    changeSlide(
      currentSlide.value +
        (distance < 0 ? 1 : -1)
    )
  }

  startAutoPlay()
}

// =========================
// 获取数据
// =========================

async function loadHistory() {
  loading.value = true
  errorMessage.value = ''

  stopAutoPlay()

  try {
    const result = await props.loadData()

    console.log(
      `${props.title}接口返回`,
      result
    )

    if (result.code === 200) {
      slides.value = Array.isArray(result.data)
        ? result.data
        : []

      currentSlide.value = 0

      console.log(
        `${props.title}数据数量:`,
        slides.value.length
      )

      if (slides.value.length > 1) {
        startAutoPlay()
      }
    } else {
      slides.value = []

      errorMessage.value =
        result.msg || '获取数据失败'
    }
  } catch (error) {
    console.error(
      `${props.title}获取失败`,
      error
    )

    slides.value = []

    errorMessage.value =
      '数据获取失败，请稍后重试'
  } finally {
    loading.value = false
  }
}

// =========================
// 切换历史分类
// =========================

function changeCategory(category) {
  if (
    activeCategory.value?.path ===
    category.path
  ) {
    return
  }

  router.push(category.path)
}

// =========================
// 搜索
// =========================

async function confirmSearch() {
  const keyword =
    searchText.value.trim()

  if (!keyword) {
    alert('请输入关键词')
    return
  }

  submittedKeyword.value = keyword

  promptRefs.value = []

  await nextTick()

  if (!filteredPrompts.value.length) {
    alert('没有找到匹配的数据')
    return
  }

  promptRefs.value[0]?.scrollIntoView({
    behavior: 'smooth',
    block: 'center',
  })
}

function clearSearch() {
  searchText.value = ''
  submittedKeyword.value = ''
  promptRefs.value = []
}

// =========================
// 滚动到历史列表
// =========================

function scrollToPrompts() {
  document
    .querySelector('.prompt-section')
    ?.scrollIntoView({
      behavior: 'smooth',
      block: 'start',
    })
}

// =========================
// 搜索高亮
// =========================

function highlightText(text) {
  const keyword =
    submittedKeyword.value.trim()

  if (!keyword || !text) {
    return text || ''
  }

  const escapeHtml = value => {
    return String(value).replace(
      /[&<>"']/g,
      char => ({
        '&': '&amp;',
        '<': '&lt;',
        '>': '&gt;',
        '"': '&quot;',
        "'": '&#39;',
      })[char]
    )
  }

  const escapedText =
    escapeHtml(text)

  const escapedKeyword =
    keyword.replace(
      /[.*+?^${}()|[\]\\]/g,
      '\\$&'
    )

  return escapedText.replace(
    new RegExp(
      escapedKeyword,
      'gi'
    ),
    match =>
      `<mark class="search-highlight">${match}</mark>`
  )
}

const goHistoryDetail = (item) => {
  if (!item) {
    return
  }
  router.push({
    name: 'HistoryDetail',
    query: {
      item: JSON.stringify(item)
    }
  })
}

// =========================
// 生命周期
// =========================

onMounted(() => {
  loadHistory()
})

onUnmounted(() => {
  stopAutoPlay()
})
</script>

<template>
  <div class="history-page">

    <!-- ==================== -->
    <!-- 顶部 -->
    <!-- ==================== -->

    <section class="history-header">

      <img class="logo"
        :src="logo"
        :alt="logo"/>

      <div class="history-tabs">

        <button
          v-for="category in categories"
          :key="category.key"
          type="button"
          :class="{
            active:
              activeCategory?.key ===
              category.key
          }"
          @click="
            changeCategory(category)
          "
        >
          {{ category.name }}
        </button>

      </div>

    </section>

    <!-- ==================== -->
    <!-- 搜索 -->
    <!-- ==================== -->

    <section class="search-section">

      <form
        class="search-box"
        @submit.prevent="
          confirmSearch
        "
      >

        <input
          v-model="searchText"
          type="text"
          :placeholder="
            `搜索${title}事件`
          "
        />

        <button type="submit">
          搜索
        </button>

      </form>

    </section>

    <!-- ==================== -->
    <!-- 加载 -->
    <!-- ==================== -->

    <section
      v-if="loading"
      class="loading-container"
    >
      <div class="loading-spinner"></div>

      <p>
        正在加载{{ title }}...
      </p>
    </section>

    <!-- ==================== -->
    <!-- 错误 -->
    <!-- ==================== -->

    <section
      v-else-if="errorMessage"
      class="error-container"
    >

      <p>
        {{ errorMessage }}
      </p>

      <button
        type="button"
        @click="loadHistory"
      >
        重新加载
      </button>

    </section>

    <!-- ==================== -->
    <!-- 轮播 -->
    <!-- ==================== -->

    <section
      v-else-if="slideCount > 0"
      class="carousel"

      @mouseenter="
        stopAutoPlay
      "

      @mouseleave="
        startAutoPlay
      "

      @touchstart.passive="
        handleTouchStart
      "

      @touchend.passive="
        handleTouchEnd
      "
    >

      <!-- 上一张 -->

      <button
        v-if="slideCount > 1"
        class="carousel-arrow prev"
        type="button"
        aria-label="上一张"
        @click="
          changeSlide(
            currentSlide - 1
          )
        "
      >
        ‹
      </button>

      <!-- 当前内容 -->

      <div
        :key="currentSlide"
        class="carousel-content"
        @click="goHistoryDetail(slides[currentSlide])"
      >

        <span class="carousel-tag">
          {{ tag }}
        </span>

        <h2>
          {{
            slides[currentSlide]?.title
          }}
        </h2>

        <p>
          {{
            slides[currentSlide]
              ?.description
          }}
        </p>

      </div>

      <!-- 下一张 -->

      <button
        v-if="slideCount > 1"
        class="carousel-arrow next"
        type="button"
        aria-label="下一张"
        @click="
          changeSlide(
            currentSlide + 1
          )
        "
      >
        ›
      </button>

      <!-- ==================== -->
      <!-- 轮播游标 -->
      <!-- ==================== -->

      <div
        v-if="slideCount > 1"
        class="carousel-dots"
      >

        <button
          v-for="(item, index) in slides"
          :key="
            item.id ||
            item.title ||
            index
          "
          type="button"
          class="carousel-dot"
          :class="{
            active:
              currentSlide === index
          }"
          :aria-label="
            `第 ${index + 1} 张`
          "
          @click.stop="
            changeSlide(index)
          "
        ></button>

      </div>

    </section>

    <!-- ==================== -->
    <!-- 没有数据 -->
    <!-- ==================== -->

    <section
      v-else
      class="empty-tip"
    >
      暂无{{ title }}数据
    </section>

    <!-- ==================== -->
    <!-- 历史列表 -->
    <!-- ==================== -->

    <section
      id="prompts"
      class="prompt-section"
    >

      <div class="section-heading">

        <div>

          <h2>
            {{ title }}
          </h2>

          <p
            v-if="submittedKeyword"
          >
            搜索结果：
            {{ submittedKeyword }}
          </p>

        </div>

        <div class="heading-actions">

          <span class="result-count">
            {{ filteredPrompts.length }}
            条
          </span>

          <button
            v-if="submittedKeyword"
            class="clear-button"
            type="button"
            @click="clearSearch"
          >
            清除搜索
          </button>

        </div>

      </div>

      <!-- 列表 -->

      <div
        v-if="
          filteredPrompts.length
        "
        class="prompt-list"
      >

        <div
          v-for="
            (item, index)
            in filteredPrompts
          "
          :key="
            item.id ||
            item.title ||
            index
          "
          :ref="
            el =>
              (promptRefs[index] = el)
          "
          class="prompt-item"
          @click="goHistoryDetail(item)"
        >

          <div class="prompt-info">

            <h3
              v-html="
                highlightText(
                  item.title
                )
              "
            ></h3>

            <p
              v-html="
                highlightText(
                  item.description
                )
              "
            ></p>

          </div>

          <button
            class="copy-button"
            type="button"
            @click="goHistoryDetail(item)"
          >
            {{ item.button }}
          </button>

        </div>

      </div>

      <div
        v-else
        class="empty-tip"
      >
        没有找到匹配的历史事件。
      </div>

    </section>

    <!-- ==================== -->
    <!-- Footer -->
    <!-- ==================== -->

    <footer class="footer">
      Treasure · 让知识更有价值
    </footer>

  </div>
</template>

<style scoped>
* {
  box-sizing: border-box;
}

.history-page {
  min-height: 100vh;
  color: #263247;
  background: #f7f8fa;
}

/* ==================== */
/* Header */
/* ==================== */

.history-header {
  padding: 0px 20px 0;
  text-align: center;
}

.logo {
  margin-bottom: 20px;
  height: 200px;
}

/* ==================== */
/* Tabs */
/* ==================== */

.history-tabs {
  display: flex;
  justify-content: center;
  gap: 8px;
  max-width: 1100px;
  margin: 0 auto;
  overflow-x: auto;
  scrollbar-width: none;
}

.history-tabs::-webkit-scrollbar {
  display: none;
}

.history-tabs button {
  flex-shrink: 0;
  padding: 9px 22px;
  color: #64748b;
  background: #fff;
  border: 1px solid #e5e7eb;
  border-radius: 22px;
  font-size: 14px;
  cursor: pointer;
  transition: all 0.2s;
}

.history-tabs button:hover {
  color: #4776e6;
  border-color: #b7c9f7;
}

.history-tabs button.active {
  color: #fff;
  background: #4776e6;
  border-color: #4776e6;
  box-shadow:
    0 4px 12px
    rgb(71 118 230 / 20%);
}

/* ==================== */
/* Search */
/* ==================== */

.search-section {
  padding: 25px 20px 0;
}

.search-box {
  position: relative;
  display: flex;
  align-items: center;
  width: 90%;
  max-width: 900px;
  margin: 0 auto;
}

.search-box input {
  width: 100%;
  height: 60px;
  padding: 0 125px 0 22px;
  color: #263247;
  background: #fff;
  border: 2px solid #dfe3ea;
  border-radius: 14px;
  outline: none;
  font-size: 16px;
  box-shadow:
    0 6px 24px
    rgb(38 50 71 / 7%);
}

.search-box input:focus {
  border-color: #4776e6;
}

.search-box button {
  position: absolute;
  top: 8px;
  right: 8px;
  bottom: 8px;
  width: 105px;
  color: #fff;
  background: #4776e6;
  border: none;
  border-radius: 9px;
  font-size: 15px;
  cursor: pointer;
}

/* ==================== */
/* Loading */
/* ==================== */

.loading-container {
  max-width: 1100px;
  min-height: 270px;
  margin: 35px auto 0;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  color: #8a94a6;
  background: #fff;
  border-radius: 16px;
}

.loading-spinner {
  width: 35px;
  height: 35px;
  margin-bottom: 15px;
  border: 3px solid #e5e7eb;
  border-top-color: #4776e6;
  border-radius: 50%;
  animation: loading 0.8s linear infinite;
}

@keyframes loading {
  to {
    transform: rotate(360deg);
  }
}

/* ==================== */
/* Error */
/* ==================== */

.error-container {
  max-width: 1100px;
  min-height: 220px;
  margin: 35px auto 0;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  color: #8a94a6;
  background: #fff;
  border-radius: 16px;
}

.error-container button {
  margin-top: 10px;
  padding: 8px 18px;
  color: #fff;
  background: #4776e6;
  border: none;
  border-radius: 6px;
  cursor: pointer;
}

/* ==================== */
/* Carousel */
/* ==================== */

.carousel {
  position: relative;
  max-width: 1100px;
  min-height: 270px;
  margin: 35px auto 0;
  padding: 36px 70px 55px;
  overflow: hidden;
  color: #fff;
  background:
    linear-gradient(
      120deg,
      #4776e6,
      #7559c9
    );
  border-radius: 16px;
}

.carousel-content {
  animation: slide-in 0.35s ease;
  cursor: pointer;
}

@keyframes slide-in {
  from {
    opacity: 0.6;
    transform: translateX(35px);
  }

  to {
    opacity: 1;
    transform: translateX(0);
  }
}

.carousel-tag {
  font-size: 11px;
  letter-spacing: 2px;
  opacity: 0.8;
}

.carousel-content h2 {
  margin: 18px 0 10px;
  font-size: 28px;
}

.carousel-content p {
  margin: 0;
  color: #e5eaff;
  font-size: 14px;
  line-height: 1.8;
}

.carousel-button {
  margin-top: 22px;
  padding: 10px 20px;
  color: #4776e6;
  background: #fff;
  border: none;
  border-radius: 7px;
  cursor: pointer;
}

/* ==================== */
/* 左右按钮 */
/* ==================== */

.carousel-arrow {
  position: absolute;
  z-index: 2;
  top: 45%;
  width: 34px;
  height: 42px;
  color: #fff;
  background: rgb(255 255 255 / 15%);
  border: none;
  border-radius: 6px;
  font-size: 30px;
  cursor: pointer;
}

.carousel-arrow:hover {
  background: rgb(255 255 255 / 25%);
}

.carousel-arrow.prev {
  left: 18px;
}

.carousel-arrow.next {
  right: 18px;
}

/* ==================== */
/* 游标 */
/* ==================== */

.carousel-dots {
  position: absolute;
  z-index: 5;
  right: 0;
  bottom: 18px;
  left: 0;

  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;

  width: 100%;
}

.carousel-dot {
  display: block;

  width: 8px;
  height: 8px;

  margin: 0;
  padding: 0;

  background: rgb(255 255 255 / 45%);
  border: 0;
  border-radius: 50%;

  cursor: pointer;

  transition:
    width 0.25s ease,
    background 0.25s ease,
    transform 0.25s ease;
}

.carousel-dot:hover {
  background: rgb(255 255 255 / 75%);
  transform: scale(1.15);
}

.carousel-dot.active {
  width: 24px;
  background: #fff;
  border-radius: 10px;
}

/* ==================== */
/* 历史列表 */
/* ==================== */

.prompt-section {
  max-width: 1100px;
  margin: 48px auto 60px;
  padding: 0 20px;
  scroll-margin-top: 24px;
}

.section-heading {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  margin-bottom: 20px;
}

.section-heading h2 {
  margin: 0;
  font-size: 22px;
}

.section-heading p {
  margin: 8px 0 0;
  color: #8a94a6;
  font-size: 13px;
}

.heading-actions {
  display: flex;
  align-items: center;
  gap: 12px;
}

.result-count {
  color: #7c8799;
  font-size: 13px;
}

.clear-button {
  padding: 6px 10px;
  color: #4776e6;
  background: #edf2ff;
  border: none;
  border-radius: 6px;
  cursor: pointer;
}

.prompt-list {
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.prompt-item {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 16px;
  padding: 16px 18px;
  background: #fff;
  border: 1px solid #edf0f4;
  border-radius: 8px;
  cursor: pointer;
  transition: border-color 0.2s;
}

.prompt-item:hover {
  border-color: #b7c9f7;
}

.prompt-info {
  min-width: 0;
}

.prompt-info h3 {
  margin: 0 0 6px;
  color: #263247;
  font-size: 15px;
  font-weight: 600;
  overflow-wrap: anywhere;
}

.prompt-info p {
  margin: 0;
  color: #8993a4;
  font-size: 13px;
  line-height: 1.7;
  overflow-wrap: anywhere;
}

.copy-button {
  flex-shrink: 0;
  padding: 8px 18px;
  color: #fff;
  background: #4776e6;
  border: none;
  border-radius: 6px;
  cursor: pointer;
}

/* ==================== */
/* 空数据 */
/* ==================== */

.empty-tip {
  padding: 35px 15px;
  color: #8a94a6;
  text-align: center;
  background: #fff;
  border-radius: 8px;
}

/* ==================== */
/* Footer */
/* ==================== */

.footer {
  padding: 25px 15px;
  color: #9aa3b2;
  background: #fff;
  text-align: center;
  font-size: 12px;
  border-top: 1px solid #eee;
}

/* ==================== */
/* 搜索高亮 */
/* ==================== */

:deep(.search-highlight) {
  padding: 1px 3px;
  color: #b45309;
  background: #fef08a;
  border-radius: 3px;
  font-weight: 700;
}

/* ==================== */
/* Mobile */
/* ==================== */

@media (max-width: 768px) {

  .history-header {
    padding-top: 30px;
  }

  .logo {
    font-size: 40px;
  }

  .history-header h2 {
    font-size: 21px;
  }

  .history-tabs {
    justify-content: flex-start;
    padding: 0 5px 5px;
  }

  .history-tabs button {
    padding: 8px 16px;
    font-size: 13px;
  }

  .search-section {
    padding: 20px 14px 0;
  }

  .search-box {
    width: 100%;
  }

  .search-box input {
    height: 56px;
    padding-left: 15px;
    font-size: 14px;
  }

  .search-box button {
    width: 80px;
    font-size: 14px;
  }

  .carousel {
    min-height: 250px;
    margin: 25px 14px 0;
    padding: 32px 40px 55px;
    border-radius: 12px;
  }

  .carousel-content h2 {
    font-size: 22px;
    line-height: 1.5;
  }

  .carousel-content p {
    font-size: 13px;
  }

  .carousel-arrow.prev {
    left: 6px;
  }

  .carousel-arrow.next {
    right: 6px;
  }

  .carousel-dots {
    bottom: 15px;
  }

  .prompt-section {
    margin-top: 35px;
    padding: 0 14px;
  }

  .prompt-item {
    padding: 13px;
  }

  .copy-button {
    padding: 7px 12px;
  }
}

@media (max-width: 500px) {

  .carousel {
    padding-right: 35px;
    padding-left: 35px;
  }

  .carousel-content h2 {
    font-size: 20px;
  }

  .carousel-content p {
    font-size: 12px;
  }
}
</style>
