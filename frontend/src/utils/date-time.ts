import i18n from '@/i18n';
import { TranslateResult } from 'vue-i18n';

const SECONDS_IN_MINUTE = 60;
const SECONDS_IN_HOUR = 60 * SECONDS_IN_MINUTE;
const SECONDS_IN_DAY = 24 * SECONDS_IN_HOUR;
const MAX_DAYS_IN_MONTH = 31;
const MAX_DAYS_IN_TWO_MONTHS = 62;
const DAYS_IN_YEAR = 365;
const DAYS_IN_TWO_YEARS = 730;

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

/**
 * return an object containing the days, hours, minutes, and seconds
 * equal to an input number of seconds
 * @param sec number of seconds input
 * @returns {days, hours, minutes, seconds} object with date data
 */
export function daysHoursMonthsSeconds(sec: number):
{ days: number, hours: number, minutes: number, seconds: number } {
  const days = Math.floor(sec/(SECONDS_IN_DAY));
  const hours = Math.floor(sec/(SECONDS_IN_HOUR) % 24);
  const minutes = Math.floor(sec/(SECONDS_IN_MINUTE)) % 60;
  const seconds = sec % 60;
  return { days, hours, minutes, seconds };
}

/**
 * get a formatted string equal to the amount of time given
 * an input number of seconds
 * @param sec input number of seconds
 * @returns string in format of '99d 11h 59m 59s'
 */
export function secondsToDDHHMMSS (sec: number) {
  const {days, hours, minutes, seconds} = daysHoursMonthsSeconds(sec);

  return `${days !== 0 && days.toFixed(0) + 'd ' || ''}` + `${hours !== 0 && ('0' + hours).slice(-2) + 'h ' || ''}` +
    `${minutes !== 0 &&('0' + minutes).slice(-2) + 'm ' || ''}` + `${seconds !== 0 && ('0' + seconds).slice(-2) + 's' || ''}`;
}

/**
 * get a string value of the relative timespan based on
 * leading specificity, i.e. 8 months and 15 mins would output
 * just 8 months.
 * @param sec input number of seconds
 * @returns string in format of `${value} ${span-of-time}`.
 * ex: '4 months' or '8 days'
 */
export function secondsToRelativeAge (sec: number): TranslateResult {
  const {days, hours, minutes, seconds} = daysHoursMonthsSeconds(sec);

  if (days > DAYS_IN_TWO_YEARS) {
    return `${Math.floor(days / DAYS_IN_YEAR)} ${i18n.t('dateTime.years')}`;
  }
  if (days > DAYS_IN_YEAR) {
    return `1 ${i18n.t('dateTime.year')}`;
  }
  if (days > MAX_DAYS_IN_TWO_MONTHS) {
    return `${Math.floor(days / MAX_DAYS_IN_MONTH)} ${i18n.t('dateTime.months')}`;
  }
  if (days > MAX_DAYS_IN_MONTH) {
    return `1 ${i18n.t('dateTime.month')}`;
  }
  if (days > 1) {
    return `${days.toFixed(0)} ${i18n.t('dateTime.days')}`;
  }
  if (days === 1) {
    return `${days} ${i18n.t('dateTime.day')}`;
  }
  if (hours > 1) {
    return `${hours.toFixed(0)} ${i18n.t('dateTime.hours')}`;
  }
  if (hours === 1) {
    return `${hours} ${i18n.t('dateTime.hour')}`;
  }
  if (minutes > 1) {
    return `${minutes.toFixed(0)} ${i18n.t('dateTime.minutes')}`;
  }
  if (minutes === 1) {
    return `${minutes} ${i18n.t('dateTime.minute')}`;
  }
  return `${seconds.toFixed(0)} ${i18n.t('dateTime.seconds')}`;
}

export function staminaToMinutes(stamina: number) {
  return stamina * 5;
}

export function staminaToHours(stamina: number) {
  return staminaToMinutes(stamina) / 60;
}
