WITH
  v_ssp_user AS (
    SELECT
      CASE
        WHEN '<P_SSP_CMMNTY_ID>' = 'User Level' THEN
          (
            SELECT u.user_sk
              FROM npf_user u
              JOIN wpa_user_appl ua
                ON ua.user_sk = u.user_sk
             WHERE u.user_sk = <P_USER_SK>
             LIMIT 1
          )
        ELSE NULL
      END AS v_ssp_user_sk
  ),
  v_ssp_count AS (
    SELECT
      COUNT(ssp.ssp_id) AS cnt
    FROM wpa_ssp       AS ssp
    JOIN wpa_ssp_cmnty AS cmnty
      ON ssp.cmnty_id = cmnty.cmnty_id
    CROSS JOIN v_ssp_user
    WHERE cmnty.cmnty_cde = '<P_SSP_CMMNTY_ID>'
      AND CURRENT_TIMESTAMP() BETWEEN ssp.ssp_start_date AND ssp.ssp_end_date
      AND (v_ssp_user.v_ssp_user_sk IS NULL
           OR ssp.user_sk = v_ssp_user.v_ssp_user_sk)
  ),
  v_ssp_latest AS (
    SELECT
      MAX(ssp.ssp_id) AS ssp_id
    FROM wpa_ssp       AS ssp
    JOIN wpa_ssp_cmnty AS cmnty
      ON ssp.cmnty_id = cmnty.cmnty_id
    CROSS JOIN v_ssp_user
    CROSS JOIN v_ssp_count
    WHERE cmnty.cmnty_cde = '<P_SSP_CMMNTY_ID>'
      AND CURRENT_TIMESTAMP() BETWEEN ssp.ssp_start_date AND ssp.ssp_end_date
      AND (v_ssp_user.v_ssp_user_sk IS NULL
           OR ssp.user_sk = v_ssp_user.v_ssp_user_sk)
      AND v_ssp_count.cnt >= 1
  ),
  v_ssp_content AS (
    SELECT
      s.ssp_id,
      s.ssp_msg_text_clob   AS msg_text,
      s.ssp_msg_url         AS msg_url,
      CASE
        WHEN s.ssp_msg_url IS NULL THEN 'MSG'
        ELSE 'URL'
      END AS ssp_type
    FROM wpa_ssp AS s
    JOIN v_ssp_latest AS latest
      ON s.ssp_id = latest.ssp_id
    JOIN wpa_ssp_cmnty AS cmnty
      ON s.cmnty_id = cmnty.cmnty_id
    CROSS JOIN v_ssp_user
    WHERE CURRENT_TIMESTAMP() BETWEEN s.ssp_start_date AND s.ssp_end_date
      AND cmnty.cmnty_cde = '<P_SSP_CMMNTY_ID>'
      AND (v_ssp_user.v_ssp_user_sk IS NULL
           OR s.user_sk = v_ssp_user.v_ssp_user_sk)
  ),
  v_ssp_flag AS (
    SELECT
      COUNT(u.user_sk) AS flag_count
    FROM wpa_ssp_user AS u
    JOIN v_ssp_latest AS latest
      ON u.ssp_id = latest.ssp_id
    WHERE u.user_sk = <P_USER_SK>
  )
SELECT
  CASE
    WHEN vc.cnt >= 1
         AND vf.flag_count = 0
      THEN vf.flag_count
    WHEN vc.cnt >= 1
         AND vf.flag_count > 0
      THEN vf.flag_count
    ELSE 1
  END                                                        AS ssp_flag,

  CASE
    WHEN vc.cnt >= 1
         AND vf.flag_count = 0
      THEN vl.ssp_id
    ELSE NULL
  END                                                        AS ssp_id,

  CASE
    WHEN vc.cnt >= 1
         AND vf.flag_count = 0
      THEN vcnt.ssp_type
    ELSE NULL
  END                                                        AS ssp_type,

  CASE
    WHEN vc.cnt >= 1
         AND vf.flag_count = 0
      THEN
        CASE
          WHEN vcnt.ssp_type = 'URL' THEN vcnt.msg_url
          ELSE vcnt.msg_text
        END
    ELSE NULL
  END                                                        AS ssp_content,

  '<P_TRAN_TYPE>'                                            AS ssp_proc

FROM v_ssp_count   AS vc
CROSS JOIN v_ssp_latest   AS vl
CROSS JOIN v_ssp_content  AS vcnt
CROSS JOIN v_ssp_flag     AS vf
;
