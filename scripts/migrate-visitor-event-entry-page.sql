-- Build Visitor Event Entry by cloning the existing Event Log flow page.
BEGIN;

DO $migration$
DECLARE
  v_source_ancestor text := 'd4s24lh93ys';  -- Event Log tab route model
  v_target_ancestor text := 'nd55y4syg0j';  -- Visitor Event Entry tab route model
  v_row record;
  v_model record;
  v_old_target_uids text[];
  v_options_text text;
BEGIN
  IF to_regclass('public."flowModels"') IS NULL OR to_regclass('public."flowModelTreePath"') IS NULL THEN
    RAISE NOTICE 'Flow model tables not found; skipping Visitor Event Entry migration.';
    RETURN;
  END IF;

  IF (SELECT count(*) FROM "flowModels" WHERE uid IN (v_source_ancestor, v_target_ancestor)) <> 2 THEN
    RAISE NOTICE 'Source or target flow model missing; skipping Visitor Event Entry migration.';
    RETURN;
  END IF;

  -- Remove any previously generated subtree under the target ancestor.
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

  -- Add explicit quick-create actions for entry/exit/correction.
  INSERT INTO "flowModels" (uid, name, options) VALUES
    ('vstentryact1', 'vstentryact1',
      '{"use":"AddNewActionModel","parentId":"6a0c8dbf726","subKey":"actions","subType":"array","props":{"title":"Entry","type":"primary"},"stepParams":{"popupSettings":{"openView":{"collectionName":"clickEvents","dataSourceKey":"main"}}},"sortIndex":1,"flowRegistry":{}}'::json),
    ('vstentryact2', 'vstentryact2',
      '{"use":"AddNewActionModel","parentId":"6a0c8dbf726","subKey":"actions","subType":"array","props":{"title":"Exit","type":"default"},"stepParams":{"popupSettings":{"openView":{"collectionName":"clickEvents","dataSourceKey":"main"}}},"sortIndex":2,"flowRegistry":{}}'::json),
    ('vstentryact3', 'vstentryact3',
      '{"use":"AddNewActionModel","parentId":"6a0c8dbf726","subKey":"actions","subType":"array","props":{"title":"Correction","type":"dashed"},"stepParams":{"popupSettings":{"openView":{"collectionName":"clickEvents","dataSourceKey":"main"}}},"sortIndex":3,"flowRegistry":{}}'::json)
  ON CONFLICT (uid) DO UPDATE SET options = EXCLUDED.options;

  INSERT INTO "flowModelTreePath" (ancestor, descendant, depth, async, type, sort) VALUES
    ('6a0c8dbf726', 'vstentryact1', 1, NULL, NULL, 1),
    ('86c992ab013', 'vstentryact1', 2, NULL, NULL, NULL),
    ('nd55y4syg0j', 'vstentryact1', 3, NULL, NULL, NULL),
    ('vstentryact1', 'vstentryact1', 0, FALSE, 'actions', NULL),
    ('6a0c8dbf726', 'vstentryact2', 1, NULL, NULL, 2),
    ('86c992ab013', 'vstentryact2', 2, NULL, NULL, NULL),
    ('nd55y4syg0j', 'vstentryact2', 3, NULL, NULL, NULL),
    ('vstentryact2', 'vstentryact2', 0, FALSE, 'actions', NULL),
    ('6a0c8dbf726', 'vstentryact3', 1, NULL, NULL, 3),
    ('86c992ab013', 'vstentryact3', 2, NULL, NULL, NULL),
    ('nd55y4syg0j', 'vstentryact3', 3, NULL, NULL, NULL),
    ('vstentryact3', 'vstentryact3', 0, FALSE, 'actions', NULL)
  ON CONFLICT DO NOTHING;

  RAISE NOTICE 'Visitor Event Entry page migration applied.';
END;
$migration$;

COMMIT;
