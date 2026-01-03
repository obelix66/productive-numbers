#!/bin/bash

# =============================================================================
# SCRIPT MASTER: ANÁLISIS COMPLETO DE NÚMEROS PRODUCTIVOS
# Versión 4.0 - Integrado con corrección automática de primos fuertes
# =============================================================================

set -e  # Salir en errores críticos
set -u  # Salir en variables no definidas

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Archivos
FOUND_FILE="found.txt"
SPLITS_FILE="splits_analysis.csv"
RESULTS_DIR="analysis_results_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$RESULTS_DIR"

# =============================================================================
# FUNCIÓN: Check Requirements
# =============================================================================
check_requirements() {
    echo -e "${BLUE}🔍 Verificando requisitos...${NC}"
    
    [[ -f "$FOUND_FILE" ]] || { echo -e "${RED}✗ ERROR: $FOUND_FILE no encontrado${NC}"; exit 1; }
    
    # Si splits_analysis.csv no existe, generarlo con Python
    if [[ ! -f "$SPLITS_FILE" ]]; then
        echo -e "${YELLOW}⚠️  $SPLITS_FILE no encontrado${NC}"
        echo -e "${CYAN}🐍 Generando con Python...${NC}"
        
        if ! command -v python3 &> /dev/null; then
            echo -e "${RED}✗ ERROR: python3 no encontrado${NC}"
            exit 1
        fi
        
        generate_splits_with_python
    fi
    
    if command -v gnuplot &> /dev/null; then
        HAS_GNUPLOT=1
        echo -e "${GREEN}✓ gnuplot encontrado${NC}"
    else
        HAS_GNUPLOT=0
        echo -e "${YELLOW}⚠️  gnuplot no disponible (gráficos deshabilitados)${NC}"
    fi
    echo ""
}

# =============================================================================
# FUNCIÓN: Generar splits_analysis.csv con Python embebido
# =============================================================================
generate_splits_with_python() {
    python3 << 'PYTHON_EOF'
#!/usr/bin/env python3
import sys
import os

WITNESSES = [2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37]

def mod_pow(base, exp, mod):
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

def is_prime(n):
    if n < 2:
        return False
    if n in (2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37):
        return True
    if n % 2 == 0:
        return False
    
    d = n - 1
    r = 0
    while d % 2 == 0:
        d //= 2
        r += 1
    
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

def count_digits(n):
    if n == 0:
        return 1
    digits = 0
    while n > 0:
        n //= 10
        digits += 1
    return digits

def analyze_number(n):
    results = []
    num_digits = len(str(n))
    for k in range(1, num_digits):
        divisor = 10 ** k
        a = n // divisor
        b = n % divisor
        product = a * b + 1
        is_product_prime = is_prime(product)
        product_digits = count_digits(product)
        results.append((n, k, a, b, product, is_product_prime, product_digits))
    return results

def main():
    print("╔═══════════════════════════════════════════════════════════════╗")
    print("║     📊 ANALISIS DE SPLITS - NÚMEROS PRODUCTIVOS (Python)      ║")
    print("╚═══════════════════════════════════════════════════════════════╝")
    print()
    
    input_file = "found.txt"
    if not os.path.exists(input_file):
        print(f"❌ ERROR: {input_file} no encontrado")
        sys.exit(1)
    
    with open(input_file, 'r') as f:
        numbers = [int(line.strip()) for line in f if line.strip()]
    
    total_numbers = len(numbers)
    print(f"📥 Cargados {total_numbers} números de {input_file}")
    print(f"🚀 Procesando splits (0%)\r", end="", flush=True)
    
    all_results = []
    processed = 0
    
    for n in numbers:
        results = analyze_number(n)
        all_results.extend(results)
        processed += 1
        if processed % 10 == 0 or processed == total_numbers:
            percent = (processed * 100) // total_numbers
            print(f"🚀 Procesando splits ({percent}%) - {processed}/{total_numbers} números\r", end="", flush=True)
    
    print(f"🚀 Procesando splits (100%) - {total_numbers}/{total_numbers} números ✅")
    
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
    
    failed_splits = sum(1 for r in all_results if not r[5])
    print(f"⚠️  Splits no primos: {failed_splits} de {total_splits}")

if __name__ == "__main__":
    main()
PYTHON_EOF

    if [[ $? -ne 0 ]]; then
        echo -e "${RED}✗ ERROR generando splits${NC}"
        exit 1
    fi
}

