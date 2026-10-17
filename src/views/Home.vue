<script setup>
import { ref, computed, nextTick, onMounted, onUnmounted } from 'vue'
import promptsData from '@/data/dynasties_list.json'

const searchText = ref('')
const submittedKeyword = ref('')
const currentSlide = ref(0)
const promptRefs = ref([])

const slides = promptsData
const slideCount = slides.length

let timer = null
let touchStartX = 0

// 搜索提示词
const filteredPrompts = computed(() => {
  const keyword = submittedKeyword.value.trim().toLowerCase()

  if (!keyword) return promptsData

  return promptsData.filter(item =>
    `${item.title} ${item.description}`
      .toLowerCase()
      .includes(keyword),
  )
})

// 切换轮播
function changeSlide(index) {
  if (!slideCount) return

  currentSlide.value = (index + slideCount) % slideCount
}

// 开始自动轮播
function startAutoPlay() {
  stopAutoPlay()

  if (slideCount > 1) {
    timer = setInterval(() => {
      changeSlide(currentSlide.value + 1)
    }, 4000)
  }
}

// 停止自动轮播
function stopAutoPlay() {
  if (timer) {
    clearInterval(timer)
    timer = null
  }
}

// 触摸开始
function handleTouchStart(event) {
  touchStartX = event.changedTouches[0].clientX
  stopAutoPlay()
}

// 触摸结束
function handleTouchEnd(event) {
  const touchEndX = event.changedTouches[0].clientX
  const distance = touchEndX - touchStartX

  if (Math.abs(distance) > 50) {
    changeSlide(currentSlide.value + (distance < 0 ? 1 : -1))
  }

  startAutoPlay()
}

// 搜索
async function confirmSearch() {
  const keyword = searchText.value.trim()

  if (!keyword) {
    alert('请输入提示词名称或关键词')
    return
  }

  submittedKeyword.value = keyword
  promptRefs.value = []

  await nextTick()

  if (!filteredPrompts.value.length) {
    alert('没有找到匹配的提示词')
    return
  }

  promptRefs.value[0]?.scrollIntoView({
    behavior: 'smooth',
    block: 'center',
  })
}

// 清空搜索
function clearSearch() {
  searchText.value = ''
  submittedKeyword.value = ''
  promptRefs.value = []
}

// 滚动到提示词列表
function scrollToPrompts() {
  document.querySelector('.prompt-section')?.scrollIntoView({
    behavior: 'smooth',
    block: 'start',
  })
}

// 复制提示词
async function copyPrompt(content) {
  try {
    await navigator.clipboard.writeText(content)
    alert('复制成功')
  } catch {
    alert('复制失败，请检查浏览器权限或使用 HTTPS')
  }
}

onMounted(startAutoPlay)
onUnmounted(stopAutoPlay)

// 高亮搜索关键词
function highlightText(text) {
  const keyword = submittedKeyword.value.trim()

  if (!keyword || !text) return text || ''

  const escapeHtml = value =>
    String(value).replace(/[&<>"']/g, char => ({
      '&': '&amp;',
      '<': '&lt;',
      '>': '&gt;',
      '"': '&quot;',
      "'": '&#39;',
    })[char])

  const escapedText = escapeHtml(text)
  const escapedKeyword = keyword.replace(
    /[.*+?^${}()|[\]\\]/g,
    '\\$&',
  )

  return escapedText.replace(
    new RegExp(escapedKeyword, 'gi'),
    match => `<mark class="search-highlight">${match}</mark>`,
  )
}

const openDetail = (item)=> alert(item.content)
</script>

