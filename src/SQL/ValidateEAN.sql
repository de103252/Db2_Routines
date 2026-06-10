-- validate_ean: Validates EAN-13 (European Article Number) barcodes
--
-- Argument: ean (decimal(13)) - A 13-digit EAN barcode number
-- Returns:  integer - 1 if valid, 0 if invalid
--
-- The function calculates the checksum using alternating weights (3 and 1)
-- and compares it against the embedded check digit (rightmost digit).
--
-- Following comment lines tell Data Studio resp. SPUFI
-- to use # as statement terminator
--
-- <ScriptOptions statementTerminator="#"/>
-- #SET TERMINATOR #

drop function validate_ean(ean decimal(13))#

create function validate_ean(ean decimal(13))
  returns integer
  deterministic
  no external action
  returns null on null input
begin
  declare m         integer default 3;
  declare calc_chk  decimal(1) default 0;
  declare given_chk decimal(1);

  set given_chk = mod(ean, 10);
  repeat
    set ean = ean / 10;
    set calc_chk = mod(calc_chk + m*integer(mod(ean, 10)), 10);
    set m = 4 - m;
  until ean = 0 end repeat;
  set calc_chk = mod(10 - calc_chk, 10);
  return case when given_chk - calc_chk = 0 then 1 
end
#

with eans(ean) as (
  select 4003994155485 from sysibm.sysdummyu union all
  select 9783966451192 from sysibm.sysdummyu union all
  select 4015532205577 from sysibm.sysdummyu
)
select ean, case validate_ean(ean) 
            when 1 then 'valid' 
                   else 'invalid'
            end as valid
  from eans
#
