import request from './request'

export function getChinaHistory() {
  return request.get('/api/file/history/china')
}

export function getEuropeHistory() {
  return request.get('/api/file/history/europe')
}

export function getUSAHistory() {
  return request.get('/api/file/history/usa')
}

export function getRussiaHistory() {
  return request.get('/api/file/history/russia')
}
