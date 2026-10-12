<script setup>
import { ref, onMounted } from 'vue';
import { getMomentList } from '@/api/moment';
import { isLogin } from '@/api/request';
import { useRouter } from 'vue-router';
import MomentItem from '@/components/MomentItem.vue';

const router = useRouter()
const moments = ref([])
const loading = ref(false)
const errorMsg = ref("");

async function loadMoments() {
  if (!isLogin()) {
    await router.push("/login");
    return;
  }
  loading.value = true;
  errorMsg.value = "";
  try {
    const result = await getMomentList(1, 10);
    console.log("getMomentList", result)
    if (result.code === 200) {
      moments.value = result.data.momentList || [];
    } else {
      errorMsg.value = result.msg || " 获取朋友圈失败";
    }
  } catch (error) {
    errorMsg.value = error.msg || " 获取朋友圈失败";
  } finally {
    loading.value = false;
  }
}

onMounted(() => { loadMoments() })
</script>

<template>
  <div class="page">
    <div class="header">
      <h1>朋友圈</h1>
    </div>
    <div v-if="loading">
        正在加载...
    </div>
    <div v-else-if="errorMsg" class="error">
      {{ errorMsg }}
    </div>
    <div v-else>
      <MomentItem v-for="moment in moments" :key="moment.id" :moment="moment" />
      <div v-if="moments.length === 0" class="empty">暂无朋友圈</div>
    </div>
  </div>
</template>

<style scoped>
.page {
  min-height: 100vh;

  padding: 20px;

  background: #f5f5f5;
}

.header {
  width: 640px;

  margin: 0 auto 20px;

  display: flex;
  justify-content: space-between;
  align-items: center;
}

.header h1 {
  margin: 0;
}

.header button {
  padding: 8px 15px;
}


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

.time {
  color: #999;
  font-size: 14px;
}

.error {
  width: 640px;
  margin: auto;

  color: red;
}

.empty {
  text-align: center;
  color: #999;
}
</style>
