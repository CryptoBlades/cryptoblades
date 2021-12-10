<template>
  <div class="character-summary">
    <div class="char-img">
      <img src="../../assets/new-ui/character/raid-CB_monsters_HellbornShaman.png" alt="character-default">
    </div>
    <div class="char-info">
      <div class="icon-frame-sm active"><img src="../../assets/new-ui/icon-alien-fire.png" alt="character"></div>
      <div class="name-meta">
        <div class="char-name">Azkul Emtar</div>
        <div class="char-meta">
          <ul>
            <li>Hellborn Shaman</li>
            <li>Fire Element</li>
            <li>+240 EXP</li>
          </ul>
        </div>

        <div class="char-bio">{{ bio }}</div>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'CharacterSummary',
  data() {
    return {
      bio: 'Messenger ravens flood the skies with news of the Seers visions. ' +
        'Heralds are heard throughout the cities and towns proclaiming. ' +
        '“All ye that are able of body and strong of heart are called upon to serve in the kings legion to combat a new enemy”'
    };
  },
};
</script>

<style scoped>
.character-summary {
  display: flex;
}
.character-summary .char-info {
  padding-top: 70px;
  margin-left: 30px;
  display: flex;
}
.character-summary .name-meta {
  padding-left: 18px;
}
.character-summary .char-name {
  font-family: 'Trajan';
  color: #EDCD90;
  font-size: 30px;
  font-weight: bold;
}
.character-summary .char-meta {
  margin-bottom: 23px;
}
.character-summary .char-meta ul {
  list-style-type: none;
  margin: 0;
  padding: 0;
}
.character-summary .char-meta ul li {
  display: inline-block;
  border-right: 1px solid #7F8693;
  padding-right: 15px;
  margin-right: 15px;
  line-height: 14px;
  color: #EDCD90;
}
.character-summary .char-meta ul li:last-child {
  margin-right: 0;
  padding-right: 0;
  border-right: 0;
}
.character-summary .char-progress-bar {
  height: 5px;
}
.character-summary .char-progress-bar .percent {
  width: 35%;
}

.char-bio {
  max-width: 460px;
  color: #9D98A1;
  font-size: 15px;
}

</style>
