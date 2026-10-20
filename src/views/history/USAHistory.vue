<script setup>
import HistoryPage from '@/components/HistoryPage.vue'
import { getUSAHistory } from '@/api/history'
</script>

<template>
  <HistoryPage
    title="美国历史"
    tag="USA HISTORY"
    :load-data="getUSAHistory"
  />
</template>
