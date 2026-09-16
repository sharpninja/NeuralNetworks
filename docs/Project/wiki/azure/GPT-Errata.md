# Neural Networks C64 disk: comparison and errata

Checked: 2026-09-16 14:34 UTC.

**Two confirmed disk-versus-listing discrepancies were found: three trailing zero bytes are absent from the two machine-language files.** The five files in [Neural-Networks-C64.d64](Neural-Networks-C64.d64) are byte-for-byte copies of their source magazine-disk files. The omissions therefore predate this compilation.

The D64 and its programs were left unchanged.

## 1. BP.ML: final printed byte is absent

- Source: COMPUTE!'s Gazette, February 1990, printed page 39, last row of Program 1, BP. The MLX instructions on page 35 specify `$C000` through `$CFFF`.
- Printed final row: `CFF8: 00 00 00 00 54 45 00 00 50`.
- The last `50` is the MLX checksum, not program data.
- Disk file: load address `$C000`, 4,095 payload bytes, ending at `$CFFE`. Total PRG size, including its two-byte load address: **4,097 bytes**.
- Discrepancy: the printed `00` at **`$CFFF`** is absent.
- A file containing the complete printed range would have 4,096 payload bytes and a total PRG size of **4,098 bytes**. Appending one `00` byte would supply the missing address without changing the existing bytes or load address.

## 2. CL.ML: final two printed bytes are absent

- Source: COMPUTE!'s Gazette, March 1990, printed page 45, last row of CL. The MLX instructions on page 43 specify `$C000` through `$C98F`.
- Printed final row: `C988: 00 00 00 54 45 00 00 00 8B`.
- The last `8B` is the MLX checksum, not program data.
- Disk file: load address `$C000`, 2,446 payload bytes, ending at `$C98D`. Total PRG size: **2,448 bytes**.
- Discrepancy: the printed `00 00` at **`$C98E` and `$C98F`** is absent.
- A file containing the complete printed range would have 2,448 payload bytes and a total PRG size of **2,450 bytes**. Appending two `00` bytes would supply the missing addresses without changing the existing bytes or load address.

These are confirmed file-length differences. Loading the shorter files does not write the omitted addresses. Their effect on execution was not tested, so this report does not classify them as harmless padding or as demonstrated runtime bugs.

## Results for all five files

- **XOR:** 28 BASIC lines, printed page 39 of February 1990. All 28 printed Automatic Proofreader checksums match. No discrepancy found.
- **ENCODE:** 41 BASIC lines, the same printed page. All 41 printed checksums match. No discrepancy found.
- **DIPOLE:** 62 BASIC lines, printed pages 45-46 of March 1990. All 62 printed checksums match. No discrepancy found.
- **BP.ML:** 512 MLX rows, printed pages 37-39 of February 1990. All 512 printed checksums match when the one missing final zero is supplied **only in the comparison buffer**.
- **CL.ML:** 306 MLX rows, printed pages 44-45 of March 1990. All 306 printed checksums match when the two missing final zeros are supplied **only in the comparison buffer**.

Total coverage: **131/131 BASIC line checksums and 818/818 MLX row checksums**. The machine-language listings specify 6,544 payload bytes; the two disk files contain 6,541.

The January installment contains no type-in program for this series.

## Method and limits

1. Extracted all five files afresh from the delivered D64 with VICE `c1541` 3.10. Compared their complete byte sequences with fresh extractions from the original February and March disk images: **5/5 identical**.
2. Detokenized the BASIC files and reproduced the Automatic Proofreader calculation from the magazine disk's own utility. Compared every line with the printed two-letter checksum. Quoted spaces, PETSCII control bytes, shifted letters, and line numbers were included; spaces outside quotation marks were ignored according to the utility's rules.
3. Reproduced the MLX checksum calculation from the February disk's `64 mlx` utility. Compared every eight-byte row with its printed checksum. Used OCR for the scan, then visually resolved 31 unclear checksum readings and one row omitted by a crop. Missing trailing bytes were explicitly recorded, not silently treated as present in the disk files.
4. Checked the final rows against the original page images. The two final-row quotations above are transcribed from those images.

Underlined letters in the magazine represent shifted characters. The disk's mixed-case messages and the magazine's uppercase typography do not constitute a program discrepancy. Likewise, brace notation such as `{CLR}` and `{HOME}` represents control bytes, not literal braces in the program.

This is a complete comparison of the magazine's published check values, supported by scan inspection. Those checksums are eight-bit values and can collide; their agreement is not a cryptographic proof that every printed character was independently transcribed correctly. No C64 execution or neural-network training run was performed. No separate independent reviewer was run.

## Audit records and sources

- [Per-line BASIC results](Neural-Networks-C64-BASIC-Checks.csv)
- [Per-address MLX results](Neural-Networks-C64-MLX-Checks.csv), including the final-row padding disclosure
- [Combined article scans and OCR](Future-Computing-Neural-Networks-Parts-1-2-3-OCR.pdf): February listings are PDF pages 7-9; March listings are PDF pages 12-14.
- [Original magazine disk collection](https://commodore.bombjack.org/commodore/magazines-disk/compute-gazette/compute-gazette-disk.htm). February source: `1990-02-good.d64`. March source: `1990-03.d64` from `Compute!'s_Gazette_Disks_(04-21-2024).zip`.
- [Publisher's explanation of the Automatic Proofreader](https://www.atarimagazines.com/compute/issue70/096_1_The_New_Automatic_Proofreader_For_Commodore.php), including its treatment of spaces and line-number-dependent checksum.

The unchanged D64 is 174,848 bytes, with five PRG entries and 623 blocks free.

SHA-256:

```text
fc73b0d8580569dd71aa240511011861cba4fdcc15636f90e4d615e33d20a183  Neural-Networks-C64.d64
571ef6326bc83e39fefd4d9c446405a4510b2d9f9d9279c77ba23ba4f6bf4274  BP.ML.prg
b436bac31257da8f9508c3908a7e9d4baba0c7c3d1876ba67d0927b72a4d56cb  CL.ML.prg
35a8a72c0296aed6c87db8fa4910825fd64f0c0cba036be103f162a76a1b9b43  XOR.prg
d6aa27f72d204edb8a459a088e29186889551e065ccca9555f51c3ef041c9e80  ENCODE.prg
88555de12d7ee5a09f1572d0de1d3e503cf187570e16702d716b8a37515064b1  DIPOLE.prg
```
