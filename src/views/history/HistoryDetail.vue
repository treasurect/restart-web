<script setup>
import { ref, computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'

const route = useRoute()
const router = useRouter()

// 接收跳转参数
const item = computed(() => {
  try {
    const value = route.query.item

    if (!value) return {}

    return JSON.parse(
      Array.isArray(value) ? value[0] : value
    )
  } catch (error) {
    console.error('解析历史详情失败：', error)
    return {}
  }
})

// 返回上一页
const goBack = () => {
  router.back()
}
</script>

<template>
  <div class="history-detail">

    <!-- 顶部 -->
    <header class="detail-header">
      <button class="back-button" @click="goBack">
        ← 返回
      </button>

      <h1>{{ item.title || '历史详情' }}</h1>
    </header>

    <!-- 描述 -->
    <section v-if="item.description" class="description">
      {{ item.description }}
    </section>

    <!-- 图片 -->
    <section v-if="item.imageList?.length" class="image-grid">
      <img
        v-for="(image, index) in item.imageList"
        :key="image + index"
        :src="image"
        :alt="`${item.title || '历史图片'} ${index + 1}`"
        loading="lazy"
      />
    </section>

    <!-- 正文 -->
    <article v-if="item.content" class="content">
      {{ item.content }}
    </article>

    <div v-if="!item.title && !item.content" class="empty">
      暂无历史详情
    </div>

  </div>
</template>

<style scoped>
.history-detail {
  max-width: 1100px;
  margin: 0 auto;
  padding: 24px;
  color: #333;
  box-sizing: border-box;
}

.detail-header {
  display: flex;
  align-items: center;
  gap: 16px;
  margin-bottom: 20px;
}

.detail-header h1 {
  margin: 0;
  font-size: 28px;
  line-height: 1.5;
}

.back-button {
  flex-shrink: 0;
  padding: 8px 12px;
  border: 1px solid #ddd;
  border-radius: 6px;
  background: #fff;
  cursor: pointer;
}

.description {
  margin-bottom: 24px;
  padding: 16px;
  border-radius: 8px;
  background: #f7f7f7;
  color: #666;
  font-size: 14px;
  line-height: 1.8;
}

.image-grid {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 12px;
  margin-bottom: 28px;
}

.image-grid img {
  display: block;
  width: 100%;
  aspect-ratio: 4 / 3;
  object-fit: cover;
  border-radius: 8px;
  background: #eee;
}

.content {
  font-size: 16px;
  line-height: 2;
  white-space: pre-line;
  overflow-wrap: anywhere;
}

.empty {
  padding: 60px 0;
  text-align: center;
  color: #999;
}

@media (max-width: 600px) {
  .history-detail {
    padding: 14px;
  }

  .detail-header {
    align-items: flex-start;
    gap: 10px;
  }

  .detail-header h1 {
    font-size: 21px;
  }

  .image-grid {
    grid-template-columns: repeat(2, minmax(0, 1fr));
    gap: 8px;
  }

  .content {
    font-size: 15px;
  }
}
</style>
