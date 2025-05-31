WITH
intrn_flag AS (
  SELECT
    CASE
      WHEN EXISTS (
        SELECT 1
          FROM npe_user u
          JOIN npe_user_type ut
            ON ut.user_type_id = u.user_type_id
         WHERE u.user_id     = '<P_USER_ID>'
           AND ut.intrn_flag = 'E'
      ) THEN 'E'
      ELSE 'I'
    END AS flag
),

has_xx AS (
  SELECT
    CASE
      WHEN STRPOS('<P_USER_ID>', 'XX') > 0 THEN TRUE
      ELSE FALSE
    END AS value
),

branchA AS (
  SELECT
    g.wpa_entl_grp AS entl,
    1              AS value
  FROM npe_prf
  JOIN npe_xx_user_cfg
    ON npe_prf.prf_sk = npe_xx_user_cfg.prf_sk
  JOIN npe_prf_bus_func
    ON npe_xx_user_cfg.prf_sk = npe_prf_bus_func.prf_sk
  JOIN npe_bus_func_asa_role
    ON npe_prf_bus_func.bus_func_id = npe_bus_func_asa_role.bus_func_id
  JOIN npe_wpa_entl_grp g
    ON g.prf_sk = npe_prf.prf_sk
  WHERE
    STRPOS('<P_USER_ID>', 'XX') > 0
    AND npe_prf.lvl_type IN ('USERCA','USERCAACC')
    AND g.wpa_entl_grp NOT IN ('VWE','EDE')

  UNION ALL
  SELECT 'VWE' AS entl,
         get_emulation('VWE','<P_USER_ID>') AS value
  UNION ALL
  SELECT 'EDE' AS entl,
         get_emulation('EDE','<P_USER_ID>') AS value

  UNION ALL
  SELECT
    'BPT' AS entl,
    COUNT(*) AS value
  FROM npe_user u
  JOIN npf_user_extl_appl appl
    ON appl.user_sk = u.user_sk
  JOIN npf_bpt_user bu
    ON bu.user_sk = u.user_sk
  WHERE
    u.user_id = '<P_USER_ID>'
    AND appl.extl_appl_id        = 'BPT'
    AND bu.bpt_actv_stat_cde     = 'ACA'

  UNION ALL

  SELECT
    'BRK' AS entl,
    COUNT(*) AS value
  FROM npe_user u
  JOIN npf_user_extl_appl a
    ON a.user_sk = u.user_sk
  WHERE
    u.user_id              = '<P_USER_ID>'
    AND a.extl_appl_id      = 'BRK'
),

