import { createRouter, createWebHistory } from "vue-router";

import Login from "@/views/Login.vue";
import HomeLayout from "@/layout/HomeLayout.vue";
import Home from "@/views/Home.vue";
import Moments from "@/views/Moments.vue";
import Album from "@/views/Album.vue";
import Profile from "@/views/Profile.vue";

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
      redirect: "/home",
      children: [
        {
          path: "/home",
          component: Home
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
    return "/moments";
  }
});

export default router;
