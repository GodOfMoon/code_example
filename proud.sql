
/*
Изменение стоимости коллективного тарифа
*/

  SELECT bap.date_start, bap.plan_cost, bap.service, om.email, b.name, cp.name_pack, o.name AS org_name, o.type AS org_type, bos.list_email
    FROM (SELECT id_range, id_building, date_start, plan, plan_cost, "atv" AS service FROM building_atv_plans WHERE DATE_SUB(date_start, INTERVAL 1 MONTH) = ?
           UNION
          SELECT id_range, id_building, date_start, plan, plan_cost, service FROM building_collective_plans WHERE DATE_SUB(date_start, INTERVAL 1 MONTH) = ?) AS bap
    JOIN building_attr AS ba ON ba.id_building= bap.id_building
    JOIN org_managers AS om ON ba.manager_id = om.id
    JOIN buildings AS b ON b.id = bap.id_building
    JOIN building_org_serv AS bos ON bos.id = bap.id_range
    JOIN org AS o ON o.id = bos.id_org
    JOIN collective_packs AS cp ON cp.code = bap.plan

/*
Уведомление о последних сформированных счетах
*/

  SELECT bos.id, cab.range_id, bos.id_org AS org_id, b.name AS building_name, o.type AS org_type, o.name AS org_name, om.email AS manager_email, bos.list_email, bos.bill_period, bos.adm_contract, bos.adm_radio_contract,
         cab2.adm_contract AS by_contract, cab2.year_bill, cab2.month_bill, cab2.serv_type
    FROM building_org_serv AS bos
    JOIN building_attr AS ba ON ba.id_building = bos.id_building
    JOIN org_managers AS om ON ba.manager_id = om.id
    JOIN buildings AS b ON b.id = bos.id_building
    JOIN org AS o ON o.id = bos.id_org
    LEFT JOIN (
        SELECT MAX(CONCAT(DATE(CONCAT(year_bill, "-", month_bill, "-01")), id)) AS id, range_id, serv_type FROM (SELECT id, building_id, org_id, adm_contract, year_bill, month_bill, serv_type, actual_date, bill_enter_date, range_id FROM dhcp_server.coop_atv_bills AS cab
        JOIN JSON_TABLE(json_keys(ranges), "$[*]" COLUMNS(range_id int PATH "$[0]")) AS ranges) AS a GROUP BY range_id, serv_type
    ) AS cab ON cab.range_id = bos.id
    LEFT JOIN coop_atv_bills AS cab2 ON SUBSTR(cab.id, 11) = cab2.id
    WHERE bos.calcs_by_org = 1 AND bos.calc_type NOT IN ("vckp", "individ", "pes", "") AND b.id <> 3004

  --   AND DATE_ADD(DATE(CONCAT(cab2.year_bill, "-", cab2.month_bill, "-", DAY(CURRENT_DATE()))), INTERVAL IF (bos.bill_period = "quarter", 3, 1) MONTH) < CURRENT_DATE()

    ORDER BY o.id, b.name
