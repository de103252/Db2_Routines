
drop function SPRINTF(format varchar(32704), packed_data varbinary(32704)); 
create function SPRINTF(format varchar(32704), packed_data varbinary(32704)) 
returns varchar(32704)
external name
  'ADCDMST.ROUTINES:com.ibm.db2.sprintf.Sprintf.sprintf'
language java 
parameter style java 
no external action 
allow parallel 
wlm environment DBDGENVJ 
asutime no limit 
continue after failure
deterministic; 

drop function SPRINTF(locale varchar(64), format varchar(32704), packed_data varbinary(32704)); 
create function SPRINTF(locale varchar(64), format varchar(32704), packed_data varbinary(32704)) 
returns varchar(32704)
external name
  'ADCDMST.ROUTINES:com.ibm.db2.sprintf.Sprintf.sprintf'
language java 
parameter style java 
no external action 
allow parallel 
wlm environment DBDGENVJ 
asutime no limit 
continue after failure
deterministic; 

with
u as (select * from sysibm.sysdummyu),
locales(locale) as (
select 'ar_JO' from u union all
select 'fr_BE' from u union all
select 'es_ES_PREEURO' from u union all
select 'mt_MT' from u union all
select 'es_VE' from u union all
select 'bg' from u union all
select 'mr' from u union all
select 'ko' from u union all
select 'nb_NO' from u union all
select 'lv' from u union all
select 'de_DE_PREEURO' from u union all
select 'vi_VN' from u union all
select 'de_LU_PREEURO' from u union all
select 'en_US' from u union all
select 'sv_SE' from u union all
select 'mt_MT_PREEURO' from u union all
select 'sr_ME' from u union all
select 'es_BO' from u union all
select 'lv_LV_PREEURO' from u union all
select 'ar_SA' from u union all
select 'gu_IN' from u union all
select 'sk' from u union all
select 'en_MT' from u union all
select 'fi_FI' from u union all
select 'sv' from u union all
select 'cs' from u union all
select 'bn_IN' from u union all
select 'sr_BA_#Latn' from u union all
select 'el' from u union all
select 'pa' from u union all
select 'uk_UA' from u union all
select 'fr_CH' from u union all
select 'hu' from u union all
select 'ar_EG' from u union all
select 'cs_CZ' from u union all
select 'tr' from u union all
select 'pl_PL' from u union all
select 'ca_ES' from u union all
select 'sr_CS' from u union all
select 'ms_MY' from u union all
select 'fr_BE_PREEURO' from u union all
select 'es_ES' from u union all
select 'es_CO' from u union all
select 'bg_BG' from u union all
select 'sq' from u union all
select 'fr' from u union all
select 'sr_BA' from u union all
select 'es_PY' from u union all
select 'de' from u union all
select 'es_EC' from u union all
select 'es_US' from u union all
select 'fi_FI_PREEURO' from u union all
select 'ar_SD' from u union all
select 'ro_RO' from u union all
select 'en_PH' from u union all
select 'sr_ME_#Latn' from u union all
select 'de_AT_PREEURO' from u union all
select 'es_GT' from u union all
select 'en_IE_PREEURO' from u union all
select 'ru_RU' from u union all
select 'no_NO_NY' from u union all
select 'ca_ES_PREEURO' from u union all
select 'es_CL' from u union all
select 'ar_MA' from u union all
select 'ga_IE' from u union all
select 'tr_TR' from u union all
select 'fr_LU' from u union all
select 'cs_CZ_PREEURO' from u union all
select 'sq_AL' from u union all
select 'es_DO' from u union all
select 'fr_LU_PREEURO' from u union all
select 'ru' from u union all
select 'ms' from u union all
select 'iw_IL' from u union all
select 'kk' from u union all
select 'th_TH_TH_#u-nu-thai' from u union all
select 'hi' from u union all
select 'no_NO' from u union all
select 'en_AU' from u union all
select 'sv_SE_PREEURO' from u union all
select 'vi' from u union all
select 'fr_CA' from u union all
select 'de_LU' from u union all
select 'mt' from u union all
select 'it_CH' from u union all
select 'de_DE' from u union all
select 'it_IT_PREEURO' from u union all
select 'lt_LT' from u union all
select 'it_IT' from u union all
select 'en_IE' from u union all
select 'zh_SG' from u union all
select 'ro' from u union all
select 'no' from u union all
select 'pl' from u union all
select 'ja_JP' from u union all
select 'or_IN' from u union all
select 'ar_LB' from u union all
select 'zh' from u union all
select 'be_BY' from u union all
select 'es_PE' from u union all
select 'in_ID' from u union all
select 'ta' from u union all
select 'en_GB' from u union all
select 'ar_AE' from u union all
select 'ar_SY' from u union all
select 'hr_HR' from u union all
select 'kk_KZ' from u union all
select 'es_PA' from u union all
select 'sh' from u union all
select 'zh_TW' from u union all
select 'it' from u union all
select 'uk' from u union all
select 'da_DK' from u union all
select 'sk_SK_PREEURO' from u union all
select 'es_PR' from u union all
select 'lt_LT_PREEURO' from u union all
select 'en_BE' from u union all
select 'en_SG' from u union all
select 'ar_BH' from u union all
select 'pt' from u union all
select 'kn_IN' from u union all
select 'ar_YE' from u union all
select 'hi_IN' from u union all
select 'ga' from u union all
select 'sl_SI_PREEURO' from u union all
select 'et' from u union all
select 'in' from u union all
select 'es_AR' from u union all
select 'ja_JP_JP_#u-ca-japanese' from u union all
select 'es_SV' from u union all
select 'en_BE_PREEURO' from u union all
select 'pt_BR' from u union all
select 'ml_IN' from u union all
select 'be' from u union all
select 'es' from u union all
select 'is_IS' from u union all
select 'hr' from u union all
select 'lt' from u union all
select 'ta_IN' from u union all
select 'ja' from u union all
select 'is' from u union all
select 'en' from u union all
select 'nl_NL_PREEURO' from u union all
select 'ca' from u union all
select 'ar_TN' from u union all
select 'te' from u union all
select 'sl' from u union all
select 'ko_KR' from u union all
select 'mr_IN' from u union all
select 'el_CY' from u union all
select 'nl_BE_PREEURO' from u union all
select 'es_MX' from u union all
select 'zh_HK' from u union all
select 'es_HN' from u union all
select 'hu_HU' from u union all
select 'th_TH' from u union all
select 'ar_IQ' from u union all
select 'fi' from u union all
select 'mk' from u union all
select 'et_EE' from u union all
select 'ar_QA' from u union all
select 'sr__#Latn' from u union all
select 'pt_PT' from u union all
select 'ar_OM' from u union all
select 'th' from u union all
select 'sh_CS' from u union all
select 'es_CU' from u union all
select 'ar' from u union all
select 'kn' from u union all
select 'en_NZ' from u union all
select 'sr_RS' from u union all
select 'de_CH' from u union all
select 'es_UY' from u union all
select 'el_GR' from u union all
select 'gu' from u union all
select 'en_ZA' from u union all
select 'fr_FR' from u union all
select 'de_AT' from u union all
select 'el_CY_PREEURO' from u union all
select 'pa_IN' from u union all
select 'nl' from u union all
select 'nl_NL' from u union all
select 'lv_LV' from u union all
select 'pt_PT_PREEURO' from u union all
select 'es_CR' from u union all
select 'fr_FR_PREEURO' from u union all
select 'ar_KW' from u union all
select 'sr' from u union all
select 'ar_LY' from u union all
select 'da' from u union all
select 'el_GR_PREEURO' from u union all
select 'et_EE_PREEURO' from u union all
select 'pl_PL_PREEURO' from u union all
select 'ar_DZ' from u union all
select 'en_HK' from u union all
select 'sk_SK' from u union all
select 'en_CA' from u union all
select 'nl_BE' from u union all
select 'zh_CN' from u union all
select 'de_GR' from u union all
select 'sr_RS_#Latn' from u union all
select 'hu_HU_PREEURO' from u union all
select 'iw' from u union all
select 'en_IN' from u union all
select 'es_NI' from u union all
select 'mk_MK' from u union all
select 'sl_SI' from u union all
select 'te_IN' from u
)
select locale, sprintf(locale, '%1$tB', pack(ccsid 1208, current timestamp)) as Result
  from locales;

with p(p) as (
 select pack(ccsid 1208, 
             current timestamp
            ) from sysibm.sysdummyu
)
select sprintf('it', '%1$tB', p) as Result from p;

select sprintf('%-20s %-20s: %ta, %<td.%<tm.%<tY: %09.2f', 
               pack(ccsid 1208, lastname, firstnme, birthdate, salary))
  from dsn81310.emp;
  
select    char(lastname, 20)
       || ' ' 
       || char(firstnme, 20) 
       || ': '
       || decode(dayofweek_iso(birthdate), 1, 'Mon', 2, 'Tue', 3, 'Wed', 4, 'Thu', 5, 'Fri', 6, 'Sat', 7, 'Sun')
       || ', ' 
       || varchar_format(birthdate, 'DD.MM.YYYY')
       || ': '
       || varchar_format(salary, '000000.00')
  from dsn81310.emp;
  
  