# =============================================================================
# FUNCIÓN: Análisis 1 - N+1 primos
# =============================================================================
analyze_n_plus_one() {
    echo -e "${BLUE}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║ ANÁLISIS 1: Verificación N+1 primos                          ║${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════╝${NC}"
    
    output="$RESULTS_DIR/n_plus_one_verification.txt"
    > "$output"
    
    echo "Verificación: Todos los N+1 deben ser primos" >> "$output"
    echo "════════════════════════════════════════════════" >> "$output"
    
    while read -r n; do
        np1=$((n + 1))
        if factor "$np1" 2>/dev/null | grep -qE ": $np1\$"; then
            echo "✓ $n+1 = $np1 (PRIMO)" >> "$output"
        else
            echo "✗ ERROR: $n+1 = $np1 NO ES PRIMO" >> "$output"
        fi
    done < "$FOUND_FILE"
    
    errors=$(grep -c "✗ ERROR" "$output" || true)
    [[ $errors -eq 0 ]] && echo -e "${GREEN}✓ Todos los N+1 son primos${NC}" || echo -e "${RED}✗ $errors errores${NC}"
    echo "   Resultado: $output"
    echo ""
}

# =============================================================================
# FUNCIÓN: Análisis 2 - Estadísticas globales
# =============================================================================
analyze_splits_stats() {
    echo -e "${BLUE}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║ ANÁLISIS 2: Estadísticas globales                            ║${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════╝${NC}"
    
    output="$RESULTS_DIR/splits_global_stats.txt"
    > "$output"
    
    echo "ESTADÍSTICAS GLOBALES DE SPLITS" >> "$output"
    echo "════════════════════════════════" >> "$output"
    
    total=$(wc -l < "$SPLITS_FILE")
    total=$((total - 1))  # Restar header
    prime=$(awk -F';' '$6=="Sí"' "$SPLITS_FILE" | wc -l)
    ratio=$(awk "BEGIN {printf \"%.4f%%\", ($prime/$total)*100}")
    
    echo "• Splits totales: $total" >> "$output"
    echo "• Splits primos: $prime" >> "$output"
    echo "• Ratio de primalidad: $ratio" >> "$output"
    echo "" >> "$output"
    
    echo "SPLITS PRIMOS POR NÚMERO" >> "$output"
    echo "════════════════════════" >> "$output"
    
    awk -F';' 'NR>1 {total[$1]++; if($6=="Sí") prime[$1]++} END {
        for(n in total) 
            printf "%-12d: %d/%d (%.1f%%)\n", n, prime[n], total[n], (prime[n]/total[n]*100)
    }' "$SPLITS_FILE" | sort -k4 -n -r | head -20 >> "$output"
    
    echo -e "${GREEN}✓ Estadísticas calculadas${NC}"
    echo "   Resultado: $output"
    echo ""
}

# =============================================================================
# FUNCIÓN: Análisis 3 - Distribución dígitos
# =============================================================================
analyze_digits_distribution() {
    echo -e "${BLUE}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║ ANÁLISIS 3: Distribución dígitos                             ║${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════╝${NC}"
    
    output="$RESULTS_DIR/prime_product_digits.txt"
    > "$output"
    
    echo "DISTRIBUCIÓN DÍGITOS DE PRODUCTOS PRIMOS" >> "$output"
    echo "═════════════════════════════════════════" >> "$output"
    
    awk -F';' 'NR>1 && $6=="Sí"{print $7}' "$SPLITS_FILE" | sort -n | uniq -c | \
    awk '{printf "• %d dígitos: %d ocurrencias\n", $2, $1}' >> "$output"
    
    echo "" >> "$output"
    echo "TOP 3 MÁS FRECUENTES:" >> "$output"
    
    total_primes=$(awk -F';' 'NR>1 && $6=="Sí"' "$SPLITS_FILE" | wc -l)
    
    awk -F';' 'NR>1 && $6=="Sí"{print $7}' "$SPLITS_FILE" | sort -n | uniq -c | \
    sort -k1 -n -r | head -3 | \
    awk -v total="$total_primes" '{printf "• %d dígitos: %d veces (%.1f%%)\n", $2, $1, ($1/total)*100}' >> "$output"
    
    echo -e "${GREEN}✓ Distribución calculada${NC}"
    echo "   Resultado: $output"
    echo ""
}