<template>
  <div class="home-page">
    <main id="home">
      <!-- 搜索区域 -->
      <section class="search-section">
        <h1 class="logo">Treasure</h1>

        <form class="search-box" @submit.prevent="confirmSearch">
          <input
            v-model="searchText"
            type="text"
            placeholder="输入关键词，快速查找朝代大事件"
            aria-label="搜索提示词"
          />

          <button type="submit">确认</button>
        </form>
      </section>

      <!-- 轮播区域 -->
      <section
        v-if="slideCount"
        class="carousel"
        @mouseenter="stopAutoPlay"
        @mouseleave="startAutoPlay"
        @touchstart.passive="handleTouchStart"
        @touchend.passive="handleTouchEnd"
      >
        <button
          class="carousel-arrow prev"
          aria-label="上一张"
          @click="changeSlide(currentSlide - 1)"
        >
          ‹
        </button>

        <div :key="currentSlide" class="carousel-content" @click="openDetail(slides[currentSlide])">
          <span class="carousel-tag">PROMPT LIBRARY</span>

          <h2>{{ slides[currentSlide].title }}</h2>

          <p>{{ slides[currentSlide].description }}</p>

          <button class="carousel-button" @click="scrollToPrompts">
            {{ slides[currentSlide].button || '立即查看' }}
          </button>
        </div>

        <button
          class="carousel-arrow next"
          aria-label="下一张"
          @click="changeSlide(currentSlide + 1)"
        >
          ›
        </button>

        <div class="carousel-dots">
          <button
            v-for="(slide, index) in slides"
            :key="slide.title + index"
            :class="{ active: currentSlide === index }"
            :aria-label="`第 ${index + 1} 张`"
            @click="changeSlide(index)"
          />
        </div>
      </section>

      <!-- 提示词列表 -->
      <section id="prompts" class="prompt-section">
        <div class="section-heading">
          <div>
            <h2>朝代大事件</h2>

            <p>
              {{
                submittedKeyword
                  ? `搜索结果：${submittedKeyword}`
                  : ''
              }}
            </p>
          </div>

          <div class="heading-actions">
            <span class="result-count">
              {{ filteredPrompts.length }} 条
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

        <div v-if="filteredPrompts.length" class="prompt-list">
          <div
            v-for="(item, index) in filteredPrompts"
            :key="item.title + index"
            :ref="el => (promptRefs[index] = el)"
            class="prompt-item"
            @click="openDetail(item)"
          >
            <div class="prompt-info">
              <h3 v-html="highlightText(item.title)"></h3>
              <p v-html="highlightText(item.description)"></p>
            </div>

            <button
              class="copy-button"
              type="button"
              @click="copyPrompt(item.content)"
            >
              复制
            </button>
          </div>
        </div>

        <div v-else class="empty-tip">
          没有找到匹配的提示词，请尝试其他关键词。
        </div>
      </section>
    </main>

    <footer class="footer">
      Treasure · 让知识更有价值
    </footer>
  </div>
</template>

<style scoped>
* {
  box-sizing: border-box;
}

.home-page {
  min-height: 100vh;
  color: #263247;
  background: #f7f8fa;
}

/* 搜索区域 */
.search-section {
  padding: 55px 20px 35px;
  text-align: center;
}

.logo {
  margin: 15px 0 0;
  color: #ff8325;
  font-size: 50px;
  font-weight: 800;
  letter-spacing: 3px;
  line-height: 1.2;
}

/* 搜索框：确认按钮位于输入框内部 */
.search-box {
  position: relative;
  display: flex;
  align-items: center;
  width: 90%;
  max-width: 900px;
  margin: 35px auto 0;
}

.search-box input {
  width: 100%;
  height: 66px;
  padding: 0 145px 0 28px;
  color: #263247;
  background: #fff;
  border: 2px solid #dfe3ea;
  border-radius: 14px;
  outline: none;
  font-size: 18px;
  box-shadow: 0 6px 24px rgb(38 50 71 / 7%);
  transition: border-color 0.2s, box-shadow 0.2s;
}

.search-box input:focus {
  border-color: #4776e6;
  box-shadow: 0 6px 24px rgb(71 118 230 / 15%);
}

.search-box input::placeholder {
  color: #c6d1e6;
}

.search-box button {
  position: absolute;
  top: 12px;
  right: 12px;
  bottom: 12px;
  width: 115px;
  margin: 0;
  color: #fff;
  background: #469dfae6;
  border: none;
  border-radius: 10px;
  font-size: 18px;
  font-weight: 600;
  cursor: pointer;
  transition: background 0.2s;
}

