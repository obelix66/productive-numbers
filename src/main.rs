//! # Buscador de Números Productivos - Versión Optimizada
//!
//! Optimizaciones implementadas:
//! - Miller-Rabin con testigos adaptativos según rango
//! - Criba de primos pequeños (≤65536) para lookup O(1)

use std::fs::{File, OpenOptions};
use std::io::{Read, Write};
use std::path::Path;
use std::sync::atomic::{AtomicBool, AtomicU64, Ordering};
use std::sync::{Arc, Mutex, OnceLock};
use std::time::{Duration, Instant};

use chrono::Local;
use clap::Parser;
use indicatif::{ProgressBar, ProgressStyle};
use num_format::{Locale, ToFormattedString};
use rayon::prelude::*;
use serde::{Deserialize, Serialize};

// ============================================================================
//                         CONSTANTES GLOBALES
// ============================================================================

/// Potencias de 10 precalculadas para división rápida de dígitos.
const POWERS_OF_10: [u64; 20] = [
    1,
    10,
    100,
    1_000,
    10_000,
    100_000,
    1_000_000,
    10_000_000,
    100_000_000,
    1_000_000_000,
    10_000_000_000,
    100_000_000_000,
    1_000_000_000_000,
    10_000_000_000_000,
    100_000_000_000_000,
    1_000_000_000_000_000,
    10_000_000_000_000_000,
    100_000_000_000_000_000,
    1_000_000_000_000_000_000,
    10_000_000_000_000_000_000,
];

/// Intervalo mínimo entre guardados de estado
const STATE_SAVE_INTERVAL: Duration = Duration::from_secs(5);

/// Límite de la criba de primos pequeños (64KB de memoria)
const SIEVE_LIMIT: usize = 65536;

// ============================================================================
//                    CRIBA DE PRIMOS PEQUEÑOS (OPT 2)
// ============================================================================

/// Criba de Eratóstenes para primos pequeños.
/// Inicialización lazy, thread-safe, O(1) lookup.
static SMALL_PRIMES_SIEVE: OnceLock<Box<[bool]>> = OnceLock::new();

/// Inicializa la criba de primos hasta SIEVE_LIMIT.
/// Se ejecuta una sola vez al primer uso (~1ms).
fn init_sieve() -> Box<[bool]> {
    let mut is_prime = vec![true; SIEVE_LIMIT + 1];
    is_prime[0] = false;
    is_prime[1] = false;

    let limit_sqrt = (SIEVE_LIMIT as f64).sqrt() as usize + 1;
    for i in 2..=limit_sqrt {
        if is_prime[i] {
            for j in (i * i..=SIEVE_LIMIT).step_by(i) {
                is_prime[j] = false;
            }
        }
    }

    is_prime.into_boxed_slice()
}

/// Obtiene referencia a la criba (inicializa si es necesario).
#[inline]
fn get_sieve() -> &'static [bool] {
    SMALL_PRIMES_SIEVE.get_or_init(init_sieve)
}

// ============================================================================
//                  MILLER-RABIN ADAPTATIVO (OPT 1)
// ============================================================================

/// Exponenciación modular: (base^exp) mod m
/// Usa u128 para evitar overflow en multiplicaciones intermedias.
#[inline(always)]
fn mod_pow(mut base: u128, mut exp: u64, m: u128) -> u128 {
    if m == 1 {
        return 0;
    }

    let mut result: u128 = 1;
    base %= m;

    while exp > 0 {
        if exp & 1 == 1 {
            result = (result * base) % m;
        }
        exp >>= 1;
        base = (base * base) % m;
    }

    result
}

/// Test de Miller-Rabin con testigos específicos.
#[inline]
fn miller_rabin_test(n: u64, d: u64, r: u32, witnesses: &[u64]) -> bool {
    let n_128 = n as u128;
    let nm1_128 = n_128 - 1;

    'witness: for &a in witnesses {
        if a >= n {
            continue;
        }

        let mut x = mod_pow(a as u128, d, n_128);

        if x == 1 || x == nm1_128 {
            continue 'witness;
        }

        for _ in 0..r - 1 {
            x = (x * x) % n_128;
            if x == nm1_128 {
                continue 'witness;
            }
        }

        return false;
    }

    true
}

