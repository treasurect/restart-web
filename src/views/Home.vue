<script setup>
import HistoryPage from '@/components/HistoryPage.vue'
import { getChinaHistory } from '@/api/history'
</script>

<template>
  <HistoryPage
    title="中国历史"
    tag="CHINESE HISTORY"
    :load-data="getChinaHistory"
  />
</template>
