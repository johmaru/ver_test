## 構造

3ステージのパイプラインを備えたRISC-V32I派生プロセッサ。

Fetch/Decode・Execute/WBの3ステージ。

## 最終目標

1. エミュレータでの動作確認
2. FPGA開発ボード実機での動作確認

## エミュレート

```bash
iverilog -g2012 -o sim.out `
  .\top.sv `
  .\rtl\alu.sv `
  .\rtl\stages\fetch.sv `
  .\rtl\stages\dec.sv `
  .\tb_cpu_top.sv `
  .\rtl\regfile.sv,
  .\rtl\hazard.sv,
  .\rtl\stages\execute.sv,
  .\rtl\pipeline_regs.sv,
  .\rtl\imem.sv
```

```bash
vvp .\sim.out
```

GtkWave

```bash
gtkwave .\cpu.vcd
```

## ロードマップ

1. (Done)3ステージ化する
2. RV32Iの命令を揃える(分岐、ジャンプ、即値生成、比較、ハザード)
3. 例外追加(軽いやつ)
4. Load/Store + バイトイネーブル + RAM + MMIOデコード
5. キャッシュ追加
6. 割り込み、タイマー、DMA
