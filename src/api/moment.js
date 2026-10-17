import request from "./request";

export function getMomentList(page = 1, size = 10, type = 'all') {
  return request.get("api/moments/list",{
    params : {page,size, type}
  })
}