branchB AS (
  SELECT
    g.wpa_entl_grp AS entl,
    1              AS value
  FROM npf_user usr
  JOIN npe_user npe
    ON npe.user_sk = usr.user_sk
  JOIN npe_intrn_user_prf uprf
    ON uprf.user_sk = npe.user_sk
  JOIN npe_prf prf
    ON uprf.prf_sk = prf.prf_sk
  JOIN npe_wpa_entl_grp g
    ON g.prf_sk = prf.prf_sk
  WHERE
    usr.user_type_dcde = 'IN'
    AND npe.user_id     = '<P_USER_ID>'
    AND STRPOS('<P_USER_ID>', 'XX') = 0
    AND g.wpa_entl_grp IN ('MMP','MMR','IMO')

  UNION ALL

  SELECT
    g.wpa_entl_grp AS entl,
    1              AS value
  FROM npe_wpa_entl_grp g
  WHERE
    STRPOS('<P_USER_ID>', 'XX') = 0
    AND g.wpa_entl_grp NOT IN ('VWE','EDE','MMP','MMR','IMO')

  UNION ALL

  SELECT 'PMM' AS entl,
         1      AS value

  UNION ALL
  SELECT 'VWE' AS entl,
         get_emulation('VWE','<P_USER_ID>') AS value
  UNION ALL
  SELECT 'EDE' AS entl,
         get_emulation('EDE','<P_USER_ID>') AS value

  UNION ALL
  SELECT
    'BPT' AS entl,
    COUNT(*) AS value
  FROM npe_user u
  JOIN npf_user_extl_appl appl
    ON appl.user_sk = u.user_sk
  JOIN npf_bpt_user bu
    ON bu.user_sk = u.user_sk
  WHERE
    u.user_id              = '<P_USER_ID>'
    AND appl.extl_appl_id   = 'BPT'
    AND bu.bpt_actv_stat_cde = 'ACA'

  UNION ALL
  SELECT
    'BRK' AS entl,
    COUNT(*) AS value
  FROM npe_user u
  JOIN npf_user_extl_appl a
    ON a.user_sk = u.user_sk
  WHERE
    u.user_id           = '<P_USER_ID>'
    AND a.extl_appl_id   = 'BRK'
),
branchC AS (
  SELECT
    g.wpa_entl_grp AS entl,
    1              AS value
  FROM npe_ca_user_prf c
  JOIN npe_ca_user u
    ON u.ca_user_sk = c.ca_user_sk
  JOIN npe_user uu
    ON uu.user_sk = u.user_sk
  JOIN npe_ca_prf p
    ON p.ca_prf_sk = c.ca_prf_sk
  JOIN npe_wpa_entl_grp g
    ON g.prf_sk = p.prf_sk
  WHERE
    uu.user_id = '<P_USER_ID>'
    AND g.wpa_entl_grp <> 'PMM'

  UNION ALL
  SELECT
    'PMM' AS entl,
    1      AS value
  WHERE
    EXISTS (
      SELECT 1
        FROM npe_ca_user_prf p
        JOIN npe_ca_user cu
          ON cu.ca_user_sk = p.ca_user_sk
        JOIN npe_user u
          ON u.user_sk = cu.user_sk
        JOIN npe_ca_mm_prf cp
          ON cp.ca_prf_sk = p.ca_prf_sk
       WHERE u.user_id = '<P_USER_ID>'
         AND cu.ca_sk   = cp.ca_sk

      UNION ALL

      SELECT 1
        FROM npe_ca_user_prf p
        JOIN npe_ca_user cu
          ON cu.ca_user_sk = p.ca_user_sk
        JOIN npe_user u
          ON u.user_sk = cu.user_sk
        JOIN npe_ca_prf cp
          ON cp.ca_prf_sk = p.ca_prf_sk
       WHERE u.user_id = '<P_USER_ID>'
         AND cp.prf_sk IN (122, 709, 710)
    )

  UNION ALL
  SELECT
    'MMO' AS entl,
    1     AS value
  WHERE EXISTS (
    SELECT 1
      FROM npe_ca_user_prf p
      JOIN npe_ca_user cu
        ON cu.ca_user_sk = p.ca_user_sk
      JOIN npe_user u
        ON u.user_sk = cu.user_sk
      JOIN npe_ca_mm_prf cp
        ON cp.ca_prf_sk = p.ca_prf_sk
      JOIN npe_prf prf
        ON prf.prf_name = cp.prf_name
     WHERE u.user_id = '<P_USER_ID>'
       AND prf.prf_sk  = '701'
  )

  UNION ALL
  SELECT
    'MMC' AS entl,
    1     AS value
  WHERE EXISTS (
    SELECT 1
      FROM npe_ca_user_prf p
      JOIN npe_ca_user cu
        ON cu.ca_user_sk = p.ca_user_sk
      JOIN npe_user u
        ON u.user_sk = cu.user_sk
      JOIN npe_ca_mm_prf cp
        ON cp.ca_prf_sk = p.ca_prf_sk
      JOIN npe_prf prf
        ON prf.prf_name = cp.prf_name
     WHERE u.user_id = '<P_USER_ID>'
       AND prf.prf_sk  = '702'
  )

  UNION ALL
  SELECT
    'MML' AS entl,
    1     AS value
  WHERE EXISTS (
    SELECT 1
      FROM npe_ca_user_prf p
      JOIN npe_ca_user cu
        ON cu.ca_user_sk = p.ca_user_sk
      JOIN npe_user u
        ON u.user_sk = cu.user_sk
      JOIN npe_ca_mm_prf cp
        ON cp.ca_prf_sk = p.ca_prf_sk
      JOIN npe_prf prf
        ON prf.prf_name = cp.prf_name
     WHERE u.user_id = '<P_USER_ID>'
       AND prf.prf_sk  = '704'
  )

  UNION ALL
  SELECT
    'MMA' AS entl,
    1     AS value
  WHERE EXISTS (
    SELECT 1
      FROM npe_ca_user_prf p
      JOIN npe_ca_user cu
        ON cu.ca_user_sk = p.ca_user_sk
      JOIN npe_user u
        ON u.user_sk = cu.user_sk
      JOIN npe_ca_mm_prf cp
        ON cp.ca_prf_sk = p.ca_prf_sk
      JOIN npe_prf prf
        ON prf.prf_name = cp.prf_name
     WHERE u.user_id = '<P_USER_ID>'
       AND prf.prf_sk  = '700'
  )

  UNION ALL
  SELECT
    'LCP' AS entl,
    1     AS value
  WHERE EXISTS (
    SELECT 1
      FROM npe_ca_user_prf p
      JOIN npe_ca_user cu
        ON cu.ca_user_sk = p.ca_user_sk
      JOIN npe_user u
        ON u.user_sk = cu.user_sk
      JOIN npe_ca_prf cp
        ON cp.ca_prf_sk = p.ca_prf_sk
     WHERE u.user_id = '<P_USER_ID>'
       AND cp.prf_sk  = 125
  )

  UNION ALL
  SELECT
    'BPT' AS entl,
    COUNT(*) AS value
  FROM npe_user u
  JOIN npf_user_extl_appl appl
    ON appl.user_sk = u.user_sk
  JOIN npf_bpt_user bu
    ON bu.user_sk = u.user_sk
  WHERE
    u.user_id              = '<P_USER_ID>'
    AND appl.extl_appl_id   = 'BPT'
    AND bu.bpt_actv_stat_cde = 'ACA'

  UNION ALL
  SELECT
    'BRK' AS entl,
    COUNT(*) AS value
  FROM npe_user u
  JOIN npf_user_extl_appl a
    ON a.user_sk = u.user_sk
  WHERE
    u.user_id        = '<P_USER_ID>'
    AND a.extl_appl_id = 'BRK'
),
all_entl_grp AS (
  SELECT wpa_entl_grp
    FROM npe_wpa_entl_grp
)
SELECT
  e.wpa_entl_grp AS entl,
  CASE
    WHEN i.flag = 'I' AND h.value = TRUE  THEN COALESCE(a.value, 0)
    WHEN i.flag = 'I' AND h.value = FALSE THEN COALESCE(b.value, 0)
    WHEN i.flag = 'E'                  THEN COALESCE(c.value, 0)
  END AS value
FROM all_entl_grp e

LEFT JOIN branchA a
  ON a.entl = e.wpa_entl_grp
LEFT JOIN branchB b
  ON b.entl = e.wpa_entl_grp
LEFT JOIN branchC c
  ON c.entl = e.wpa_entl_grp

CROSS JOIN intrn_flag i
CROSS JOIN has_xx h

ORDER BY e.wpa_entl_grp
;
