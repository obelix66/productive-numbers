#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Analizador de Splits para Números Productivos
Genera CSV con análisis detallado: Número;SplitPos;A;B;Product+1;Primo?;Digitos
"""

import math
import sys
from typing import List, Tuple

# =============================================================================
# MATEMÁTICAS: Miller-Rabin Determinista para u64
# =============================================================================

WITNESSES: List[int] = [2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37]

def mod_pow(base: int, exp: int, mod: int) -> int:
    """Exponenciación modular binaria (base^exp mod mod)"""
    if mod == 1:
        return 0
    result = 1
    base = base % mod
    while exp > 0:
        if exp % 2 == 1:
            result = (result * base) % mod
        exp >>= 1
        base = (base * base) % mod
    return result

def is_prime(n: int) -> bool:
    """
    Test Miller-Rabin determinista para todos los n < 2^64
    Usa los 12 testigos de WITNESSES
    """
    if n < 2:
        return False
    if n in (2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37):
        return True
    if n % 2 == 0:
        return False
    
    # Escribir n-1 como 2^r * d
    d = n - 1
    r = 0
    while d % 2 == 0:
        d //= 2
        r += 1
    
    # Test con cada testigo
    for a in WITNESSES:
        if a >= n:
            continue
        
        x = mod_pow(a, d, n)
        if x == 1 or x == n - 1:
            continue
        
        composite = True
        for _ in range(r - 1):
            x = (x * x) % n
            if x == n - 1:
                composite = False
                break
        
        if composite:
            return False
    
    return True

def count_digits(n: int) -> int:
    """Contar dígitos de un número (más rápido que log10)"""
    if n == 0:
        return 1
    digits = 0
    while n > 0:
        n //= 10
        digits += 1
    return digits

# =============================================================================
# PROCESAMIENTO: Análisis de splits
# =============================================================================

def analyze_number(n: int) -> List[Tuple[int, int, int, int, int, bool, int]]:
    """
    Analizar un número productivo
    Retorna: [(n, split_pos, a, b, product, is_prime, digits), ...]
    """
    results = []
    s = str(n)
    num_digits = len(s)
    
    # Para cada posición de split (1 a num_digits-1)
    for k in range(1, num_digits):
        divisor = 10 ** k
        a = n // divisor
        b = n % divisor
        product = a * b + 1
        
        # Verificar primalidad
        is_product_prime = is_prime(product)
        
        # Contar dígitos del producto
        product_digits = count_digits(product)
        
        results.append((n, k, a, b, product, is_product_prime, product_digits))
    
    return results

def main():
    print("╔══════════════════════════════════════════════════════════════════╗")
    print("║     🔍 ANALISIS DE SPLITS - NÚMEROS PRODUCTIVOS (Python)        ║")
    print("╚══════════════════════════════════════════════════════════════════╝")
    print()
    
    # Verificar archivo de entrada
    input_file = "found.txt"
    if not os.path.exists(input_file):
        print(f"❌ ERROR: {input_file} no encontrado")
        sys.exit(1)
    
    # Leer números
    with open(input_file, 'r') as f:
        numbers = [int(line.strip()) for line in f if line.strip()]
    
    total_numbers = len(numbers)
    print(f"📥 Cargados {total_numbers} números de {input_file}")
    print(f"🚀 Procesando splits (0%)\r", end="", flush=True)
    
    # Procesar cada número
    all_results = []
    processed = 0
    
    for n in numbers:
        results = analyze_number(n)
        all_results.extend(results)
        processed += 1
        
        # Mostrar progreso cada 10 números
        if processed % 10 == 0 or processed == total_numbers:
            percent = (processed * 100) // total_numbers
            print(f"🚀 Procesando splits ({percent}%) - {processed}/{total_numbers} números\r", end="", flush=True)
    
    print(f"🚀 Procesando splits (100%) - {total_numbers}/{total_numbers} números ✅")
    
    # Guardar CSV
    output_file = "splits_analysis.csv"
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write("Número;SplitPos;A;B;A×B+1;Primo?;Digitos\n")
        
        for result in all_results:
            n, k, a, b, product, is_prime_bool, digits = result
            prime_str = "Sí" if is_prime_bool else "No"
            f.write(f"{n};{k};{a};{b};{product};{prime_str};{digits}\n")
    
    total_splits = len(all_results)
    print(f"\n✅ CSV generado: {output_file}")
    print(f"   Total de splits: {total_splits}")
    
    # Verificación rápida
    print(f"\n📋 Verificación (primeras líneas):")
    with open(output_file, 'r') as f:
        for _ in range(3):
            print(f"   {f.readline().strip()}")
    print("   ...")
    
    # Contar cuántos splits fallan
    failed_splits = sum(1 for r in all_results if not r[5])
    print(f"⚠️  Splits no primos: {failed_splits} de {total_splits}")

if __name__ == "__main__":
    import os
    main()