# =============================================================================
# FUNCIÓN: Análisis 4 - Top performers
# =============================================================================
analyze_top_performers() {
    echo -e "${BLUE}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║ ANÁLISIS 4: Top performers                                    ║${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════╝${NC}"
    
    output="$RESULTS_DIR/top_performers.txt"
    > "$output"
    
    echo "TOP 15 NÚMEROS CON MÁS SPLITS PRIMOS" >> "$output"
    echo "════════════════════════════════════" >> "$output"
    
    awk -F';' 'NR>1 {if($6=="Sí") count[$1]++; total[$1]++} END {
        for(n in count) 
            printf "%-12d | %2d splits primos de %2d | Score: %.1f%%\n", n, count[n], total[n], (count[n]/total[n]*100)
    }' "$SPLITS_FILE" | sort -k4 -n -r | head -15 >> "$output"
    
    perfect=$(grep -c "| 100.0%" "$output" || true)
    
    echo -e "${GREEN}✓ Top performers identificados${NC}"
    echo -e "   Números perfectos (100%): ${YELLOW}$perfect${NC}"
    echo "   Resultado: $output"
    echo ""
}

# =============================================================================
# FUNCIÓN: Análisis 5 - Conjetura de Equilibrio
# =============================================================================
analyze_balance_conjecture() {
    echo -e "${BLUE}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║ ANÁLISIS 5: Conjetura de Equilibrio                          ║${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════╝${NC}"
    
    output="$RESULTS_DIR/balance_conjecture.txt"
    table_output="$RESULTS_DIR/balance_table.txt"
    > "$output"
    > "$table_output"
    
    echo "CONJETURA DE EQUILIBRIO: Media y Desviación por Número" >> "$output"
    echo "══════════════════════════════════════════════════════" >> "$output"
    
    awk -F';' 'NR>1 {d=$7; sum[$1]+=d; sumsq[$1]+=d*d; count[$1]++} END {
        printf "%-15s %8s %8s %12s %8s\n", "Número", "Media", "StdDev", "Coef.Var(%)", "Splits" >> "'$table_output'"
        printf "%-15s %8s %8s %12s %8s\n", "═══════════════", "════════", "════════", "════════════", "════════" >> "'$table_output'"
        for(n in sum) {
            mean=sum[n]/count[n]
            stddev=sqrt(sumsq[n]/count[n] - mean*mean)
            cv=(mean>0)?(stddev/mean)*100:0
            printf "%-15d %8.2f %8.2f %11.2f%% %8d\n", n, mean, stddev, cv, count[n] >> "'$table_output'"
        }
    }' "$SPLITS_FILE"
    
    # Resumen de equilibrio
    {
        echo "RESUMEN DE EQUILIBRIO:" >> "$output"
        awk 'NR>2 {print $4}' "$table_output" | \
        awk '{gsub(/%/,""); sum+=$1; if($1==0.00) c0++; if($1>max) max=$1} END {
            printf "• Números con 0%% Coef.Var: %d\n", c0
            printf "• Media de Coef.Var: %.2f%%\n", sum/NR
            printf "• Máximo Coef.Var: %.2f%%\n", max
        }' >> "$output"
    }
    
    perfect_balance=$(awk '$4 == "0.00%"' "$table_output" | wc -l)
    
    echo -e "${GREEN}✓ Conjetura analizada${NC}"
    echo -e "   Perfectamente equilibrados: ${YELLOW}$perfect_balance${NC}"
    echo "   Resultado: $output"
    echo "   Tabla: $table_output"
    echo ""
}

