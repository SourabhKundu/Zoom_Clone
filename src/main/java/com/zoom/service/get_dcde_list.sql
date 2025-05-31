SELECT
  dcde_code,
  dcde_type,
  dcde_desc,
  sort_nbr,
  creat_by,
  creat_tm,
  upd_by,
  upd_tm
FROM npf_decode
WHERE dcde_type = TRIM(:P_DCDE_TYPE);
