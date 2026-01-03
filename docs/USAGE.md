# Usage Guide - Productive Numbers

Complete guide for using the productive numbers search and analysis suite.

---

## 🚀 Quick Start

### 1. Build the Project

```bash
# Debug build (faster compilation, slower execution)
cargo build

# Release build (slower compilation, 3-4x faster execution)
cargo build --release
```

### 2. Basic Search

```bash
# Search up to 1 million (takes ~10 seconds)
./target/release/productive-numbers --limit 1000000

# Search with custom parameters
./target/release/productive-numbers \
  --start 1000000 \
  --limit 2000000 \
  --chunk-size 100000 \
  --output-file my_results.txt \
  --state-file my_state.json
```

### 3. Run Analysis

```bash
# Full analysis pipeline (requires found.txt)
bash scripts/master_analysis.sh

# Manual verification
bash scripts/verify_results.sh
```

---

## 📖 Command-Line Options

### Main Search Program

```bash
./target/release/productive-numbers [OPTIONS]

OPTIONS:
  -s, --start <START>           Starting number [default: 1]
  -l, --limit <LIMIT>           Maximum search limit [default: 1000000000]
  --chunk-size <SIZE>           Parallel chunk size [default: 500000]
  --output-file <FILE>          Output file [default: found.txt]
  --state-file <FILE>           State file [default: state.json]
  --fresh                       Ignore saved state, start fresh
  -q, --quiet                   Quiet mode (no progress bar)
  -v, --verbose                 Verbose output (-v, -vv, -vvv)
  -h, --help                    Print help
  -V, --version                 Print version
```

### Verbosity Levels

```bash
# No verbosity (default)
./target/release/productive-numbers --limit 1000000

# Level 1: Show numbers as found
./target/release/productive-numbers --limit 1000000 -v

# Level 2: Show state saves
./target/release/productive-numbers --limit 1000000 -vv

# Level 3: Show debug info (chunks, etc.)
./target/release/productive-numbers --limit 1000000 -vvv
```

---

## 🎯 Common Use Cases

### Use Case 1: Quick Test

```bash
# Find productive numbers up to 10,000 (should find ~9 numbers)
cargo run --release -- --limit 10000
```

**Expected output:**
```
Numbers found: 1, 2, 4, 6, 12, 16, 22, 28, 36, ...
```

### Use Case 2: Resume Interrupted Search

```bash
# Start search
./target/release/productive-numbers --limit 10000000000

# Press Ctrl+C to interrupt

# Resume from where it stopped
./target/release/productive-numbers --limit 10000000000
```

The program automatically loads `state.json` and continues.

### Use Case 3: Multiple Ranges

```bash
# Search range 1: 0 to 1 billion
./target/release/productive-numbers \
  --limit 1000000000 \
  --output-file range1.txt \
  --state-file state1.json

# Search range 2: 1 billion to 2 billion
./target/release/productive-numbers \
  --start 1000000000 \
  --limit 2000000000 \
  --output-file range2.txt \
  --state-file state2.json

# Combine results
cat range1.txt range2.txt | sort -n | uniq > found.txt
```

### Use Case 4: Fresh Start

```bash
# Ignore previous state, start from scratch
./target/release/productive-numbers --limit 1000000 --fresh
```

---

## 📊 Analysis Pipeline

### Full Analysis

```bash
# 1. Generate CSV of all splits (Python)
python3 scripts/analyze_all_splits.py

# 2. Run master analysis (Bash)
bash scripts/master_analysis.sh

# 3. View results
ls -lh analysis_results_*/
cat analysis_results_*/SUMMARY.txt
```

### Output Files

After running `master_analysis.sh`, you'll get:

```
analysis_results_YYYYMMDD_HHMMSS/
├── n_plus_one_verification.txt    # N+1 primality check
├── splits_global_stats.txt        # Overall statistics
├── prime_product_digits.txt       # Digit distribution
├── top_performers.txt             # 100% prime splits
├── balance_conjecture.txt         # Variance analysis
├── balance_table.txt              # Detailed balance table
├── strong_primes.txt              # (N+1)/2 prime check
├── cv_histogram.txt               # Coefficient of variation
├── SUMMARY.txt                    # Executive summary
├── digits_distribution.png        # Graph (if gnuplot)
└── size_vs_balance.png            # Graph (if gnuplot)
```

### Verification

```bash
# Run verification tests
bash scripts/verify_results.sh
```

**Tests performed:**
1. Single-digit numbers: {1, 2, 4, 6}
2. Number 2026 verification
3. No odd numbers > 1
4. Known strong primes
5. Primality ratio ~99.89%
6. Balanced numbers
7. Total count validation

---

## 🔧 Advanced Usage

### Custom Chunk Size

The chunk size affects parallelism and progress bar updates:

```bash
# Small chunks (more frequent updates, slight overhead)
./target/release/productive-numbers --limit 1000000 --chunk-size 10000

# Large chunks (fewer updates, better throughput)
./target/release/productive-numbers --limit 1000000 --chunk-size 1000000
```

**Recommendation:** 
- Fast CPUs (16+ cores): 500,000 - 1,000,000
- Slower CPUs (4-8 cores): 100,000 - 500,000

### Quiet Mode for Scripts