/// Test de primalidad optimizado.
///
/// Estrategia de 3 niveles:
/// 1. Números ≤ SIEVE_LIMIT: lookup O(1) en criba precalculada
/// 2. División por primos pequeños: descarta ~80% de compuestos
/// 3. Miller-Rabin adaptativo: testigos mínimos según rango de n
///
/// Referencia testigos: https://miller-rabin.appspot.com/
#[inline]
fn is_prime(n: u64) -> bool {
    // Nivel 1: Criba para números pequeños (O(1) lookup)
    if n <= SIEVE_LIMIT as u64 {
        return get_sieve()[n as usize];
    }

    // Nivel 2: Filtros rápidos por divisibilidad
    if n.is_multiple_of(2) {
        return false;
    }
    if n.is_multiple_of(3) {
        return false;
    }
    if n.is_multiple_of(5) {
        return false;
    }
    if n.is_multiple_of(7) {
        return false;
    }
    if n.is_multiple_of(11) {
        return false;
    }
    if n.is_multiple_of(13) {
        return false;
    }
    if n.is_multiple_of(17) {
        return false;
    }
    if n.is_multiple_of(19) {
        return false;
    }
    if n.is_multiple_of(23) {
        return false;
    }
    if n.is_multiple_of(29) {
        return false;
    }
    if n.is_multiple_of(31) {
        return false;
    }
    if n.is_multiple_of(37) {
        return false;
    }

    // Nivel 3: Miller-Rabin con testigos adaptativos
    // Preparar n-1 = 2^r * d
    let mut d = n - 1;
    let mut r = 0u32;
    while d.is_multiple_of(2) {
        d /= 2;
        r += 1;
    }

    // Seleccionar testigos mínimos según rango
    // Cada conjunto garantiza resultados correctos hasta su límite
    let witnesses: &[u64] = if n < 2_047 {
        &[2]
    } else if n < 1_373_653 {
        &[2, 3]
    } else if n < 9_080_191 {
        &[31, 73]
    } else if n < 25_326_001 {
        &[2, 3, 5]
    } else if n < 3_215_031_751 {
        &[2, 3, 5, 7]
    } else if n < 4_759_123_141 {
        &[2, 7, 61]
    } else if n < 1_122_004_669_633 {
        &[2, 13, 23, 1662803]
    } else if n < 2_152_302_898_747 {
        &[2, 3, 5, 7, 11]
    } else if n < 3_474_749_660_383 {
        &[2, 3, 5, 7, 11, 13]
    } else if n < 341_550_071_728_321 {
        &[2, 3, 5, 7, 11, 13, 17]
    } else {
        // Cubre todo el rango u64
        &[2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37]
    };

    miller_rabin_test(n, d, r, witnesses)
}

// ============================================================================
//                      CONFIGURACIÓN CLI (CLAP)
// ============================================================================

fn validate_positive(s: &str) -> Result<u64, String> {
    let value: u64 = s
        .parse()
        .map_err(|_| format!("'{}' no es un número válido", s))?;
    if value == 0 {
        return Err("El valor debe ser mayor que 0".to_string());
    }
    Ok(value)
}

fn validate_chunk_size(s: &str) -> Result<u64, String> {
    let value: u64 = s
        .parse()
        .map_err(|_| format!("'{}' no es un número válido", s))?;
    if value < 1000 {
        return Err("El chunk size debe ser al menos 1000".to_string());
    }
    if value > 100_000_000 {
        return Err("El chunk size no debe exceder 100,000,000".to_string());
    }
    Ok(value)
}

