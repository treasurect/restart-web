<script setup>
import HistoryPage from '@/components/HistoryPage.vue'
import { getEuropeHistory } from '@/api/history'
</script>

<template>
  <HistoryPage
    title="欧洲历史"
    tag="EUROPEAN HISTORY"
    :load-data="getEuropeHistory"
  />
</template>