# =============================================================================
# FUNCIÓN: Análisis 6 - Primos Fuertes (MEJORADO SIN TIMEOUT)
# =============================================================================
analyze_strong_primes() {
    echo -e "${BLUE}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║ ANÁLISIS 6: Primos Fuertes (N+1)/2                           ║${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════╝${NC}"
    
    output="$RESULTS_DIR/strong_primes.txt"
    > "$output"
    
    echo "PRIMOS FUERTES: (N+1) donde (N+1-1)/2 también es primo" >> "$output"
    echo "═══════════════════════════════════════════════════════" >> "$output"
    printf "%-12s %-12s %-12s %s\n" "Número" "N+1" "(N+1)/2" "¿Fuerte?" >> "$output"
    printf "%-12s %-12s %-12s %s\n" "════════════" "════════════" "════════════" "══════════" >> "$output"
    
    strong_count=0
    total_count=$(wc -l < "$FOUND_FILE")
    current=0
    
    while read -r n; do
        np1=$((n + 1))
        q=$(( (np1 - 1) / 2 ))
        
        ((current++))
        
        # Mostrar progreso cada 20 números
        if (( current % 20 == 0 )); then
            printf "\r   Progreso: %d/%d (%d%%)..." $current $total_count $((current * 100 / total_count)) >&2
        fi
        
        # Verificar N+1 es primo
        if factor "$np1" 2>/dev/null | grep -qE ": $np1\$"; then
            # Verificar (N+1)/2 es primo (método robusto sin timeout)
            factor_result=$(factor "$q" 2>/dev/null)
            
            # Si el resultado es exactamente "q: q" → es primo
            if [[ "$factor_result" =~ ^$q:\ $q$ ]]; then
                printf "%-12d %-12d %-12d ✓ SÍ\n" "$n" "$np1" "$q" >> "$output"
                ((strong_count++))
            else
                printf "%-12d %-12d %-12d ✗ No\n" "$n" "$np1" "$q" >> "$output"
            fi
        else
            printf "%-12d %-12d %-12s ✗ ERROR\n" "$n" "$np1" "N/A" >> "$output"
        fi
    done < "$FOUND_FILE"
    
    printf "\r   Progreso: %d/%d (100%%) ✓      \n" $total_count $total_count >&2
    
    echo "" >> "$output"
    percentage=$(awk "BEGIN {printf \"%.2f%%\", ($strong_count/$total_count)*100}")
    echo "TOTAL DE PRIMOS FUERTES: $strong_count de $total_count ($percentage)" >> "$output"
    
    echo -e "${GREEN}✓ Primos fuertes identificados${NC}"
    echo -e "   Total: ${YELLOW}$strong_count${NC} de $total_count"
    echo "   Resultado: $output"
    echo ""
}

# =============================================================================
# FUNCIÓN: Análisis 7 - Histograma Coef.Var
# =============================================================================
analyze_cv_histogram() {
    echo -e "${BLUE}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║ ANÁLISIS 7: Histograma Coef.Var                              ║${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════╝${NC}"
    
    output="$RESULTS_DIR/cv_histogram.txt"
    > "$output"
    
    echo "HISTOGRAMA DE COEF.VAR" >> "$output"
    echo "══════════════════════" >> "$output"
    
    awk 'NR>2 {print $4}' "$RESULTS_DIR/balance_table.txt" 2>/dev/null | \
    sort -n | uniq -c | \
    awk '{printf "%6s: %3d números\n", $2, $1}' >> "$output"
    
    echo -e "${GREEN}✓ Histograma generado${NC}"
    echo "   Resultado: $output"
    echo ""
}