#[derive(Parser, Debug)]
#[command(name = "productive-numbers")]
#[command(author = "Sistema Experto en Rust")]
#[command(version = "2.0.0")]
#[command(about = "🔢 Busca números productivos hasta un límite dado (versión optimizada)")]
#[command(long_about = r#"
Un número N es "productivo" si cumple:
  1. N + 1 es primo
  2. Para cada división A|B de sus dígitos: (A × B) + 1 es primo

Optimizaciones v2.0:
  • Criba de primos para números ≤ 65536 (lookup O(1))
  • Miller-Rabin adaptativo (testigos mínimos según rango)
  • Speedup esperado: 3-4x vs versión anterior
"#)]
struct Args {
    /// Número inicial para comenzar la búsqueda
    #[arg(short, long, default_value_t = 1, value_parser = validate_positive)]
    start: u64,

    /// Límite máximo para la búsqueda
    #[arg(short, long, default_value_t = 1_000_000_000, value_parser = validate_positive)]
    limit: u64,

    /// Archivo para guardar el estado de progreso
    #[arg(long, default_value = "state.json")]
    state_file: String,

    /// Archivo para guardar los números encontrados
    #[arg(long, default_value = "found.txt")]
    output_file: String,

    /// Tamaño del chunk para procesamiento paralelo
    #[arg(long, default_value_t = 500_000, value_parser = validate_chunk_size)]
    chunk_size: u64,

    /// Ignorar estado guardado y empezar desde el inicio
    #[arg(long, default_value_t = false)]
    fresh: bool,

    /// Modo silencioso (sin barra de progreso)
    #[arg(short, long, default_value_t = false)]
    quiet: bool,

    /// Nivel de verbosidad (-v, -vv, -vvv)
    #[arg(short, long, action = clap::ArgAction::Count)]
    verbose: u8,
}

impl Args {
    fn validate(&self) -> Result<(), String> {
        if self.start >= self.limit {
            return Err(format!(
                "El inicio ({}) debe ser menor que el límite ({})",
                self.start, self.limit
            ));
        }
        Ok(())
    }
}

// ============================================================================
//                       ESTADO PERSISTENTE
// ============================================================================

#[derive(Serialize, Deserialize, Debug, Clone)]
struct SearchState {
    last_checked: u64,
    limit: u64,
    found_count: u64,
    timestamp: String,
    #[serde(default = "default_version")]
    version: u32,
}

fn default_version() -> u32 {
    1
}

impl SearchState {
    fn new(start: u64, limit: u64) -> Self {
        Self {
            last_checked: start,
            limit,
            found_count: 0,
            timestamp: current_timestamp(),
            version: 1,
        }
    }

    fn load(path: &str) -> Result<Option<Self>, std::io::Error> {
        if !Path::new(path).exists() {
            return Ok(None);
        }

        let mut file = File::open(path)?;
        let mut contents = String::new();
        file.read_to_string(&mut contents)?;

        match serde_json::from_str(&contents) {
            Ok(state) => Ok(Some(state)),
            Err(e) => {
                eprintln!("⚠️  Error parseando estado guardado: {}", e);
                eprintln!("   Se creará un nuevo estado.");
                Ok(None)
            }
        }
    }

    fn save(&mut self, path: &str) -> std::io::Result<()> {
        self.timestamp = current_timestamp();

        let temp_path = format!("{}.tmp", path);
        let json = serde_json::to_string_pretty(self).map_err(std::io::Error::other)?;

        let mut file = File::create(&temp_path)?;
        file.write_all(json.as_bytes())?;
        file.sync_all()?;

        std::fs::rename(&temp_path, path)?;

        Ok(())
    }
}

fn current_timestamp() -> String {
    Local::now().format("%Y-%m-%d %H:%M:%S").to_string()
}

// ============================================================================
//                    LÓGICA DE NÚMEROS PRODUCTIVOS
// ============================================================================

