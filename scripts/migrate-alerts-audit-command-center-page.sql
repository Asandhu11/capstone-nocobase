-- Build Alerts and Audit Command Center by cloning the existing Occupancy Dashboard flow page.
BEGIN;

DO $migration$
DECLARE
  v_source_ancestor text := '4loakiv2t4k';  -- Occupancy Dashboard tab route model
  v_target_ancestor text := 'wjhituuh4cu';  -- Alerts and Audit Command Center tab route model
  v_row record;
  v_model record;
  v_old_target_uids text[];
  v_options_text text;
BEGIN
  IF to_regclass('public."flowModels"') IS NULL OR to_regclass('public."flowModelTreePath"') IS NULL THEN
    RAISE NOTICE 'Flow model tables not found; skipping Alerts and Audit Command Center migration.';
    RETURN;
  END IF;

  IF (SELECT count(*) FROM "flowModels" WHERE uid IN (v_source_ancestor, v_target_ancestor)) <> 2 THEN
    RAISE NOTICE 'Source or target flow model missing; skipping Alerts and Audit Command Center migration.';
    RETURN;
  END IF;

  SELECT array_agg(descendant) INTO v_old_target_uids
  FROM "flowModelTreePath"
  WHERE ancestor = v_target_ancestor AND depth > 0;

  IF v_old_target_uids IS NOT NULL THEN
    DELETE FROM "flowModelTreePath"
    WHERE ancestor = ANY(v_old_target_uids)
       OR descendant = ANY(v_old_target_uids)
       OR (ancestor = v_target_ancestor AND descendant = ANY(v_old_target_uids));

    DELETE FROM "flowModels" WHERE uid = ANY(v_old_target_uids);
  END IF;

  CREATE TEMP TABLE tmp_map (
    old_uid text PRIMARY KEY,
    new_uid text NOT NULL
  ) ON COMMIT DROP;

  INSERT INTO tmp_map (old_uid, new_uid)
  SELECT descendant AS old_uid,
         substr(md5(v_target_ancestor || ':' || descendant), 1, 11) AS new_uid
  FROM "flowModelTreePath"
  WHERE ancestor = v_source_ancestor
    AND depth > 0
  ORDER BY depth, descendant;

  FOR v_model IN
    SELECT f.uid, f.options
    FROM "flowModels" f
    JOIN tmp_map m ON m.old_uid = f.uid
  LOOP
    v_options_text := v_model.options::text;
    v_options_text := replace(v_options_text, v_source_ancestor, v_target_ancestor);

    FOR v_row IN SELECT old_uid, new_uid FROM tmp_map LOOP
      v_options_text := replace(v_options_text, v_row.old_uid, v_row.new_uid);
    END LOOP;

    INSERT INTO "flowModels" (uid, name, options)
    SELECT m.new_uid, m.new_uid, v_options_text::json
    FROM tmp_map m
    WHERE m.old_uid = v_model.uid;
  END LOOP;

  INSERT INTO "flowModelTreePath" (ancestor, descendant, depth, async, type, sort)
  SELECT CASE
           WHEN t.ancestor = v_source_ancestor THEN v_target_ancestor
           ELSE ma.new_uid
         END AS ancestor,
         md.new_uid AS descendant,
         t.depth,
         t.async,
         t.type,
         t.sort
  FROM "flowModelTreePath" t
  JOIN tmp_map md ON md.old_uid = t.descendant
  LEFT JOIN tmp_map ma ON ma.old_uid = t.ancestor
  WHERE (t.ancestor = v_source_ancestor OR t.ancestor IN (SELECT old_uid FROM tmp_map))
    AND t.descendant IN (SELECT old_uid FROM tmp_map)
  ORDER BY 1, 2, 3;

  -- Keep existing alerts and venues blocks, then add audit/notifications/click-events blocks.
  INSERT INTO "flowModels" (uid, name, options)
  SELECT 'alrtaudblk01', 'alrtaudblk01',
         replace(replace(options::text, '"parentId":"54dd3089d69"', '"parentId":"54dd3089d69"'), '"collectionName":"venues"', '"collectionName":"auditLogs"')::json
  FROM "flowModels"
  WHERE uid = 'efb33f9fc11'
  ON CONFLICT (uid) DO UPDATE SET options = EXCLUDED.options;

  INSERT INTO "flowModelTreePath" (ancestor, descendant, depth, async, type, sort) VALUES
    ('54dd3089d69', 'alrtaudblk01', 1, NULL, NULL, 3),
    ('wjhituuh4cu', 'alrtaudblk01', 2, NULL, NULL, NULL),
    ('alrtaudblk01', 'alrtaudblk01', 0, FALSE, 'items', NULL)
  ON CONFLICT DO NOTHING;

  INSERT INTO "flowModels" (uid, name, options)
  SELECT 'alrtnotblk01', 'alrtnotblk01',
         replace(replace(options::text, '"parentId":"54dd3089d69"', '"parentId":"54dd3089d69"'), '"collectionName":"venues"', '"collectionName":"notificationSubscriptions"')::json
  FROM "flowModels"
  WHERE uid = 'efb33f9fc11'
  ON CONFLICT (uid) DO UPDATE SET options = EXCLUDED.options;

  INSERT INTO "flowModelTreePath" (ancestor, descendant, depth, async, type, sort) VALUES
    ('54dd3089d69', 'alrtnotblk01', 1, NULL, NULL, 4),
    ('wjhituuh4cu', 'alrtnotblk01', 2, NULL, NULL, NULL),
    ('alrtnotblk01', 'alrtnotblk01', 0, FALSE, 'items', NULL)
  ON CONFLICT DO NOTHING;

  INSERT INTO "flowModels" (uid, name, options)
  SELECT 'alrtclkblk01', 'alrtclkblk01',
         replace(replace(options::text, '"parentId":"54dd3089d69"', '"parentId":"54dd3089d69"'), '"collectionName":"venues"', '"collectionName":"clickEvents"')::json
  FROM "flowModels"
  WHERE uid = 'efb33f9fc11'
  ON CONFLICT (uid) DO UPDATE SET options = EXCLUDED.options;

  INSERT INTO "flowModelTreePath" (ancestor, descendant, depth, async, type, sort) VALUES
    ('54dd3089d69', 'alrtclkblk01', 1, NULL, NULL, 5),
    ('wjhituuh4cu', 'alrtclkblk01', 2, NULL, NULL, NULL),
    ('alrtclkblk01', 'alrtclkblk01', 0, FALSE, 'items', NULL)
  ON CONFLICT DO NOTHING;

  RAISE NOTICE 'Alerts and Audit Command Center migration applied.';
END;
$migration$;

COMMIT;