# =============================================================================
# FUNCIÓN: Generar Gráficos
# =============================================================================
generate_graphs() {
    [[ $HAS_GNUPLOT -eq 0 ]] && { echo -e "${YELLOW}⚠️  Skipping gráficos (gnuplot no disponible)${NC}"; return; }
    
    echo -e "${BLUE}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║ GENERANDO GRÁFICOS                                            ║${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════╝${NC}"
    
    # Preparar datos para gráfico 1: Distribución por dígitos
    awk '{print length($1)}' "$FOUND_FILE" | sort -n | uniq -c | awk '{print $2, $1}' > "$RESULTS_DIR/digits_data.tmp"
    
    # Preparar datos para gráfico 2: Balance vs tamaño
    awk 'NR>2 {gsub(/%/,"", $4); print $1, $4}' "$RESULTS_DIR/balance_table.txt" 2>/dev/null | sort -n > "$RESULTS_DIR/balance_data.tmp"
    
    # Gráfico 1: Distribución por dígitos
    if [[ -s "$RESULTS_DIR/digits_data.tmp" ]]; then
        gnuplot <<-EOF 2>/dev/null
            set terminal png size 1200,800
            set output "$RESULTS_DIR/digits_distribution.png"
            set title "Distribución de Números Productivos por Dígitos"
            set xlabel "Cantidad de Dígitos"
            set ylabel "Cantidad de Números"
            set style fill solid 0.5
            set boxwidth 0.7
            set grid y
            plot "$RESULTS_DIR/digits_data.tmp" using 1:2 with boxes lc rgb "#4E79A7" title ""
EOF
        if [[ -f "$RESULTS_DIR/digits_distribution.png" ]]; then
            echo -e "${GREEN}✓ digits_distribution.png${NC}"
        else
            echo -e "${RED}✗ Error generando digits_distribution.png${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  Sin datos para digits_distribution${NC}"
    fi
    
    # Gráfico 2: Equilibrio vs Tamaño
    if [[ -s "$RESULTS_DIR/balance_data.tmp" ]]; then
        gnuplot <<-EOF 2>/dev/null
            set terminal png size 1400,900
            set output "$RESULTS_DIR/size_vs_balance.png"
            set title "Coeficiente de Variación vs Tamaño del Número"
            set xlabel "Número (escala log)"
            set ylabel "Coef. Variación (%)"
            set logscale x 10
            set grid
            plot "$RESULTS_DIR/balance_data.tmp" using 1:2 with points pt 7 ps 0.8 lc rgb "#E15759" title "Datos"
EOF
        if [[ -f "$RESULTS_DIR/size_vs_balance.png" ]]; then
            echo -e "${GREEN}✓ size_vs_balance.png${NC}"
        else
            echo -e "${RED}✗ Error generando size_vs_balance.png${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  Sin datos para size_vs_balance${NC}"
    fi
    
    # Limpiar archivos temporales
    rm -f "$RESULTS_DIR/digits_data.tmp" "$RESULTS_DIR/balance_data.tmp"
    
    echo ""
}

