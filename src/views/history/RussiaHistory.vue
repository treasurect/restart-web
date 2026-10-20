<script setup>
import HistoryPage from '@/components/HistoryPage.vue'
import { getRussiaHistory } from '@/api/history'
</script>

<template>
  <HistoryPage
    title="俄罗斯历史"
    tag="RUSSIA HISTORY"
    :load-data="getRussiaHistory"
  />
</template>
