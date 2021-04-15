const SECONDS_IN_MINUTE = 60;
const SECONDS_IN_HOUR = 60 * SECONDS_IN_MINUTE;
const SECONDS_IN_DAY = 24 * SECONDS_IN_HOUR;

function formatDurationToUnit(n, unitNames) {
  if (n > 1) {
    return n.toFixed(0) + ' ' + (n > 2 ? unitNames[1] : unitNames[0]);
  }
  return '';
}

export function formatDurationFromSeconds(sec) {
  if (sec / SECONDS_IN_DAY > 1) {
    return formatDurationToUnit(sec / SECONDS_IN_DAY, ['day', 'days']);
  }

  if (sec / SECONDS_IN_HOUR > 1) {
    return formatDurationToUnit(sec / SECONDS_IN_HOUR, ['hour', 'hours']);
  }

  if (sec / SECONDS_IN_MINUTE > 1) {
    return formatDurationToUnit(sec / SECONDS_IN_MINUTE, ['minute', 'minutes']);
  }

  return formatDurationToUnit(sec, ['second', 'seconds']);
}
