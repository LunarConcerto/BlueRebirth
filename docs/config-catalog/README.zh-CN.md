# 某游戏客户端配置目录

> 生成时间 `2026-08-13T02:51:29.4919159+00:00`。所有数据库均以只读方式访问，原始客户端文件未修改。

## 已确认的解码规则

`DBObject.jsonbytes` 的每个字节与 `0x55` 异或后解析为 JSON：

```text
decoded[i] = encoded[i] XOR 0x55
```

## 扫描结果

| 客户端 | 数据库 | 总行数 | 元数据行 | 有效 JSON | 解码失败 |
| --- | ---: | ---: | ---: | ---: | ---: |
| `jp-1.4.0` | 492 | 292839 | 492 | 292347 | 0 |
| `cn-1.5.20` | 450 | 213578 | 450 | 213128 | 0 |

## 奖励类型推断

### jp-1.4.0

| 类型 | 引用数 | 不同目标 | 最佳语义 | 覆盖率 | 未解析样本 |
| ---: | ---: | ---: | --- | ---: | --- |
| 1 | 4886 | 272 | `item` | 100.0% | `` |
| 2 | 310 | 111 | `equipment` | 100.0% | `` |
| 3 | 153 | 67 | `ship` | 100.0% | `` |
| 5 | 3029 | 19 | `currency` | 100.0% | `` |
| 6 | 261 | 4 | `unresolved` | 0.0% | `60000, 60003, 60002, 60001` |
| 8 | 742 | 127 | `unresolved` | 0.0% | `80357, 80362, 80363, 80044, 80361, 80358, 80154, 80371, 80222, 80259, 80170, 80118, 80155, 80040, 80360, 81011, 81001, 81002, 80171, 80257` |
| 11 | 391 | 17 | `unresolved` | 0.0% | `110097, 110003, 110056, 110055, 110043, 110096, 110099, 110002, 110104, 110048, 110101, 110100, 110046, 110047, 110102, 110095, 110041` |
| 12 | 17 | 3 | `unresolved` | 0.0% | `120004, 120006, 120005` |
| 14 | 3 | 2 | `unresolved` | 0.0% | `140002, 140001` |
| 15 | 605 | 6 | `unresolved` | 0.0% | `150001, 150004, 150003, 150005, 150006, 150002` |
| 16 | 64 | 62 | `unresolved` | 0.0% | `168226, 168301, 168227, 168205, 168109, 168260, 168264, 168265, 168266, 168270, 168271, 168272, 168256, 168253, 168249, 168273, 168204, 168105, 168103, 168213` |
| 18 | 32 | 32 | `fashion` | 100.0% | `` |
| 22 | 4 | 4 | `unresolved` | 0.0% | `220228, 220227, 220226, 220225` |
| 24 | 37 | 35 | `player_head_frame` | 100.0% | `` |
| 25 | 53 | 49 | `interaction_item` | 100.0% | `` |
| 27 | 52 | 52 | `unresolved` | 0.0% | `270108, 270122, 270105, 270101, 270119, 270102, 270106, 270107, 270120, 270019, 270020, 270021, 270001, 270022, 270023, 270024, 270002, 270025, 270026, 270027` |
| 28 | 170 | 5 | `unresolved` | 0.0% | `280002, 280004, 280005, 280001, 280008` |
| 29 | 2 | 2 | `unresolved` | 0.0% | `2101018, 1265019` |

### cn-1.5.20

| 类型 | 引用数 | 不同目标 | 最佳语义 | 覆盖率 | 未解析样本 |
| ---: | ---: | ---: | --- | ---: | --- |
| 1 | 1454 | 108 | `item` | 100.0% | `` |
| 2 | 55 | 27 | `equipment` | 100.0% | `` |
| 3 | 37 | 20 | `ship` | 100.0% | `` |
| 5 | 1728 | 16 | `currency` | 100.0% | `` |
| 6 | 108 | 3 | `unresolved` | 0.0% | `60002, 60000, 60001` |
| 8 | 32 | 19 | `unresolved` | 0.0% | `80247, 80248, 80249, 80118, 89998, 80040, 80044, 80154, 80225, 89999, 80100, 80099, 80101, 80224, 80041, 80146, 80002, 80003, 80238` |
| 10 | 47 | 19 | `unresolved` | 0.0% | `100007, 100022, 100024, 100002, 100001, 100006, 100026, 100025, 100020, 100021, 100008, 100009, 100010, 100017, 100018, 100011, 100019, 100014, 100012` |
| 11 | 73 | 2 | `unresolved` | 0.0% | `110003, 110002` |
| 14 | 4 | 2 | `unresolved` | 0.0% | `140001, 140002` |
| 15 | 105 | 4 | `unresolved` | 0.0% | `150004, 150003, 150002, 150001` |
| 16 | 10 | 9 | `unresolved` | 0.0% | `160023, 168108, 168113, 160020, 160022, 160021, 160024, 168204, 168205` |
| 18 | 1 | 1 | `fashion` | 100.0% | `` |
| 22 | 4 | 4 | `unresolved` | 0.0% | `220228, 220227, 220226, 220225` |
| 24 | 11 | 11 | `player_head_frame` | 100.0% | `` |
| 25 | 32 | 32 | `interaction_item` | 100.0% | `` |

