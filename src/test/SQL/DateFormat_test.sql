-- =============================================================================
-- Test Cases for FORMATTIMESTAMP Functions
-- =============================================================================
-- This file contains demonstration and test queries for the FORMATTIMESTAMP
-- functions defined in src/main/java/DateFormat.sql
--
-- Functions tested:
-- - FORMATTIMESTAMP(timestamp, format): Format with default locale
-- - FORMATTIMESTAMP(timestamp, format, locale): Format with specific locale
-- =============================================================================

-- Tests

select formattimestamp(current timestamp, 'EEEE, d MMM yyyy HH:mm:ss') 
 from sysibm.sysdummyu; 
 
select formattimestamp(current timestamp, 'EEEE, d MMM yyyy HH:mm:ss', 'de-DE') 
 from sysibm.sysdummyu;

with 
u(u) as (
  select * from sysibm.sysdummyu
),
locales(locale) as (
            select 'de-DE' from u
  union all select 'en-US' from u
  union all select 'hu-HU' from u
  union all select 'sv-SE' from u
  union all select 'ja-JP' from u
  union all select 'de-AT' from u
)
select locale,
       formattimestamp(current timestamp, 'EEEE, d MMMM yyyy HH:mm:ss', locale) now,
       formattimestamp(timestamp('2025-01-01-00:11:22'), 'EEEE, d MMMM yyyy HH:mm:ss', locale) 
 from locales;
 
-- Using apostrophes in the format string:
-- This is messy since both SQL and Java's DateTimeFormatter require duplicate apostrophes...
select formattimestamp(current timestamp, '''It''''s ''H ''o''''clock'' BBBB', 'en-US') 
  from sysibm.sysdummyu;
  
-- Test involving other functions from this package:
select sprintf('Heute ist %s, der %s.%s.%s, und es ist %d Uhr %s.',
               pack(ccsid 1208, formattimestamp(current timestamp, 'EEEE', 'de-DE'),
                                to_roman(day(current date)),
                                to_roman(month(current date)),
                                to_roman(year(current date)),
                                hour(current timestamp),
                                formattimestamp(current timestamp, 'BBBB', 'de-DE')))
  from sysibm.sysdummyu;

with
locales(locale) as (
  select trim(token) from table(split(
    'ar, ar-AE, ar-BH, ar-DZ, ar-EG, ar-IQ, ar-JO, ar-KW, ar-LB, ar-LY,
     ar-MA, ar-OM, ar-QA, ar-SA, ar-SD, ar-SY, ar-TN, ar-YE, be, be-BY, bg,
     bg-BG, bn-IN, ca, ca-ES, cs, cs-CZ, da, da-DK, de, de-AT, de-CH, de-DE,
     de-GR, de-LU, el, el-CY, el-GR, en, en-AU, en-BE, en-CA, en-GB, en-HK,
     en-IE, en-IN, en-MT, en-NZ, en-PH, en-SG, en-US, en-ZA, es, es-AR,
     es-BO, es-CL, es-CO, es-CR, es-CU, es-DO, es-EC, es-ES, es-GT, es-HN,
     es-MX, es-NI, es-PA, es-PE, es-PR, es-PY, es-SV, es-US, es-UY, es-VE,
     et, et-EE, fi, fi-FI, fr, fr-BE, fr-CA, fr-CH, fr-FR, fr-LU, ga, ga-IE,
     gu, gu-IN, hi, hi-IN, hr, hr-HR, hu, hu-HU, in, in-ID, is, is-IS, it,
     it-CH, it-IT, iw, iw-IL, ja, ja-JP, ja-JP-JP-#u-ca-japanese, kk, kk-KZ,
     kn, kn-IN, ko, ko-KR, lt, lt-LT, lv, lv-LV, mk, mk-MK, ml-IN, mr, mr-IN,
     ms, ms-MY, mt, mt-MT, nb-NO, nl, nl-BE, nl-NL, no, no-NO, no-NO-NY,
     or-IN, pa, pa-IN, pl, pl-PL, pt, pt-BR, pt-PT, ro, ro-RO, ru, ru-RU, sh,
     sh-CS, sk, sk-SK, sl, sl-SI, sq, sq-AL, sr, sr--#Latn, sr-BA,
     sr-BA-#Latn, sr-CS, sr-ME, sr-ME-#Latn, sr-RS, sr-RS-#Latn, sv, sv-SE,
     ta, ta-IN, te, te-IN, th, th-TH, th-TH-TH-#u-nu-thai, tr, tr-TR, uk,
     uk-UA, vi, vi-VN, zh, zh-CN, zh-HK, zh-SG, zh-TW'))
)
select locale, formattimestamp(current timestamp, 'EEEE, d MMMM yyyy HH:mm:ss', locale) as today
  from locales;

-- Made with Bob