/// Cuenta los dígitos decimales de un número.
/// Implementación simple con branch prediction óptimo.
#[inline(always)]
fn count_digits(n: u64) -> u32 {
    if n < 10 {
        1
    } else if n < 100 {
        2
    } else if n < 1_000 {
        3
    } else if n < 10_000 {
        4
    } else if n < 100_000 {
        5
    } else if n < 1_000_000 {
        6
    } else if n < 10_000_000 {
        7
    } else if n < 100_000_000 {
        8
    } else if n < 1_000_000_000 {
        9
    } else if n < 10_000_000_000 {
        10
    } else if n < 100_000_000_000 {
        11
    } else if n < 1_000_000_000_000 {
        12
    } else if n < 10_000_000_000_000 {
        13
    } else if n < 100_000_000_000_000 {
        14
    } else if n < 1_000_000_000_000_000 {
        15
    } else if n < 10_000_000_000_000_000 {
        16
    } else if n < 100_000_000_000_000_000 {
        17
    } else if n < 1_000_000_000_000_000_000 {
        18
    } else if n < 10_000_000_000_000_000_000 {
        19
    } else {
        20
    }
}

/// Verifica si un número es "productivo".
///
/// Mantiene checked_mul para seguridad contra overflow.
#[inline]
fn is_productive(n: u64) -> bool {
    if n == 0 {
        return false;
    }

    // Optimización: impares > 1 → N+1 es par > 2 → no primo
    if n > 1 && !n.is_multiple_of(2) {
        return false;
    }

    // Condición 1: N+1 debe ser primo
    if !is_prime(n + 1) {
        return false;
    }

    let num_digits = count_digits(n);

    // Un solo dígito: sin divisiones, condición vacuamente verdadera
    if num_digits == 1 {
        return true;
    }

    // Condición 2: Verificar cada división
    for k in 1..num_digits {
        let divisor = POWERS_OF_10[k as usize];
        let a = n / divisor;
        let b = n % divisor;

        // checked_mul para seguridad (overflow silencioso es peligroso)
        let product = match a.checked_mul(b) {
            Some(p) => p,
            None => return false,
        };

        let candidate = match product.checked_add(1) {
            Some(c) => c,
            None => return false,
        };

        if !is_prime(candidate) {
            return false;
        }
    }

    true
}

// ============================================================================
//                         UTILIDADES
// ============================================================================

macro_rules! log_verbose {
    ($level:expr, $verbosity:expr, $($arg:tt)*) => {
        if $verbosity >= $level {
            eprintln!($($arg)*);
        }
    };
}