## 日服/国服差异摘要

| 状态 | 表数量 |
| --- | ---: |
| `cn-only` | 3 |
| `content-different` | 55 |
| `identical` | 192 |
| `jp-only` | 45 |
| `records-different` | 144 |
| `schema-different` | 56 |

- 日服独有业务记录：83162
- 国服独有业务记录：7321
- 两服键相同但内容不同：80661
- 两服完全相同记录：125146

完整逐表差异见 `cross-version-differences.csv` 和 `catalog.json`。

## 首期关卡相关表

### jp-1.4.0

- `config_chapter`：202 行（含 1 行元数据），201 行有效 JSON；字段 `activate_by_default`, `belong_chapter_list`, `big_activity_chapter_id`, `changechapterbtnhide`, `chapter_details`, `chapter_open`, `chapter_openname`, `chapter_period`, `chapter_periodarea`, `chapter_plot_type`, `chapter_type`, `class_name`, `class_type`, `coordinate`, `copy_background`, `copy_background_2`, `copy_pos_x`, `copy_pos_y`, `dailygroup_id`, `day_chapter`, `ex_id`, `help_info`, `id`, `is_available`, `is_show`, `level_list`, `leveldetailsbgm`, `memory_id`, `memory_start`, `mubarcopy_chapter_image01`, `mubarcopy_chapter_image02`, `mubarcopy_data`, `name`, `name2`, `new_ocean_tag`, `next_chapter`, `night_chapter`, `open_chapter`, `outpost_id`, `plot_copy_cover`, `plot_locked`, `prev_chapter`, `pve_copy`, `relation_chapter_id`, `reward_times`, `running_level_list`, `show_name`, `star_box`, `star_cond`, `star_reward`, `starbox_cosy`, `starimage`, `starpositionx`, `tactic_type`, `title`, `training_chapter_id`, `treaty_copy`, `treaty_open_copy`
- `config_copy`：1402 行（含 1 行元数据），1401 行有效 JSON；字段 `aerialaeconnaissance_cd`, `airattack_cd`, `angleView`, `battle_airattack_cd`, `battle_anim`, `battle_time`, `blood_range_lower`, `blood_range_upper`, `born_sp_id`, `close_nigh_battle`, `copy_finish_type`, `copy_id`, `copy_scene_length`, `copy_scene_width`, `copy_type`, `cycle_day`, `cycle_night`, `dayNight_switch`, `fleet_id`, `fleet_supple`, `initially_dayNight`, `logic_trigger_array`, `map_fog_hide`, `match_player_num`, `match_type`, `mission_id`, `r_id`, `random_weight`, `recommend`, `report_type`, `resource_id`, `running_fight_evaluation`, `running_fight_level_id`, `running_fight_rate`, `scene_id`, `sea_area_name`, `search_airattack_cd`, `search_bgm`, `series_fleet`, `team_attack_num`, `type_parameter`, `weather_group`
- `config_copy_enemy`：13 行（含 1 行元数据），12 行有效 JSON；字段 `aircraft`, `angle_spped`, `attack`, `battle_angle_speed`, `defence`, `diff_name`, `enmey_type`, `hero_id`, `hp`, `id`, `speed`, `view_range`
- `config_ship`：14 行（含 1 行元数据），13 行有效 JSON；字段 `angle_spped`, `anti_crit`, `attack`, `attack_levelup`, `battle_angle_speed`, `carry_airplane_count`, `crit`, `defense`, `defense_levelup`, `dodge`, `equip_attr_num_1`, `equip_attr_num_2`, `equip_attr_num_3`, `equip_attr_num_4`, `ewt_ids`, `fate`, `gun_range_type`, `hit`, `hp`, `hp_levelup`, `init_star`, `max_star`, `model`, `model_height`, `model_radius`, `s_id`, `ship_air_control`, `ship_air_control_levelup`, `ship_bomb_attack`, `ship_bomb_attack_levelup`, `ship_county`, `ship_icon`, `ship_name`, `ship_torpedo_attack`, `ship_torpedo_attack_levelup`, `ship_type`, `speed`, `to_air_attack`, `to_air_attack_levelup`, `to_torpedo_attack`, `to_torpedo_attack_levelup`, `torpedo_attack`, `torpedo_attack_levelup`, `torpedo_defense`, `torpedo_defense_levelup`, `view_range`
- `config_ship_enemy`：10718 行（含 1 行元数据），10717 行有效 JSON；字段 `angle_speed`, `anti_crit`, `attack`, `backup_plane_count`, `basi_id`, `battle_angle_speed`, `carry_plane_count`, `chase_speed`, `conversion_blood_loss`, `crit`, `damage_coefficient_of_special_air`, `damage_coefficient_of_special_maingun`, `damage_coefficient_of_special_torpedo`, `defense`, `dodge`, `fail_score_percent`, `fate`, `hit`, `hp`, `id`, `isonlyspecial`, `large_blood_loss`, `level`, `lighting_shells_available`, `main_gun_available`, `main_gun_cd`, `main_gun_range`, `main_gun_target_num`, `medium_blood_loss`, `name`, `number_of_special_air_attacks`, `number_of_special_maingun_attacks`, `number_of_special_torpedo_attacks`, `patrol_speed`, `plane_bomb`, `plane_health`, `plane_target_num`, `plane_to_air`, `plane_torpedo`, `projectiles`, `projectiles_cd`, `pskill_id_array`, `safe_score`, `second_gun_available`, `ship_air_control`, `ship_bomb_attack`, `ship_country`, `ship_info_id`, `ship_torpedo_attack`, `sink_blood_loss`, `small_blood_loss`, `special_air_range`, `special_maingun_range`, `special_projectiles`, `special_projectiles_count`, `special_projectiles_times`, `special_torpedo_range`, `specialship_id`, `specialship_type`, `specialstrategy`, `speed`, `st_id`, `to_air_attack`, `to_torpedo_attack`, `torpedo`, `torpedo_available`, `torpedo_defense`, `torpedo_num`, `torpedo_target_num`, `type`, `view_range`, `voyage`

