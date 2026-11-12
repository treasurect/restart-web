import request from "./request";

export function getCarouselList() {
  return request.get("api/ext/carousel/list");
}
