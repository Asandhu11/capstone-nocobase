-- Rebuild new pages with distinct block trees instead of cloned dashboard layouts.
BEGIN;

DO $migration$
DECLARE
  v_old_uids text[];
BEGIN
  IF to_regclass('public."flowModels"') IS NULL OR to_regclass('public."flowModelTreePath"') IS NULL THEN
    RAISE NOTICE 'Flow model tables missing; skipping de-clone migration.';
    RETURN;
  END IF;

  CREATE OR REPLACE FUNCTION pg_temp.clone_block_subtree(
    p_source_root text,
    p_target_ancestor text,
    p_target_grid text,
    p_new_root text,
    p_sort int,
    p_source_collection text,
    p_target_collection text
  ) RETURNS void
  LANGUAGE plpgsql
  AS $f$
  DECLARE
    v_model record;
    v_pair record;
    v_opt text;
  BEGIN
    DROP TABLE IF EXISTS tmp_clone_map;
    CREATE TEMP TABLE tmp_clone_map (
      old_uid text PRIMARY KEY,
      new_uid text NOT NULL
    ) ON COMMIT DROP;

    INSERT INTO tmp_clone_map (old_uid, new_uid)
    SELECT descendant,
           CASE
             WHEN descendant = p_source_root THEN p_new_root
             ELSE substr(md5(p_target_ancestor || ':' || p_new_root || ':' || descendant), 1, 11)
           END
    FROM "flowModelTreePath"
    WHERE ancestor = p_source_root;

    FOR v_model IN
      SELECT f.uid, f.options
      FROM "flowModels" f
      JOIN tmp_clone_map m ON m.old_uid = f.uid
    LOOP
      v_opt := v_model.options::text;

      FOR v_pair IN SELECT old_uid, new_uid FROM tmp_clone_map LOOP
        v_opt := replace(v_opt, v_pair.old_uid, v_pair.new_uid);
      END LOOP;

      IF p_source_collection IS NOT NULL AND p_target_collection IS NOT NULL THEN
        v_opt := replace(
          v_opt,
          '"collectionName":"' || p_source_collection || '"',
          '"collectionName":"' || p_target_collection || '"'
        );
      END IF;

      IF v_model.uid = p_source_root THEN
        v_opt := regexp_replace(v_opt, '"parentId":"[^"]+"', '"parentId":"' || p_target_grid || '"', 1, 1);
        v_opt := regexp_replace(v_opt, '"sortIndex":[0-9]+', '"sortIndex":' || p_sort::text, 1, 1);
      END IF;

      INSERT INTO "flowModels" (uid, name, options)
      SELECT m.new_uid, m.new_uid, v_opt::json
      FROM tmp_clone_map m
      WHERE m.old_uid = v_model.uid
      ON CONFLICT (uid) DO UPDATE SET options = EXCLUDED.options;
    END LOOP;

    INSERT INTO "flowModelTreePath" (ancestor, descendant, depth, async, type, sort)
    SELECT ma.new_uid, md.new_uid, t.depth, t.async, t.type, t.sort
    FROM "flowModelTreePath" t
    JOIN tmp_clone_map ma ON ma.old_uid = t.ancestor
    JOIN tmp_clone_map md ON md.old_uid = t.descendant
    ON CONFLICT DO NOTHING;

    INSERT INTO "flowModelTreePath" (ancestor, descendant, depth, async, type, sort)
    SELECT p_target_grid, m.new_uid, s.depth + 1, NULL, NULL,
           CASE WHEN s.depth = 0 THEN p_sort ELSE NULL END
    FROM "flowModelTreePath" s
    JOIN tmp_clone_map m ON m.old_uid = s.descendant
    WHERE s.ancestor = p_source_root
    ON CONFLICT DO NOTHING;

    INSERT INTO "flowModelTreePath" (ancestor, descendant, depth, async, type, sort)
    SELECT p_target_ancestor, m.new_uid, s.depth + 2, NULL, NULL, NULL
    FROM "flowModelTreePath" s
    JOIN tmp_clone_map m ON m.old_uid = s.descendant
    WHERE s.ancestor = p_source_root
    ON CONFLICT DO NOTHING;
  END;
  $f$;

  -- Rebuild Facility and Access Admin page.
  SELECT array_agg(descendant) INTO v_old_uids
  FROM "flowModelTreePath"
  WHERE ancestor = '32c903yb1hd' AND depth > 0;

  IF v_old_uids IS NOT NULL THEN
    DELETE FROM "flowModelTreePath"
    WHERE ancestor = ANY(v_old_uids)
       OR descendant = ANY(v_old_uids)
       OR (ancestor = '32c903yb1hd' AND descendant = ANY(v_old_uids));

    DELETE FROM "flowModels" WHERE uid = ANY(v_old_uids);
  END IF;

  INSERT INTO "flowModels" (uid, name, options) VALUES
    ('facgridv2a1', 'facgridv2a1', '{"parentId":"32c903yb1hd","subKey":"grid","subType":"object","use":"BlockGridModel","props":{},"stepParams":{},"sortIndex":0,"flowRegistry":{},"filterManager":[]}'::json)
  ON CONFLICT (uid) DO UPDATE SET options = EXCLUDED.options;

  INSERT INTO "flowModelTreePath" (ancestor, descendant, depth, async, type, sort) VALUES
    ('facgridv2a1', 'facgridv2a1', 0, FALSE, 'grid', NULL),
    ('32c903yb1hd', 'facgridv2a1', 1, NULL, NULL, 1)
  ON CONFLICT DO NOTHING;

  PERFORM pg_temp.clone_block_subtree('a8c1500a514', '32c903yb1hd', 'facgridv2a1', 'facvenv2a01', 1, 'venues', 'venues');
  PERFORM pg_temp.clone_block_subtree('a8c1500a514', '32c903yb1hd', 'facgridv2a1', 'facentv2a01', 2, 'venues', 'entrances');
  PERFORM pg_temp.clone_block_subtree('cb7955f07ea', '32c903yb1hd', 'facgridv2a1', 'facdevv2a01', 3, 'devices', 'devices');
  PERFORM pg_temp.clone_block_subtree('9a0b8179b5e', '32c903yb1hd', 'facgridv2a1', 'facclkv2a01', 4, 'clickEvents', 'clickEvents');
  PERFORM pg_temp.clone_block_subtree('a8c1500a514', '32c903yb1hd', 'facgridv2a1', 'facrolv2a01', 5, 'venues', 'roles');

  -- Rebuild Alerts and Audit Command Center page.
  SELECT array_agg(descendant) INTO v_old_uids
  FROM "flowModelTreePath"
  WHERE ancestor = 'wjhituuh4cu' AND depth > 0;

  IF v_old_uids IS NOT NULL THEN
    DELETE FROM "flowModelTreePath"
    WHERE ancestor = ANY(v_old_uids)
       OR descendant = ANY(v_old_uids)
       OR (ancestor = 'wjhituuh4cu' AND descendant = ANY(v_old_uids));

    DELETE FROM "flowModels" WHERE uid = ANY(v_old_uids);
  END IF;

  INSERT INTO "flowModels" (uid, name, options) VALUES
    ('alrtgridv2a1', 'alrtgridv2a1', '{"parentId":"wjhituuh4cu","subKey":"grid","subType":"object","use":"BlockGridModel","props":{},"stepParams":{},"sortIndex":0,"flowRegistry":{},"filterManager":[]}'::json)
  ON CONFLICT (uid) DO UPDATE SET options = EXCLUDED.options;

  INSERT INTO "flowModelTreePath" (ancestor, descendant, depth, async, type, sort) VALUES
    ('alrtgridv2a1', 'alrtgridv2a1', 0, FALSE, 'grid', NULL),
    ('wjhituuh4cu', 'alrtgridv2a1', 1, NULL, NULL, 1)
  ON CONFLICT DO NOTHING;

  PERFORM pg_temp.clone_block_subtree('d4d5bdb8435', 'wjhituuh4cu', 'alrtgridv2a1', 'alrtblk2a01', 1, 'alerts', 'alerts');
  PERFORM pg_temp.clone_block_subtree('d4d5bdb8435', 'wjhituuh4cu', 'alrtgridv2a1', 'audtblk2a01', 2, 'alerts', 'auditLogs');
  PERFORM pg_temp.clone_block_subtree('d4d5bdb8435', 'wjhituuh4cu', 'alrtgridv2a1', 'notsblk2a01', 3, 'alerts', 'notificationSubscriptions');
  PERFORM pg_temp.clone_block_subtree('9a0b8179b5e', 'wjhituuh4cu', 'alrtgridv2a1', 'relcblk2a01', 4, 'clickEvents', 'clickEvents');

  -- Rebuild Visitor Event Entry page and keep quick actions.
  SELECT array_agg(descendant) INTO v_old_uids
  FROM "flowModelTreePath"
  WHERE ancestor = 'nd55y4syg0j' AND depth > 0;

  IF v_old_uids IS NOT NULL THEN
    DELETE FROM "flowModelTreePath"
    WHERE ancestor = ANY(v_old_uids)
       OR descendant = ANY(v_old_uids)
       OR (ancestor = 'nd55y4syg0j' AND descendant = ANY(v_old_uids));

    DELETE FROM "flowModels" WHERE uid = ANY(v_old_uids);
  END IF;

  INSERT INTO "flowModels" (uid, name, options) VALUES
    ('visgridv2a1', 'visgridv2a1', '{"parentId":"nd55y4syg0j","subKey":"grid","subType":"object","use":"BlockGridModel","props":{},"stepParams":{},"sortIndex":0,"flowRegistry":{},"filterManager":[]}'::json)
  ON CONFLICT (uid) DO UPDATE SET options = EXCLUDED.options;

  INSERT INTO "flowModelTreePath" (ancestor, descendant, depth, async, type, sort) VALUES
    ('visgridv2a1', 'visgridv2a1', 0, FALSE, 'grid', NULL),
    ('nd55y4syg0j', 'visgridv2a1', 1, NULL, NULL, 1)
  ON CONFLICT DO NOTHING;

  PERFORM pg_temp.clone_block_subtree('9a0b8179b5e', 'nd55y4syg0j', 'visgridv2a1', 'visclkv2a01', 1, 'clickEvents', 'clickEvents');

  INSERT INTO "flowModels" (uid, name, options) VALUES
    ('vstentryb21', 'vstentryb21', '{"use":"AddNewActionModel","parentId":"visclkv2a01","subKey":"actions","subType":"array","props":{"title":"Log Entrance Entry","type":"primary"},"stepParams":{"popupSettings":{"openView":{"collectionName":"clickEvents","dataSourceKey":"main"}}},"sortIndex":1,"flowRegistry":{}}'::json)
  ON CONFLICT (uid) DO UPDATE SET options = EXCLUDED.options;

  INSERT INTO "flowModelTreePath" (ancestor, descendant, depth, async, type, sort) VALUES
    ('visclkv2a01', 'vstentryb21', 1, NULL, NULL, 1),
    ('visgridv2a1', 'vstentryb21', 2, NULL, NULL, NULL),
    ('nd55y4syg0j', 'vstentryb21', 3, NULL, NULL, NULL),
    ('vstentryb21', 'vstentryb21', 0, FALSE, 'actions', NULL)
  ON CONFLICT DO NOTHING;

  RAISE NOTICE 'De-clone page rebuild migration applied.';
END;
$migration$;

COMMIT;