### cn-1.5.20

- `config_chapter`：103 行（含 1 行元数据），102 行有效 JSON；字段 `activate_by_default`, `belong_chapter_list`, `big_activity_chapter_id`, `chapter_details`, `chapter_open`, `chapter_openname`, `chapter_period`, `chapter_periodarea`, `chapter_plot_type`, `chapter_type`, `class_name`, `class_type`, `coordinate`, `copy_background`, `copy_pos_x`, `copy_pos_y`, `dailygroup_id`, `day_chapter`, `ex_id`, `id`, `is_available`, `is_show`, `level_list`, `leveldetailsbgm`, `memory_id`, `memory_start`, `mubarcopy_chapter_image01`, `mubarcopy_chapter_image02`, `mubarcopy_data`, `name`, `next_chapter`, `night_chapter`, `open_chapter`, `outpost_id`, `plot_copy_cover`, `prev_chapter`, `relation_chapter_id`, `reward_times`, `running_level_list`, `show_name`, `star_box`, `star_cond`, `star_reward`, `starimage`, `starpositionx`, `tactic_type`, `title`, `training_chapter_id`, `treaty_copy`, `treaty_open_copy`
- `config_copy`：1077 行（含 1 行元数据），1076 行有效 JSON；字段 `aerialaeconnaissance_cd`, `airattack_cd`, `angleView`, `battle_airattack_cd`, `battle_anim`, `battle_time`, `blood_range_lower`, `blood_range_upper`, `born_sp_id`, `close_nigh_battle`, `copy_finish_type`, `copy_id`, `copy_scene_length`, `copy_scene_width`, `copy_type`, `cycle_day`, `cycle_night`, `dayNight_switch`, `fleet_id`, `fleet_supple`, `initially_dayNight`, `logic_trigger_array`, `map_fog_hide`, `match_player_num`, `mission_id`, `r_id`, `random_weight`, `recommend`, `report_type`, `resource_id`, `running_fight_evaluation`, `running_fight_level_id`, `running_fight_rate`, `scene_id`, `sea_area_name`, `search_airattack_cd`, `search_bgm`, `series_fleet`, `team_attack_num`, `type_parameter`, `weather_group`
- `config_copy_enemy`：13 行（含 1 行元数据），12 行有效 JSON；字段 `aircraft`, `angle_spped`, `attack`, `battle_angle_speed`, `defence`, `diff_name`, `enmey_type`, `hero_id`, `hp`, `id`, `speed`, `view_range`
- `config_ship`：14 行（含 1 行元数据），13 行有效 JSON；字段 `angle_spped`, `anti_crit`, `attack`, `attack_levelup`, `battle_angle_speed`, `carry_airplane_count`, `crit`, `defense`, `defense_levelup`, `dodge`, `equip_attr_num_1`, `equip_attr_num_2`, `equip_attr_num_3`, `equip_attr_num_4`, `ewt_ids`, `fate`, `gun_range_type`, `hit`, `hp`, `hp_levelup`, `init_star`, `max_star`, `model`, `model_height`, `model_radius`, `s_id`, `ship_air_control`, `ship_air_control_levelup`, `ship_bomb_attack`, `ship_bomb_attack_levelup`, `ship_county`, `ship_icon`, `ship_name`, `ship_torpedo_attack`, `ship_torpedo_attack_levelup`, `ship_type`, `speed`, `to_air_attack`, `to_air_attack_levelup`, `to_torpedo_attack`, `to_torpedo_attack_levelup`, `torpedo_attack`, `torpedo_attack_levelup`, `torpedo_defense`, `torpedo_defense_levelup`, `view_range`
- `config_ship_enemy`：9836 行（含 1 行元数据），9835 行有效 JSON；字段 `angle_speed`, `anti_crit`, `attack`, `backup_plane_count`, `basi_id`, `battle_angle_speed`, `carry_plane_count`, `chase_speed`, `conversion_blood_loss`, `crit`, `damage_coefficient_of_special_air`, `damage_coefficient_of_special_maingun`, `damage_coefficient_of_special_torpedo`, `defense`, `dodge`, `fail_score_percent`, `fate`, `hit`, `hp`, `id`, `isonlyspecial`, `large_blood_loss`, `level`, `lighting_shells_available`, `main_gun_available`, `main_gun_cd`, `main_gun_range`, `main_gun_target_num`, `medium_blood_loss`, `name`, `number_of_special_air_attacks`, `number_of_special_maingun_attacks`, `number_of_special_torpedo_attacks`, `patrol_speed`, `plane_bomb`, `plane_health`, `plane_target_num`, `plane_to_air`, `plane_torpedo`, `projectiles`, `projectiles_cd`, `pskill_id_array`, `safe_score`, `second_gun_available`, `ship_air_control`, `ship_bomb_attack`, `ship_country`, `ship_info_id`, `ship_torpedo_attack`, `sink_blood_loss`, `small_blood_loss`, `special_air_range`, `special_maingun_range`, `special_projectiles`, `special_projectiles_count`, `special_projectiles_times`, `special_torpedo_range`, `specialship_id`, `specialship_type`, `specialstrategy`, `speed`, `st_id`, `to_air_attack`, `to_torpedo_attack`, `torpedo`, `torpedo_available`, `torpedo_defense`, `torpedo_num`, `torpedo_target_num`, `type`, `view_range`, `voyage`

完整逐表结果见 `tables.csv`，机器可读字段与样本见 `catalog.json`。

## 首个离线闭环基准关卡

当前固定序章 `0-4`（日服“初阵”、国服“初战”）作为首个战斗基准。两服关键 ID 一致、等级限制为 1，普通分支只有一个敌方舰队和一艘敌舰。

```text
config_chapter 1 -> level_list 包含 4
config_copy_display 4 -> copy_index 0-4, first_reward 509035
config_copy 40 -> scene_id 10000, fleet_id [200401]
config_fleet 200401 -> copy_enemys [100000]
config_ship_enemy 100000 -> level 1, hp 238, attack 1, defense 5
config_assist_fleet 1 -> formation 1, assist_ship_info [10002101]
config_assist_ship_info 10002101 -> level 10 story-only Oakland
config_rewards 509035 -> ship reward [[3, 20210111, 1]] -> 天龙 x1
```

完整机器可读定义见 `baseline-stage.json`。类型 `1/2/3/5` 已分别以 100% 目标表覆盖率映射为道具、装备、船只和货币。