.search-box button:hover {
  background: #3564d4;
}

/* 轮播区域 */
.carousel {
  position: relative;
  max-width: 1100px;
  min-height: 270px;
  margin: 55px auto 0;
  padding: 36px 70px 48px;
  overflow: hidden;
  color: #fff;
  background: linear-gradient(120deg, #4776e6, #7559c9);
  border-radius: 16px;
}

.carousel-content {
  animation: slide-in 0.35s ease;
  touch-action: pan-y;
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
  font-size: 14px;
  cursor: pointer;
}

.carousel-button:hover {
  background: #f0f3ff;
}

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

.prev {
  left: 18px;
}

.next {
  right: 18px;
}

.carousel-dots {
  position: absolute;
  right: 0;
  bottom: 18px;
  left: 0;
  display: flex;
  justify-content: center;
  gap: 8px;
}

.carousel-dots button {
  width: 7px;
  height: 7px;
  padding: 0;
  background: rgb(255 255 255 / 45%);
  border: none;
  border-radius: 10px;
  cursor: pointer;
  transition: width 0.2s, background 0.2s;
}

.carousel-dots button.active {
  width: 22px;
  background: #fff;
}

/* 提示词列表 */
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
  line-height: 1.6;
}

.heading-actions {
  display: flex;
  align-items: center;
  gap: 12px;
}

.result-count {
  flex-shrink: 0;
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

.copy-button:hover {
  background: #3564d4;
}

.empty-tip {
  padding: 35px 15px;
  color: #8a94a6;
  text-align: center;
  background: #fff;
  border-radius: 8px;
  font-size: 14px;
}

.footer {
  padding: 25px 15px;
  color: #9aa3b2;
  background: #fff;
  text-align: center;
  font-size: 12px;
  border-top: 1px solid #eee;
}

/* 平板和手机 */
@media (max-width: 768px) {
  .search-section {
    padding: 42px 18px 30px;
  }

  .logo {
    font-size: 46px;
  }

  .slogan {
    font-size: 14px;
  }

  .search-box {
    width: 100%;
    margin-top: 35px;
  }

  .search-box input {
    height: 62px;
    padding: 0 95px 0 16px;
    font-size: 14px;
    border-radius: 12px;
  }

  .search-box button {
    top: 6px;
    right: 6px;
    bottom: 6px;
    width: 78px;
    font-size: 15px;
    border-radius: 8px;
  }

  .carousel {
    min-height: 250px;
    margin: 35px 14px 0;
    padding: 32px 40px 48px;
    border-radius: 12px;
  }

  .carousel-content h2 {
    font-size: 23px;
    line-height: 1.5;
  }

  .carousel-content p {
    font-size: 13px;
  }

  .prev {
    left: 6px;
  }

  .next {
    right: 6px;
  }

  .prompt-section {
    margin-top: 38px;
    padding: 0 14px;
  }

  .prompt-item {
    padding: 13px;
  }
}

@media (max-width: 420px) {
  .logo {
    font-size: 40px;
  }

  .slogan {
    font-size: 12px;
  }

  .search-box input {
    padding-left: 12px;
    font-size: 13px;
  }

  .section-heading h2 {
    font-size: 19px;
  }

  .section-heading p {
    max-width: 230px;
    font-size: 12px;
  }

  .heading-actions {
    gap: 6px;
  }

  .clear-button {
    padding: 5px 7px;
    font-size: 12px;
  }

  .prompt-info p {
    font-size: 12px;
  }

  .copy-button {
    padding: 7px 12px;
  }
  /* 搜索关键词高亮 */
:deep(.search-highlight) {
  padding: 1px 3px;
  color: #b45309;
  background: #fef08a;
  border-radius: 3px;
  font-weight: 700;
}

.prompt-content {
  margin-top: 8px;
  color: #64748b;
  font-size: 13px;
  line-height: 1.7;
  overflow-wrap: anywhere;
}
}
</style>
