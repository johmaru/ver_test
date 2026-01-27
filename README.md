## 構造

3ステージのパイプラインを備えたRISC-V32I派生プロセッサ。

Fetch/Decode・Execute/WBの3ステージ。

## 最終目標

1. エミュレータでの動作確認
2. FPGA開発ボード実機での動作確認


## エミュレート

```bash
iverilog -g2012 -o sim.out `
  .\top.v `
  .\rtl\alu.v `
  .\rtl\stages\fetch.v `
  .\rtl\stages\dec.v `
  .\tb_cpu_top.v
```

```bash
vvp .\sim.out
```