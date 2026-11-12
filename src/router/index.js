import { createRouter, createWebHistory } from "vue-router";

import Login from "@/views/Login.vue";
import HomeLayout from "@/layout/HomeLayout.vue";

import Home from "@/views/Home.vue";
import Moments from "@/views/Moments.vue";
import Album from "@/views/Album.vue";
import Profile from "@/views/Profile.vue";
import DataSource from "@/views/DataSource.vue";
import AiChat from "@/views/AiChat.vue";

import EuropeHistory from "@/views/history/EuropeHistory.vue";
import USAHistory from "@/views/history/USAHistory.vue";
import RussiaHistory from "@/views/history/RussiaHistory.vue";

import { isLogin } from "@/api/request";

const router = createRouter({
  history: createWebHistory(),

  routes: [
    {
      path: "/login",
      component: Login
    },
    {
      path: "/",
      component: HomeLayout,
      redirect: "/ai-chat",
      children: [
        {
          path: "/home",
          component: Home
        },
        {
          path: "/ai-chat",
          component: AiChat
        },
        {
          path: "/data-source",
          component: DataSource
        },
        {
          path: "/moments",
          component: Moments
        },
        {
          path: "/album",
          component: Album
        },
        {
          path: "/profile",
          component: Profile
        },

        // 历史分类页面
        {
          path: "/history/europe",
          component: EuropeHistory
        },
        {
          path: "/history/usa",
          component: USAHistory
        },
        {
          path: "/history/russia",
          component: RussiaHistory
        },
        {
          path: 'history/history-detail',
          name: 'HistoryDetail',
          component: () => import('@/views/history/HistoryDetail.vue')
        }
      ]
    }
  ]
});

// 统一登录校验
router.beforeEach((to) => {
  if (to.path !== "/login" && !isLogin()) {
    return "/login";
  }

  if (to.path === "/login" && isLogin()) {
    return "/ai-chat";
  }
});

export default router;
