import axios from "axios";
export const BASE_URL = import.meta.env.VITE_API_BASE_URL || "";

const request = axios.create({
    baseURL: BASE_URL,
    timeout: 10000,
    headers: {
        "Content-Type" : "application/json"
    }
})

export function getToken() {
    return localStorage.getItem("token");
}
export function saveToken(token) {
    localStorage.setItem("token", token);
}

export function removeToken() {
    localStorage.removeItem("token");
}

export function isLogin() {
    return !!getToken();
}

request.interceptors.request.use(
    config => {
        if(isLogin()) {
            config.headers.Authorization = "Bearer " + getToken()
        }
        return config;
    },
    error => {
        return Promise.reject(error);
    }
);

request.interceptors.response.use(
    response => {
        const result = response.data;
        if(result?.code === 401) {
            removeToken();
            if(window.location.pathname !== "/login") {
                window.location.href = "/login";
            }
            return Promise.reject(new Error(result.msg || "登录已失效"));
        }
        return result;
    },
    error => {
        if(error.response?.status === 401) {
            removeToken();
            if(window.location.pathname !== "/login") {
                window.location.href = "/login";
            }
            return Promise.reject(new Error(error.msg || "登录已失效"));
        }
        const message = error.response?.data?.msg || error.message || "网络请求失败";
        return Promise.reject(new Error(message));
    }
);

export default request;
