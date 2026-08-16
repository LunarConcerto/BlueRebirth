# IL2CPP Metadata Registration 候选

本目录由 `--analyze-il2cpp` 只读生成。候选必须同时满足 x86 registration 的 8 组 count/pointer 结构、PE 地址映射和 `Il2CppType` 抽样校验。

## jp-1.4.0

- ImageBase: `0x10000000`
- 最大字段 typeIndex: `63183`
- 候选数: `1`，强候选: `1`

- `strong` registration RVA `0x01b1b878`, types `63429`, types VA `0x1179e008`, 抽样 `257/257`，score `134.00`

## cn-1.5.20

- ImageBase: `0x10000000`
- 最大字段 typeIndex: `62291`
- 候选数: `1`，强候选: `1`

- `strong` registration RVA `0x01ad6368`, types `62533`, types VA `0x11747210`, 抽样 `257/257`，score `134.00`

`candidate` 不能直接作为注入地址；只有经过交叉引用或运行时基址验证后才能进入版本适配器。
