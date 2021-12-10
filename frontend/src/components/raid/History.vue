<template>
  <table class="history">
    <tr class="history-row">
      <td class="history-cell">
        <div class="label">Report</div>
        <div class="content"><img src="../../assets/new-ui/win.png" alt="character-default"> Win</div>
      </td>
      <td class="history-cell">
        <div class="label">Boss Roll</div>
        <div class="content">23,000,000</div>
      </td>
      <td class="history-cell">
        <div class="label">Raid Roll</div>
        <div class="content">30,000,000</div>
      </td>
      <td class="history-cell">
        <div class="label">Participants</div>
        <div class="content">20,320</div>
      </td>
      <td class="history-cell">
        <div class="label">Trinket</div>
        <div class="content">ZhangTsun</div>
      </td>
      <td class="history-cell">
        <div class="label">Timestamp</div>
        <div class="content">2021-09-01 / 4:00</div>
      </td>
    </tr>

    <tr class="history-row">
      <td class="history-cell">
        <div class="label">Report</div>
        <div class="content"><img src="../../assets/new-ui/win.png" alt="character-default"> Win</div>
      </td>
      <td class="history-cell">
        <div class="label">Boss Roll</div>
        <div class="content">23,000,000</div>
      </td>
      <td class="history-cell">
        <div class="label">Raid Roll</div>
        <div class="content">30,000,000</div>
      </td>
      <td class="history-cell">
        <div class="label">Participants</div>
        <div class="content">20,320</div>
      </td>
      <td class="history-cell">
        <div class="label">Trinket</div>
        <div class="content">Diego</div>
      </td>
      <td class="history-cell">
        <div class="label">Timestamp</div>
        <div class="content">2021-09-01 / 4:00</div>
      </td>
    </tr>

    <tr class="history-row">
      <td class="history-cell">
        <div class="label">Report</div>
        <div class="content"><img src="../../assets/new-ui/loss.png" alt="character-default"> Loss</div>
      </td>
      <td class="history-cell">
        <div class="label">Boss Roll</div>
        <div class="content">54,000,000</div>
      </td>
      <td class="history-cell">
        <div class="label">Raid Roll</div>
        <div class="content">38,000,000</div>
      </td>
      <td class="history-cell">
        <div class="label">Participants</div>
        <div class="content">20,320</div>
      </td>
      <td class="history-cell">
        <div class="label">Trinket</div>
        <div class="content">KhalAzu</div>
      </td>
      <td class="history-cell">
        <div class="label">Timestamp</div>
        <div class="content">2021-09-01 / 4:00</div>
      </td>
    </tr>

    <tr class="history-row">
      <td class="history-cell">
        <div class="label">Report</div>
        <div class="content"><img src="../../assets/new-ui/win.png" alt="character-default"> Win</div>
      </td>
      <td class="history-cell">
        <div class="label">Boss Roll</div>
        <div class="content">54,000,000</div>
      </td>
      <td class="history-cell">
        <div class="label">Raid Roll</div>
        <div class="content">38,000,000</div>
      </td>
      <td class="history-cell">
        <div class="label">Participants</div>
        <div class="content">20,320</div>
      </td>
      <td class="history-cell">
        <div class="label">Trinket</div>
        <div class="content">KhalAzu</div>
      </td>
      <td class="history-cell">
        <div class="label">Timestamp</div>
        <div class="content">2021-09-01 / 4:00</div>
      </td>
    </tr>

    <tr class="history-row">
      <td class="history-cell">
        <div class="label">Report</div>
        <div class="content"><img src="../../assets/new-ui/win.png" alt="character-default"> Win</div>
      </td>
      <td class="history-cell">
        <div class="label">Boss Roll</div>
        <div class="content">54,000,000</div>
      </td>
      <td class="history-cell">
        <div class="label">Raid Roll</div>
        <div class="content">38,000,000</div>
      </td>
      <td class="history-cell">
        <div class="label">Participants</div>
        <div class="content">20,320</div>
      </td>
      <td class="history-cell">
        <div class="label">Trinket</div>
        <div class="content">KhalAzu</div>
      </td>
      <td class="history-cell">
        <div class="label">Timestamp</div>
        <div class="content">2021-09-01 / 4:00</div>
      </td>
    </tr>

  </table>
</template>

<script>
export default {
  name: 'RaidHistory',
  components: {}
};
</script>

<style scoped>
.history {
  width: 100%;
}
.history-row {
  border-bottom: 1px solid #404857;
  vertical-align: baseline;
}
.history-cell {
  padding-left: 50px;
  padding-bottom: 30px;
  padding-top: 30px;
}
.history-cell:first-child {
  padding-left: 0;
  padding-top: 0;
}
.history-cell .label {
  color: #CEC198;
  font-size: 12px;
  margin-bottom: 5px;
}
.history-cell .content {
  color: #9D98A1;
}
.history-cell .content img {
  width: 15px;
}
</style>
