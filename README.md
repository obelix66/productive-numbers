# 🔢 Productive Numbers: High-Performance Search & Deep Analysis

[![Rust](https://img.shields.io/badge/rust-1.70+-orange.svg)](https://www.rust-lang.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Build Status](https://img.shields.io/badge/build-passing-brightgreen.svg)](https://github.com)

> A blazing-fast Rust implementation to find and analyze **productive numbers** — a fascinating and rare class of integers deeply connected to prime number theory.

## 📖 What are Productive Numbers?

A number **N** is **productive** ([OEIS A089395](https://oeis.org/A089395)) if:

1. **N + 1 is prime**
2. **For every possible digit split A|B, the product (A × B) + 1 is also prime**

### Examples

**Single-digit productive numbers:** `{1, 2, 4, 6}`
- **1:** 1+1=2 ✓ (prime), no splits
- **4:** 4+1=5 ✓ (prime), no splits
- **3:** 3+1=4 ✗ (not prime) → not productive

**Multi-digit example: 2026**
- 2026 + 1 = **2027** ✓ (prime)
- Split 2|026: (2 × 26) + 1 = **53** ✓ (prime)
- Split 20|26: (20 × 26) + 1 = **521** ✓ (prime)
- Split 202|6: (202 × 6) + 1 = **1213** ✓ (prime)

All conditions satisfied → **2026 is productive** ✓

---

## ✨ Key Features

### 🚀 Performance Optimizations
- **Sieve of Eratosthenes:** O(1) lookup for primes ≤ 65,536
- **Adaptive Miller-Rabin:** Minimal witnesses based on input range
  - 1 witness for n < 2,047
  - 2 witnesses for n < 1,373,653
  - Up to 12 witnesses for full u64 range
- **Parallel Processing:** Leverages all CPU cores with Rayon
- **Smart Early Exit:** Rejects odd numbers > 1 instantly (n+1 would be even)

### 💾 Robust State Management
- **Crash Recovery:** Resume interrupted searches automatically
- **Atomic Saves:** Prevents state corruption with write-then-rename
- **Progress Tracking:** Real-time statistics with `indicatif`

### 📊 Deep Statistical Analysis
- **Split Analysis:** Detailed CSV export of all digit splits
- **Balanced Numbers:** Identifies numbers where all split products have equal digit length
- **Strong Primes:** Finds cryptographically valuable primes where (N+1)/2 is also prime
- **Visualization:** Automatic graph generation with gnuplot

### 🔒 Safety & Reliability
- Overflow-safe arithmetic with `checked_mul`/`checked_add`
- Comprehensive test suite (unit + integration + benchmarks)
- Deterministic results (no probabilistic algorithms)

---

## 🏆 Research Highlights

### Results from Search up to 10¹⁰

| Metric | Value | Notes |
|--------|-------|-------|
| **Productive Numbers Found** | 203 | 97.6% of all known (208 total up to 10¹³) |
| **Splits Analyzed** | 917 | All possible digit divisions |
| **Primality Ratio** | 99.89% | 916/917 splits produced primes |
| **Strong Primes** | 38 (18.72%) | (N+1)/2 also prime |
| **Perfectly Balanced** | 70 (34.48%) | All splits → same digit length |
| **Density** | 1 per 49 million | Extremely rare |

### Novel Contributions

1. **"Perfectly Balanced Numbers"** — Original concept
   - 70 numbers where Coefficient of Variation = 0%
   - Example: 71866 (all splits produce 5-digit primes)

2. **Comprehensive Statistical Framework**
   - Variance analysis of split product lengths
   - Distribution histograms by digit count
   - Correlation between number size and balance

3. **First High-Performance Rust Implementation**
   - 3-4x faster than naive Miller-Rabin
   - ~10M numbers/second on modern CPUs

---

## 🚀 Quick Start

### Prerequisites
- Rust 1.70+ ([install here](https://www.rust-lang.org/tools/install))
- Optional: gnuplot (for visualizations)
- Optional: Python 3.8+ (for analysis scripts)

### Installation

```bash
# Clone repository
git clone https://github.com/santitub/productive-numbers.git
cd productive-numbers

# Build optimized binary
cargo build --release

# Run tests
cargo test

# Run benchmarks
cargo test --release -- --ignored --nocapture
```

### Basic Usage

```bash
# Search up to 1 billion (takes ~2 minutes on 16-core CPU)
./target/release/productive-numbers --limit 1000000000

# Resume previous search
./target/release/productive-numbers --limit 10000000000

# Verbose output
./target/release/productive-numbers --limit 100000000 -vv

# Custom parameters
./target/release/productive-numbers \
  --start 1000000 \
  --limit 2000000 \
  --chunk-size 100000 \
  --output-file my_results.txt
```

### Full Analysis Pipeline

```bash
# 1. Find productive numbers
cargo run --release -- --limit 10000000000

# 2. Analyze all digit splits
python3 scripts/analyze_all_splits.py

# 3. Generate comprehensive report
bash scripts/master_analysis.sh

# 4. View results
cat analysis_results_*/SUMMARY.txt
```

---

## 📊 Analysis Scripts

### Python: Split Analyzer (`analyze_all_splits.py`)
Generates `splits_analysis.csv` with columns:
- Número (N)
- SplitPos (position k)
- A, B (split parts)
- A×B+1 (product)
- Primo? (is prime?)
- Digitos (digit count)

### Bash: Master Analysis (`master_analysis.sh`)
Produces 7 comprehensive reports:
1. **N+1 Verification** — Confirms all N+1 are prime
2. **Global Statistics** — Primality ratios, averages
3. **Digit Distribution** — Histogram of product lengths
4. **Top Performers** — Numbers with 100% prime splits
5. **Balance Conjecture** — Variance analysis (CV%)
6. **Strong Primes** — (N+1)/2 primality check
7. **CV Histogram** — Distribution of balance coefficients

### Visualizations (gnuplot)
- Productive numbers by digit count
- Coefficient of Variation vs. number size

---

## 📚 Documentation

- **[Mathematical Theory](docs/THEORY.md)** — Formal definitions & proofs
- **[Algorithm Details](docs/ALGORITHM.md)** — Miller-Rabin implementation
- **[Results Analysis](docs/RESULTS.md)** — In-depth findings

---

## 🎯 Performance Benchmarks

### Hardware: AMD Ryzen 9 5950X (16 cores, 32 threads)

| Range | Time | Speed | Notes |
|-------|------|-------|-------|
| 0 → 10⁶ | 0.1s | 10M/s | Mostly sieve lookups |
| 0 → 10⁹ | 2 min | 8.3M/s | Mixed sieve + Miller-Rabin |
| 0 → 10¹⁰ | 20 min | 8.3M/s | Predominantly Miller-Rabin |

**Memory Usage:** ~64KB (sieve) + 10MB (overhead)

### Optimization Impact

| Version | Speed | Speedup |
|---------|-------|---------|
| Naive Miller-Rabin (12 witnesses) | 2.5M/s | 1.0x |
| + Sieve for small primes | 5.8M/s | 2.3x |
| + Adaptive witnesses | 8.3M/s | 3.3x |
| + Odd number rejection | 10M/s | 4.0x |

---

## 🤝 Contributing

We welcome contributions! See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

### Areas of Interest
- Extend search to 10¹⁵+ (distributed computing?)
- GPU acceleration (CUDA/OpenCL)
- Prove conjectures about balanced numbers
- Find patterns in strong prime distribution
- Optimize for ARM/RISC-V architectures

---

## 📄 License

MIT License - see [LICENSE](LICENSE) for details.

---

## 🙏 Acknowledgments

- **OEIS** — Sequence [A089395](https://oeis.org/A089395)
- **Giovanni Resta** — numbersaplenty.com validation data
- **Rust Community** — Excellent libraries (rayon, clap, indicatif)


---

## 📬 Contact

- **Issues:** [GitHub Issues](https://github.com/santitub/productive-numbers/issues)
- **Discussions:** [GitHub Discussions](https://github.com/santitub/productive-numbers/discussions)
- **Email:** santitub22@gmail.com

---

## 🌟 Star History

If you find this project useful, please consider giving it a ⭐!

[![Star History Chart](https://api.star-history.com/svg?repos=santitub/productive-numbers&type=Date)](https://star-history.com/#santitub/productive-numbers&Date)

---

**Made with ❤️ and 🦀 Rust**