// ============================================================================
//                         PROGRAMA PRINCIPAL
// ============================================================================

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let args = Args::parse();

    if let Err(e) = args.validate() {
        eprintln!("❌ Error en argumentos: {}", e);
        std::process::exit(1);
    }

    let verbosity = args.verbose;
    log_verbose!(2, verbosity, "DEBUG: Argumentos parseados: {:?}", args);

    // Pre-inicializar criba (evita latencia en primer chunk)
    let _ = get_sieve();
    log_verbose!(
        1,
        verbosity,
        "✓ Criba de primos inicializada ({} bytes)",
        SIEVE_LIMIT
    );

    // Configurar Ctrl+C
    let running = Arc::new(AtomicBool::new(true));
    let r = running.clone();

    ctrlc::set_handler(move || {
        eprintln!("\n\n⚠️  Interrupción detectada (Ctrl+C)");
        eprintln!("📁 Guardando estado antes de salir...");
        r.store(false, Ordering::SeqCst);
    })?;

    // Cargar o crear estado
    let mut state = if args.fresh {
        println!("🆕 Iniciando búsqueda nueva (--fresh)");
        SearchState::new(args.start, args.limit)
    } else {
        match SearchState::load(&args.state_file)? {
            Some(s) => {
                println!("📂 Estado anterior encontrado:");
                println!(
                    "   └─ Último revisado: {}",
                    s.last_checked.to_formatted_string(&Locale::es)
                );
                println!(
                    "   └─ Encontrados: {}",
                    s.found_count.to_formatted_string(&Locale::es)
                );
                println!("   └─ Guardado: {}", s.timestamp);
                s
            }
            None => {
                println!("📂 No se encontró estado previo. Iniciando nueva búsqueda.");
                SearchState::new(args.start, args.limit)
            }
        }
    };

    if state.limit != args.limit {
        println!(
            "⚠️  Límite actualizado: {} → {}",
            state.limit.to_formatted_string(&Locale::es),
            args.limit.to_formatted_string(&Locale::es)
        );
        state.limit = args.limit;
    }

    let start_from = state.last_checked.max(args.start);
    let limit = args.limit;

    if start_from >= limit {
        println!("✅ La búsqueda ya está completa hasta {}", limit);
        return Ok(());
    }

    // Banner
    println!();
    println!("╔══════════════════════════════════════════════════════════════════╗");
    println!("║        🔢  BUSCADOR DE NÚMEROS PRODUCTIVOS v2.0  🔢              ║");
    println!("║            (Miller-Rabin Adaptativo + Criba)                     ║");
    println!("╠══════════════════════════════════════════════════════════════════╣");
    println!(
        "║  Rango: {:>18} → {:<18}         ║",
        start_from.to_formatted_string(&Locale::es),
        limit.to_formatted_string(&Locale::es)
    );
    println!(
        "║  Total a revisar: {:>47} ║",
        (limit - start_from).to_formatted_string(&Locale::es)
    );
    println!("║  Núcleos CPU: {:>51} ║", rayon::current_num_threads());
    println!(
        "║  Chunk size: {:>52} ║",
        args.chunk_size.to_formatted_string(&Locale::es)
    );
    println!("╠══════════════════════════════════════════════════════════════════╣");
    println!("║  📄 Resultados: {:<49} ║", args.output_file);
    println!("║  💾 Estado: {:<53} ║", args.state_file);
    println!("╚══════════════════════════════════════════════════════════════════╝");
    println!();

    // Preparar archivo de salida
    let output_file = Arc::new(Mutex::new(
        OpenOptions::new()
            .create(true)
            .append(true)
            .open(&args.output_file)?,
    ));

    // Contadores
    let found_count = Arc::new(AtomicU64::new(state.found_count));
    let last_found = Arc::new(AtomicU64::new(0));

    // Barra de progreso
    let total = limit - start_from;
    let pb = if args.quiet {
        ProgressBar::hidden()
    } else {
        let pb = ProgressBar::new(total);
        pb.set_style(
            ProgressStyle::default_bar()
                .template(concat!(
                    "{spinner:.green} [{elapsed_precise}] ",
                    "[{bar:45.cyan/blue}] ",
                    "{pos}/{len} ({percent}%)\n",
                    "   ⚡ {per_sec} | ⏱️  ETA: {eta} | 🎯 Encontrados: {msg}"
                ))?
                .progress_chars("━━╾─"),
        );
        pb.set_message("0");
        pb
    };

    let chunk_size = args.chunk_size;
    let start_time = Instant::now();
    let mut last_save_time = Instant::now();
    let mut current_pos = start_from;
    let state_file = args.state_file.clone();

    // Bucle principal
    while current_pos < limit && running.load(Ordering::SeqCst) {
        let chunk_end = (current_pos + chunk_size).min(limit);

        log_verbose!(
            3,
            verbosity,
            "DEBUG: Procesando chunk {} - {}",
            current_pos,
            chunk_end
        );

        let results: Vec<u64> = (current_pos..chunk_end)
            .into_par_iter()
            .filter(|&n| is_productive(n))
            .collect();

        if !results.is_empty() {
            let mut file = output_file
                .lock()
                .unwrap_or_else(|poisoned| poisoned.into_inner());

            for &n in &results {
                writeln!(file, "{}", n)?;
                last_found.store(n, Ordering::Relaxed);

                log_verbose!(1, verbosity, "   🎯 Encontrado: {}", n);
            }
            file.flush()?;
            found_count.fetch_add(results.len() as u64, Ordering::Relaxed);
        }

        let chunk_processed = chunk_end - current_pos;
        pb.inc(chunk_processed);

        let found = found_count.load(Ordering::Relaxed);
        let last = last_found.load(Ordering::Relaxed);
        let msg = if last > 0 {
            format!(
                "{} │ Último: {}",
                found.to_formatted_string(&Locale::es),
                last.to_formatted_string(&Locale::es)
            )
        } else {
            found.to_formatted_string(&Locale::es)
        };
        pb.set_message(msg);

        current_pos = chunk_end;

        if last_save_time.elapsed() >= STATE_SAVE_INTERVAL {
            state.last_checked = current_pos;
            state.found_count = found_count.load(Ordering::Relaxed);
            if let Err(e) = state.save(&state_file) {
                eprintln!("⚠️  Error guardando estado: {}", e);
            }
            last_save_time = Instant::now();

            log_verbose!(2, verbosity, "DEBUG: Estado guardado en {}", current_pos);
        }
    }

    // Finalización
    drop(output_file);

    let final_count = found_count.load(Ordering::Relaxed);
    pb.finish_with_message(format!(
        "✅ {} números productivos encontrados",
        final_count.to_formatted_string(&Locale::es)
    ));

    state.last_checked = current_pos;
    state.found_count = final_count;
    state.save(&state_file)?;

    let elapsed = start_time.elapsed();
    let processed = current_pos - start_from;
    let speed = if elapsed.as_secs_f64() > 0.0 {
        processed as f64 / elapsed.as_secs_f64()
    } else {
        0.0
    };

    // Resumen
    println!();
    println!("╔══════════════════════════════════════════════════════════════════╗");
    println!("║                      📊  RESUMEN FINAL                           ║");
    println!("╠══════════════════════════════════════════════════════════════════╣");
    println!(
        "║  Números revisados: {:>45} ║",
        processed.to_formatted_string(&Locale::es)
    );
    println!(
        "║  Números productivos encontrados: {:>31} ║",
        final_count.to_formatted_string(&Locale::es)
    );
    println!("║  Tiempo total: {:>50} ║", format!("{:.2?}", elapsed));
    println!(
        "║  Velocidad promedio: {:>37} núms/seg ║",
        format!("{:.0}", speed)
    );

    if final_count > 0 && processed > 0 {
        let density = (final_count as f64 / processed as f64) * 100.0;
        println!("║  Densidad: {:>47} % ║", format!("{:.6}", density));
    }

    println!("╚══════════════════════════════════════════════════════════════════╝");

    if !running.load(Ordering::SeqCst) {
        println!();
        println!("💾 Estado guardado en: {}", state_file);
        println!("▶️  Ejecute de nuevo para continuar desde donde quedó.");
    } else {
        println!();
        println!("✅ Búsqueda completada exitosamente.");
    }

    Ok(())
}