```bash
# No progress bar, only final results
./target/release/productive-numbers --limit 1000000 --quiet

# Redirect output
./target/release/productive-numbers --limit 1000000 --quiet > log.txt 2>&1
```

### Performance Profiling

```bash
# Install flamegraph
cargo install flamegraph

# Profile release build
cargo flamegraph --release -- --limit 10000000 --quiet

# Open flamegraph.svg in browser
```

---

## 📈 Performance Expectations

### Speed Benchmarks

| Range | Expected Time | Numbers Found | Hardware |
|-------|--------------|---------------|----------|
| 10^6 | 0.1 sec | ~95 | 16-core Ryzen |
| 10^7 | 1 sec | ~120 | 16-core Ryzen |
| 10^8 | 10 sec | ~150 | 16-core Ryzen |
| 10^9 | 2 min | ~185 | 16-core Ryzen |
| 10^10 | 20 min | 203 | 16-core Ryzen |

### Memory Usage

- **Base:** ~64 KB (sieve)
- **Per chunk:** ~10 MB (temporary data)
- **Total:** < 100 MB for typical searches

### CPU Utilization

The program uses **all available CPU cores** via Rayon:

```bash
# Check core usage
htop  # or top

# Limit cores (via rayon environment variable)
RAYON_NUM_THREADS=4 ./target/release/productive-numbers --limit 1000000
```

---

## 🐛 Troubleshooting

### Problem: "state.json is corrupted"

**Solution:**
```bash
# Remove corrupted state
rm state.json

# Restart with --fresh flag
./target/release/productive-numbers --limit 1000000 --fresh
```

### Problem: "No numbers found"

**Possible causes:**
1. Limit too small (try --limit 10000)
2. Start > Limit (check --start parameter)

**Solution:**
```bash
# Verify parameters
./target/release/productive-numbers --start 1 --limit 10000 -v
```

### Problem: Analysis scripts fail

**Common issues:**

1. **Python not found:**
   ```bash
   # Install Python 3
   sudo apt install python3  # Ubuntu/Debian
   brew install python3      # macOS
   ```

2. **found.txt missing:**
   ```bash
   # Run search first
   ./target/release/productive-numbers --limit 10000
   ```

3. **gnuplot missing (optional):**
   ```bash
   # Install gnuplot
   sudo apt install gnuplot  # Ubuntu/Debian
   brew install gnuplot      # macOS
   ```

### Problem: Slow performance

**Optimizations:**

1. **Use release build:**
   ```bash
   cargo build --release
   ./target/release/productive-numbers  # NOT target/debug/
   ```

2. **Adjust chunk size:**
   ```bash
   # Experiment with different sizes
   --chunk-size 1000000  # Larger = better throughput
   ```

3. **Check CPU usage:**
   ```bash
   # Ensure all cores are active
   htop
   ```

---

## 📝 Examples

### Example 1: Educational Demo

```bash
# Find first 10 productive numbers
./target/release/productive-numbers --limit 100 -v

# Manually verify 2026
python3 -c "
n = 2026
print(f'{n}+1 = {n+1}')
print(f'2|026: (2×26)+1 = {2*26+1}')
print(f'20|26: (20×26)+1 = {20*26+1}')
print(f'202|6: (202×6)+1 = {202*6+1}')
"
```

### Example 2: Research Paper Data

```bash
# Complete search up to 10^10 (reproduces published results)
./target/release/productive-numbers --limit 10000000000

# Generate all analysis reports
bash scripts/master_analysis.sh

# Create publication-ready summary
cat analysis_results_*/SUMMARY.txt > paper_data.txt
```

### Example 3: CI/CD Integration

```bash
#!/bin/bash
# smoke_test.sh - Quick validation

./target/release/productive-numbers --limit 10000 --quiet --fresh

if [[ ! -f found.txt ]]; then
  echo "ERROR: found.txt not created"
  exit 1
fi

count=$(wc -l < found.txt)
if [[ $count -lt 5 ]]; then
  echo "ERROR: Expected at least 5 numbers, got $count"
  exit 1
fi

echo "✓ Found $count productive numbers"
bash scripts/verify_results.sh
```

---

## 🔬 Research Tips

### Finding Patterns

```bash
# Analyze digit frequencies
awk '{for(i=1;i<=length($1);i++) digit[substr($1,i,1)]++} 
     END {for(d in digit) print d, digit[d]}' found.txt | sort

# Find largest gaps
awk 'NR>1 {print $1-prev, prev, $1} {prev=$1}' found.txt | sort -n | tail -10

# Distribution by magnitude
awk '{print int(log($1)/log(10))+1}' found.txt | sort -n | uniq -c
```

### Custom Analysis

```python
# read_results.py
with open('found.txt') as f:
    numbers = [int(line) for line in f]

# Your custom analysis here
print(f"Total: {len(numbers)}")
print(f"Mean: {sum(numbers)/len(numbers):.0f}")
print(f"Median: {sorted(numbers)[len(numbers)//2]}")
```

---

## 📚 Additional Resources

- **Theory:** See [THEORY.md](THEORY.md) for mathematical background
- **Algorithm:** See [ALGORITHM.md](ALGORITHM.md) for implementation details
- **Contributing:** See [CONTRIBUTING.md](../CONTRIBUTING.md) for development guidelines

---

**Last Updated:** 2026-2-1