<script setup>
import {BASE_URL} from '@/api/request';
const props = defineProps({
  moment: {
    type:Object,
    required:true
  }
});
console.log("图片URL：", props.moment.images)
</script>

<template>
  <div class="moment">
    <h2>{{ moment.username || "未知用户" }}</h2>
    <p class="content">{{ moment.content }}</p>
    <div
        v-if="moment.images && moment.images.length >0"
        class="images">
        <img
          v-for="(image,index) in moment.images"
          :key="index"
          :src="BASE_URL + image"
          alt="朋友圈图片">
    </div>
    <p class="time">
      {{ moment.createdAt }}
    </p>
  </div>
</template>

<style scoped>

.moment {
    box-sizing: border-box;

    width: 640px;

    margin: 0 auto 20px;
    padding: 20px;

    background: white;

    border: 1px solid #ddd;
    border-radius: 10px;
}

.moment h2 {
    margin-top: 0;
}

.content {
    line-height: 1.6;
}

.images {
    display: flex;
    flex-wrap: wrap;
    gap: 10px;

    margin-top: 15px;
}

.images img {
    width: 190px;
    height: 190px;

    object-fit: cover;

    border-radius: 8px;
}

.time {
    margin-top: 15px;

    color: #999;
    font-size: 14px;
}

</style>
