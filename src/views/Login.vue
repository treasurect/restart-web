<script setup>

import { ref } from "vue";
import { loginPwd } from "../api/user";
import { saveToken } from "../api/request";
import { useRouter } from "vue-router";

const router = useRouter();
const username = ref("");
const password = ref("");
const message = ref("");
const loading = ref(false);

async function login() {
  if(username.value.trim() === "") {
    message.value = "请输入用户名"
    return;
  }
  if(password.value.trim() === ""  || password.value.length < 6 || password.value.length > 18) {
    message.value = "请输入符合规则的密码"
    return;
  }
  loading.value = true;
  message.value = "正在登录"
  try {
    const result = await loginPwd(username.value.trim(),password.value.trim());
    if(result.code === 200) {
      const token = result.data.token;
      saveToken(token);
      message.value = "登录成功"
      await router.push("/")
    } else {
      message.value = result.message || "登录请求失败";
    }
  } catch(error) {
     message.value =
            error.message || "登录请求失败";
  } finally {
    loading.value = false;
  }
}
</script>

<template>
  <div class="login-page">
    <div class="login-box">
      <h1>登录</h1>
      <input
        v-model="username"
        type="text"
        placeholder="请输入用户名">
      <input
          v-model="password"
          type="password"
          placeholder="请输入密码">
        <button
          @click="login"
          :disabled="loading">
          {{ loading ? "登录中..." : "登录" }}
        </button>
        <p class="message">
          {{ message }}
        </p>
    </div>
  </div>
</template>

<style scoped>
  .login-page{
    min-height: 100vh;
    display: flex;
    justify-content: center;
    align-items: center;
    background: #f5f5f5;
  }
  .login-box {
    width: 360px;
    padding: 30px;

    background: white;

    border-radius: 10px;
}

.login-box h1 {
    margin-bottom: 25px;
    text-align: center;
}

.login-box input {
    box-sizing: border-box;

    width: 100%;

    margin-bottom: 15px;
    padding: 10px;

    border: 1px solid #ddd;
    border-radius: 5px;
}

.login-box button {
    width: 100%;
    padding: 10px;

    border: none;
    border-radius: 5px;

    cursor: pointer;
}

.login-box button:disabled {
    cursor: not-allowed;
}

.message {
    text-align: center;
}
</style>