// ============================================================================
//                             TESTS
// ============================================================================

#[cfg(test)]
mod tests {
    use super::*;

    // Tests de la criba
    #[test]
    fn test_sieve_initialization() {
        let sieve = get_sieve();
        assert!(!sieve[0]);
        assert!(!sieve[1]);
        assert!(sieve[2]);
        assert!(sieve[3]);
        assert!(!sieve[4]);
        assert!(sieve[5]);
    }

    #[test]
    fn test_sieve_known_primes() {
        let sieve = get_sieve();
        let primes = [
            2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59, 61, 67, 71, 73, 79, 83,
            89, 97, 101, 103, 107, 109, 113,
        ];
        for &p in &primes {
            assert!(sieve[p], "{} debería ser primo en la criba", p);
        }
    }

    #[test]
    fn test_sieve_composites() {
        let sieve = get_sieve();
        let composites = [
            4, 6, 8, 9, 10, 12, 14, 15, 16, 18, 20, 21, 22, 24, 25, 26, 27, 28, 30, 32, 33, 34, 35,
            36, 38, 39, 40,
        ];
        for &c in &composites {
            assert!(!sieve[c], "{} no debería ser primo en la criba", c);
        }
    }

    // Tests de Miller-Rabin adaptativo
    #[test]
    fn test_is_prime_small() {
        assert!(!is_prime(0));
        assert!(!is_prime(1));
        assert!(is_prime(2));
        assert!(is_prime(3));
        assert!(!is_prime(4));
        assert!(is_prime(5));
    }

