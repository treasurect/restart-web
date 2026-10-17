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

const curMenu = ref("all")
const menuList = [
  {
    key: 'all',
    name: '全部',
    icon: '◉',
    type: 'all'
  },
  {
    key: 'mine',
    name: '我的发布',
    icon: '●',
    type: 'mine'
  },
  {
    key: 'related',
    name: '与我有关',
    icon: '◎',
    type: 'related'
  },
  {
    key: 'latest',
    name: '最近发布',
    icon: '◷',
    type: 'latest'
  }
];

async function loadMoments(type = 'all') {
  if (!isLogin()) {
    await router.push("/login");
    return;
  }
  loading.value = true;
  errorMsg.value = "";
  try {
    const result = await getMomentList(1, 10, type);
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

async function onMenuClick(menu) {
  curMenu.value = menu.type
  await loadMoments(curMenu.value)
}

onMounted(() => { loadMoments(curMenu.value) })

</script>

<template>
  <div class="page">
    <aside class="sidebar">
      <nav
        v-for="menu in menuList"
        :key="menu.key"
        class="menu-item"
        :class="{active:curMenu === menu.key}"
        @click="onMenuClick(menu)">
        <span class="menu-icon">{{ menu.icon }}</span>
        <span class="menu-name">{{ menu.name }}</span>
      </nav>
    </aside>
    <main class="content">
      <div class="header">
        <h1>{{menuList.find(item => item.key === curMenu.type)?.name}}</h1>
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
    </main>
  </div>
</template>

<style scoped>

/* =========================
   页面
   ========================= */

.page {
  width: 100%;
  height: 100vh;

  overflow: hidden;

  background: #f5f5f5;
}


/* =========================
   左侧
   ========================= */

.sidebar {

  position: fixed;

  left: 0;
  top: 100px;
  bottom: 0;

  width: 220px;

  background: #fff;

  border-right: 1px solid #e5e5e5;

  z-index: 100;
}

/* 菜单 */

.menu {
  padding: 15px 10px;
}


/* 菜单项 */

.menu-item {

  height: 50px;

  display: flex;

  align-items: center;

  padding: 0 15px;

  margin-bottom: 5px;

  border-radius: 8px;

  cursor: pointer;

  color: #555;

  transition: all 0.2s;
}


.menu-item:hover {

  background: #f5f5f5;

}


/* 当前选中 */

.menu-item.active {

  background: #eaf3ff;

  color: #1677ff;

  font-weight: 600;

}


/* 图标 */

.menu-icon {

  width: 35px;

  font-size: 18px;

  text-align: center;

}


/* 名称 */

.menu-name {

  margin-left: 8px;

}


/* =========================
   右侧内容
   ========================= */

.content {

  margin-left: 220px;

  height: 100vh;

  overflow-y: auto;

  box-sizing: border-box;

  padding: 20px 30px;
}


/* 顶部 */

.header {

  width: 640px;

  margin: 0 auto 20px;

}


.header h1 {

  margin: 0;

}


/* =========================
   加载
   ========================= */

.loading {

  width: 640px;

  margin: 50px auto;

  text-align: center;

  color: #999;

}


/* =========================
   错误
   ========================= */

.error {

  width: 640px;

  margin: 30px auto;

  color: red;

}


/* =========================
   空数据
   ========================= */

.empty {

  width: 640px;

  margin: 50px auto;

  text-align: center;

  color: #999;

}


/* =========================
   滚动条
   ========================= */

.content::-webkit-scrollbar {

  width: 8px;

}


.content::-webkit-scrollbar-thumb {

  background: #ccc;

  border-radius: 4px;

}


.content::-webkit-scrollbar-track {

  background: transparent;

}


/* =========================
   移动端
   ========================= */

@media (max-width: 600px) {

  .sidebar {

    width: 180px;

  }

  .content {

    margin-left: 180px;

    padding: 15px;

  }

}

</style>