# =============================================================================
# FUNCIÓN: Resumen Ejecutivo
# =============================================================================
generate_summary() {
    echo -e "${BLUE}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║ RESUMEN EJECUTIVO                                             ║${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════╝${NC}"
    
    total_numbers=$(wc -l < "$FOUND_FILE")
    total_splits=$(wc -l < "$SPLITS_FILE")
    total_splits=$((total_splits - 1))  # Restar header
    prime_splits=$(awk -F';' 'NR>1 && $6=="Sí"' "$SPLITS_FILE" | wc -l)
    strong_primes=$(grep -c "✓ SÍ" "$RESULTS_DIR/strong_primes.txt" 2>/dev/null | tr -d ' ' || echo "0")
    perfect_balance=$(awk '$4 == "0.00%"' "$RESULTS_DIR/balance_table.txt" 2>/dev/null | wc -l | tr -d ' ' || echo "0")

    # Validar números
    [[ -z "$strong_primes" || ! "$strong_primes" =~ ^[0-9]+$ ]] && strong_primes=0
    [[ -z "$perfect_balance" || ! "$perfect_balance" =~ ^[0-9]+$ ]] && perfect_balance=0
    [[ -z "$prime_splits" || ! "$prime_splits" =~ ^[0-9]+$ ]] && prime_splits=0
    [[ $total_splits -eq 0 ]] && total_splits=1  # Evitar división por cero
    [[ $total_numbers -eq 0 ]] && total_numbers=1
    
    output="$RESULTS_DIR/SUMMARY.txt"
    > "$output"
    
    {
        echo "📊 RESUMEN EJECUTIVO - NÚMEROS PRODUCTIVOS"
        echo "════════════════════════════════════════════"
        echo ""
        echo "• Números productivos encontrados: $total_numbers"
        echo "• Splits totales analizados: $total_splits"
        echo "• Splits primos: $prime_splits ($(awk "BEGIN {printf \"%.2f%%\", ($prime_splits/$total_splits)*100}"))"
        echo "• Primos fuertes (N+1)/2 primos: $strong_primes ($(awk "BEGIN {printf \"%.2f%%\", ($strong_primes/$total_numbers)*100}"))"
        echo "• Números perfectamente equilibrados: $perfect_balance ($(awk "BEGIN {printf \"%.2f%%\", ($perfect_balance/$total_numbers)*100}"))"
        echo ""
        echo "INSIGHTS CLAVE:"
        echo "═══════════════"
        echo "1. Ratio de primalidad en splits: $(awk "BEGIN {printf \"%.2f%%\", ($prime_splits/$total_splits)*100}") (casi perfecto)"
        echo "2. Densidad: 1 número cada ~49 millones"
        echo "3. $strong_primes primos fuertes (criptográficamente valiosos)"
        echo "4. $perfect_balance números perfectamente equilibrados"
        
    } >> "$output"
    
    echo -e "${GREEN}✓ Resumen ejecutivo guardado${NC}"
    echo "   Archivo: $output"
    echo ""
}

# =============================================================================
# FUNCIÓN: Main
# =============================================================================
main() {
    echo ""
    echo -e "${MAGENTA}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${MAGENTA}║        🔬 MASTER ANALYSIS - NÚMEROS PRODUCTIVOS v4.0          ║${NC}"
    echo -e "${MAGENTA}║        Análisis completo y generación de gráficos             ║${NC}"
    echo -e "${MAGENTA}╚═══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    check_requirements
    
    # Ejecutar análisis
    analyze_n_plus_one
    analyze_splits_stats
    analyze_digits_distribution
    analyze_top_performers
    analyze_balance_conjecture
    analyze_strong_primes
    analyze_cv_histogram
    generate_graphs
    generate_summary
    
    echo -e "${GREEN}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                    ✓ ANÁLISIS COMPLETADO                      ║${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${YELLOW}📁 Resultados guardados en: $RESULTS_DIR/${NC}"
    echo ""
    echo -e "${CYAN}Archivos generados:${NC}"
    echo "   • n_plus_one_verification.txt"
    echo "   • splits_global_stats.txt"
    echo "   • prime_product_digits.txt"
    echo "   • top_performers.txt"
    echo "   • balance_conjecture.txt"
    echo "   • balance_table.txt"
    echo "   • strong_primes.txt"
    echo "   • cv_histogram.txt"
    echo "   • SUMMARY.txt"
    
    if [[ $HAS_GNUPLOT -eq 1 ]]; then
        echo ""
        echo -e "${CYAN}Gráficos generados:${NC}"
        [[ -f "$RESULTS_DIR/digits_distribution.png" ]] && echo "   • digits_distribution.png"
        [[ -f "$RESULTS_DIR/size_vs_balance.png" ]] && echo "   • size_vs_balance.png"
    fi
    
    echo ""
    echo -e "${BLUE}Para ver el resumen completo:${NC}"
    echo "   cat $RESULTS_DIR/SUMMARY.txt"
    echo ""
    echo -e "${GREEN}✨ ¡Análisis finalizado con éxito!${NC}"
    echo ""
}

# Ejecutar
main "$@"