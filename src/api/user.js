import request from "./request";

export function loginPwd(username, password) {
  return request.post("api/user/loginPwd",{username,password});
}

export function getUserInfo() {
  return request.get("/api/user/info")
}

export function updateUserInfo(data) {
  return request.post("/api/user/update", data);
}