    #[test]
    fn test_is_prime_boundary_2047() {
        // Límite: 2,047 (requiere testigo [2])
        assert!(is_prime(2039)); // Primo justo debajo
        assert!(!is_prime(2047)); // 2047 = 23 × 89
    }

    #[test]
    fn test_is_prime_boundary_1373653() {
        // Límite: 1,373,653 (requiere testigos [2, 3])
        assert!(is_prime(1373639)); // Primo cercano
        assert!(!is_prime(1373653)); // Compuesto
    }

    #[test]
    fn test_is_prime_large() {
        assert!(is_prime(104729)); // Primo #10000
        assert!(is_prime(1299709)); // Primo #100000
        assert!(is_prime(15485863)); // Primo #1000000
    }

    #[test]
    fn test_carmichael_numbers() {
        // Números de Carmichael - engañan Fermat, no Miller-Rabin
        assert!(!is_prime(561)); // 3 × 11 × 17
        assert!(!is_prime(1105)); // 5 × 13 × 17
        assert!(!is_prime(1729)); // 7 × 13 × 19 (Hardy-Ramanujan)
        assert!(!is_prime(2465)); // 5 × 17 × 29
        assert!(!is_prime(2821)); // 7 × 13 × 31
    }

    // Tests de números productivos
    #[test]
    fn test_single_digit_productive() {
        let productive: Vec<u64> = (0..10).filter(|&n| is_productive(n)).collect();
        assert_eq!(productive, vec![1, 2, 4, 6]);
    }

    #[test]
    fn test_2026_is_productive() {
        assert!(is_productive(2026));
    }

    #[test]
    fn test_2026_splits_detailed() {
        // Verificar cada división de 2026
        assert!(is_prime(2027)); // 2026 + 1
        assert!(is_prime(202 * 6 + 1)); // 1213
        assert!(is_prime(20 * 26 + 1)); // 521
        assert!(is_prime(2 * 26 + 1)); // 53
    }

    #[test]
    fn test_not_productive() {
        assert!(!is_productive(0)); // 0+1=1 no es primo
        assert!(!is_productive(3)); // 3+1=4 no es primo
        assert!(!is_productive(100)); // 1|00 → (1×0)+1=1 no es primo
        assert!(!is_productive(2025)); // Impar > 1
        assert!(!is_productive(2027)); // Impar > 1
    }

    // Benchmark
    #[test]
    #[ignore]
    fn benchmark_optimized() {
        use std::time::Instant;

        // Calentar criba
        let _ = get_sieve();

        let start = Instant::now();
        let count: usize = (1u64..1_000_000).filter(|&n| is_productive(n)).count();
        let elapsed = start.elapsed();

        println!(
            "Encontrados {} números productivos hasta 1M en {:?}",
            count, elapsed
        );
        println!(
            "Velocidad: {:.0} números/segundo",
            1_000_000.0 / elapsed.as_secs_f64()
        );
    }

    #[test]
    #[ignore]
    fn benchmark_is_prime_ranges() {
        use std::time::Instant;

        let ranges = [
            (1u64, 100_000, "< 100K (criba)"),
            (100_000, 200_000, "100K-200K (Miller-Rabin 2 testigos)"),
            (1_000_000, 1_100_000, "1M-1.1M (Miller-Rabin 2 testigos)"),
            (
                10_000_000,
                10_100_000,
                "10M-10.1M (Miller-Rabin 3 testigos)",
            ),
        ];

        for (start, end, label) in ranges {
            let start_time = Instant::now();
            let count: usize = (start..end).filter(|&n| is_prime(n)).count();
            let elapsed = start_time.elapsed();
            println!(
                "{}: {} primos en {:?} ({:.0}/s)",
                label,
                count,
                elapsed,
                (end - start) as f64 / elapsed.as_secs_f64()
            );
        }
    }
}
