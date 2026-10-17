import request from "./request";

export function getAlbumList() {
  return request.get("api/album/list")
}
