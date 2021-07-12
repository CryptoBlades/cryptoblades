const SECONDS_IN_MINUTE = 60;
const SECONDS_IN_HOUR = 60 * SECONDS_IN_MINUTE;
const SECONDS_IN_DAY = 24 * SECONDS_IN_HOUR;

function formatDurationToUnit(n: number, unitNames: string[]) {
  return n.toFixed(0) + ' ' + (n.toFixed(0) === '1' ? unitNames[0] : unitNames[1]);
}

export function formatDurationFromSeconds(sec: number) {
  if (sec / SECONDS_IN_DAY >= 1) {
    return formatDurationToUnit(sec / SECONDS_IN_DAY, ['day', 'days']);
  }

  if (sec / SECONDS_IN_HOUR >= 1) {
    return formatDurationToUnit(sec / SECONDS_IN_HOUR, ['hour', 'hours']);
  }

  if (sec / SECONDS_IN_MINUTE >= 1) {
    return formatDurationToUnit(sec / SECONDS_IN_MINUTE, ['minute', 'minutes']);
  }

  return formatDurationToUnit(sec, ['second', 'seconds']);
}

export function secondsToDDHHMMSS (sec: number) {
  const days = Math.floor(sec/(60*60*24));
  const hours = Math.floor(sec/(60*60)%24);
  const minutes = Math.floor(sec/(60))%60;
  const seconds = sec%60;

  return `${days !== 0 && ('0' + days).slice(-2) + 'd ' || ''}` + `${hours !== 0 && ('0' + hours).slice(-2) + 'h ' || ''}` +
    `${minutes !== 0 &&('0' + minutes).slice(-2) + 'm ' || ''}` + `${seconds !== 0 && ('0' + seconds).slice(-2) + 's' || ''}`;
}
