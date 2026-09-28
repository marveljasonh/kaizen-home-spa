// toWIB shifts a UTC timestamp by +7 h — useful for midnight boundary math
// via .getUTCFullYear()/.getUTCMonth()/.getUTCDate() calls.
// Do NOT pass its return value to toLocaleDateString without a timeZone option;
// that would double-offset in WIB browsers.
export const toWIB = (utcString: string): Date => {
  const date = new Date(utcString);
  return new Date(date.getTime() + 7 * 60 * 60 * 1000);
};

export const formatWIBTime = (utcString: string): string => {
  return new Date(utcString).toLocaleTimeString('id-ID', {
    hour: '2-digit',
    minute: '2-digit',
    hour12: false,
    timeZone: 'Asia/Jakarta',
  });
};

export const formatWIBDate = (utcString: string): string => {
  return new Date(utcString).toLocaleDateString('id-ID', {
    day: 'numeric',
    month: 'long',
    year: 'numeric',
    timeZone: 'Asia/Jakarta',
  });
};

export const formatWIBDateTime = (utcString: string): string => {
  return `${formatWIBDate(utcString)}, ${formatWIBTime(utcString)} WIB`;
};
