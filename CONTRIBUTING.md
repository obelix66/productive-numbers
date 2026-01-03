# Contributing to Productive Numbers

Thank you for considering contributing to this project! 🎉

## 🌟 Ways to Contribute

### 1. Report Bugs 🐛
Found a bug? Please [open an issue](https://github.com/Santitub/productive-numbers/issues) with:
- **Clear title** (e.g., "Miller-Rabin fails for n=561")
- **Steps to reproduce**
- **Expected vs. actual behavior**
- **Environment** (OS, Rust version, CPU)

### 2. Suggest Enhancements 💡
Have an idea? Open an issue tagged with `enhancement`:
- **Problem:** What limitation are you addressing?
- **Solution:** Proposed approach
- **Alternatives:** Other options considered
- **Impact:** Performance/usability improvements

### 3. Submit Pull Requests 🔧
Code contributions are welcome! See [Development Workflow](#development-workflow) below.

### 4. Improve Documentation 📚
- Fix typos or clarify explanations
- Add examples or tutorials
- Translate documentation

### 5. Share Results 📊
Found interesting patterns? Share your discoveries in [Discussions](https://github.com/Santitub/productive-numbers/discussions)!

---

## 🛠️ Development Workflow

### Setup

```bash
# Fork and clone your fork
git clone https://github.com/Santitub/productive-numbers.git
cd productive-numbers

# Create feature branch
git checkout -b feature/your-feature-name

# Install dependencies
cargo build

# Run tests
cargo test
```

### Making Changes

1. **Write tests first** (TDD approach recommended)
   ```rust
   #[test]
   fn test_your_new_feature() {
       assert_eq!(your_function(42), expected_value);
   }
   ```

2. **Implement your changes**
   - Follow existing code style (use `rustfmt`)
   - Add comments for complex logic
   - Update documentation strings

3. **Run full test suite**
   ```bash
   cargo test --all
   cargo test --release -- --ignored  # Benchmarks
   cargo clippy -- -D warnings        # Linter
   cargo fmt --check                  # Format check
   ```

4. **Commit with clear messages**
   ```bash
   git commit -m "feat: add GPU acceleration support"
   ```

   Use [Conventional Commits](https://www.conventionalcommits.org/):
   - `feat:` new feature
   - `fix:` bug fix
   - `docs:` documentation only
   - `perf:` performance improvement
   - `test:` adding tests
   - `refactor:` code restructuring

### Submitting PR

1. **Push to your fork**
   ```bash
   git push origin feature/your-feature-name
   ```

2. **Open Pull Request** with:
   - **Clear title:** "feat: add GPU acceleration support"
   - **Description:**
     - What changes were made?
     - Why (link to issue if applicable)?
     - How to test?
   - **Checklist:**
     - [ ] Tests pass locally
     - [ ] Code follows style guide
     - [ ] Documentation updated
     - [ ] CHANGELOG.md updated (if applicable)

3. **Respond to feedback**
   - Address review comments promptly
   - Push updates to the same branch
   - Be open to suggestions

---

## 📋 Code Style Guide

### Rust Guidelines

```rust
// ✅ Good
/// Checks if a number is productive.
///
/// # Examples
/// ```
/// assert!(is_productive(2026));
/// ```
#[inline]
pub fn is_productive(n: u64) -> bool {
    if n == 0 {
        return false;
    }
    // ... implementation
}

// ❌ Bad
pub fn is_productive(n:u64)->bool{if n==0{return false;}/*...*/}
```

**Rules:**
- Use `rustfmt` (automatic formatting)
- Follow [Rust API Guidelines](https://rust-lang.github.io/api-guidelines/)
- Document public functions with `///`
- Use meaningful variable names (not `x`, `y`, `z`)
- Prefer explicit error handling over `unwrap()`

### Python Guidelines (for scripts)

```python
# ✅ Good
def analyze_splits(numbers: List[int]) -> Dict[str, Any]:
    """
    Analyze digit splits of productive numbers.
    
    Args:
        numbers: List of productive numbers to analyze
        
    Returns:
        Dictionary with analysis results
    """
    results = {}
    for n in numbers:
        # ... implementation
    return results

# ❌ Bad
def f(n):
    r={}
    for x in n:r[x]=x+1
    return r
```

**Rules:**
- Follow [PEP 8](https://peps.python.org/pep-0008/)
- Use type hints
- Document with docstrings
- Use descriptive names

---

## 🧪 Testing Guidelines

### Unit Tests

```rust
#[test]
fn test_is_prime_small() {
    assert!(is_prime(2));
    assert!(is_prime(3));
    assert!(!is_prime(4));
}

#[test]
fn test_is_prime_carmichael() {
    // Carmichael numbers fool Fermat test
    assert!(!is_prime(561));  // 3 × 11 × 17
}
```

**Coverage goals:**
- Edge cases (0, 1, u64::MAX)
- Boundary values (sieve limit, witness thresholds)
- Known tricky inputs (Carmichael numbers)
- Performance regressions (benchmarks)

### Integration Tests

```rust
#[test]
#[ignore]
fn test_search_up_to_100k() {
    let results: Vec<u64> = (1..100_000)
        .filter(|&n| is_productive(n))
        .collect();
    
    assert_eq!(results.len(), 95); // Known count
    assert!(results.contains(&2026));
}
```

### Benchmarks

```rust
#[test]
#[ignore]
fn benchmark_is_prime() {
    use std::time::Instant;
    
    let start = Instant::now();
    let count: usize = (1..1_000_000)
        .filter(|&n| is_prime(n))
        .count();
    let elapsed = start.elapsed();
    
    println!("Found {} primes in {:?}", count, elapsed);
    assert!(elapsed.as_secs() < 1); // Should be fast
}
```

---

## 🎯 Priority Areas

### High Priority 🔥
1. **GPU Acceleration** — CUDA/OpenCL implementation
2. **Distributed Search** — MPI/cluster support for 10¹⁵+
3. **Proof of Balanced Numbers Conjecture** — Mathematical analysis

### Medium Priority 📊
4. **ARM Optimization** — SIMD for Apple Silicon / Raspberry Pi
5. **Web Interface** — WASM + interactive visualization
6. **Database Backend** — PostgreSQL for large-scale storage

### Low Priority 💡
7. **Additional languages** — C++/Julia ports
8. **Educational content** — Video tutorials, blog posts

---

## 🚫 What NOT to Contribute

- **Probabilistic primality tests** — We require deterministic results
- **Breaking API changes** — Discuss in issue first
- **Unrelated features** — Keep focus on productive numbers
- **Code without tests** — All features need test coverage

---

## 📊 Performance Requirements

### Benchmarks Must Pass

```bash
cargo bench

# Minimum acceptable performance:
# - is_prime (n < 1M):   > 5M checks/sec
# - is_productive (1M):  > 50K checks/sec
# - Full search to 10⁹:  < 5 minutes (16-core CPU)
```

### Regression Prevention
- PRs must not slow down existing operations by >5%
- Use `cargo flamegraph` to profile changes
- Document trade-offs (e.g., memory vs. speed)

---

## 🏅 Recognition

Contributors will be:
- Listed in README.md acknowledgments
- Credited in CHANGELOG.md
- Eligible for "Contributor" badge on GitHub

Significant contributions may result in co-authorship on any future research papers.

---

## 📜 Code of Conduct

### Our Pledge
We are committed to providing a welcoming and inclusive environment for all contributors, regardless of:
- Age, body size, disability, ethnicity
- Gender identity and expression
- Level of experience
- Nationality, personal appearance
- Race, religion, sexual identity/orientation

### Our Standards

**Examples of positive behavior:**
- Using welcoming and inclusive language
- Respecting differing viewpoints
- Gracefully accepting constructive criticism
- Focusing on what's best for the community

**Unacceptable behavior:**
- Trolling, insulting/derogatory comments
- Public or private harassment
- Publishing others' private information
- Other conduct reasonably considered inappropriate

### Enforcement
Instances of unacceptable behavior may be reported to [your-email@example.com]. All complaints will be reviewed and investigated confidentially.

---

## ❓ Questions?

- **Technical questions:** [GitHub Discussions](https://github.com/Santitub/productive-numbers/discussions)
- **Bug reports:** [GitHub Issues](https://github.com/Santitub/productive-numbers/issues)
- **Private inquiries:** santitub22@gmail.com

---

## 📚 Resources

### Learning Rust
- [The Rust Book](https://doc.rust-lang.org/book/)
- [Rust by Example](https://doc.rust-lang.org/rust-by-example/)
- [Rustlings](https://github.com/rust-lang/rustlings) (exercises)

### Number Theory
- [Prime Numbers and the Riemann Hypothesis](https://bookstore.ams.org/mbk-134/) (Mazur & Stein)
- [OEIS A089395](https://oeis.org/A089395) (sequence documentation)
- [Miller-Rabin Primality Test](https://en.wikipedia.org/wiki/Miller%E2%80%93Rabin_primality_test)

### Optimization
- [Rust Performance Book](https://nnethercote.github.io/perf-book/)
- [cargo-flamegraph](https://github.com/flamegraph-rs/flamegraph) (profiling)

---

**Thank you for contributing! 🚀**