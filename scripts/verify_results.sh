#!/bin/bash

# =============================================================================
# SCRIPT DE VERIFICACIÓN MANUAL - Números Productivos
# Verifica manualmente casos específicos para asegurar corrección
# =============================================================================

set -e

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║        🔍 VERIFICACIÓN MANUAL DE RESULTADOS                   ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""

# =============================================================================
# Test 1: Verificar números de 1 dígito
# =============================================================================
echo -e "${BLUE}TEST 1: Números de 1 dígito${NC}"
echo "Esperado: {1, 2, 4, 6}"

single_digit=$(awk 'length($1)==1' found.txt | sort -n | tr '\n' ',' | sed 's/,$//')
expected="1,2,4,6"

if [[ "$single_digit" == "$expected" ]]; then
    echo -e "${GREEN}✓ PASS${NC}: $single_digit"
else
    echo -e "${RED}✗ FAIL${NC}: Esperado $expected, obtenido $single_digit"
fi
echo ""

# =============================================================================
# Test 2: Verificar 2026 (caso emblemático)
# =============================================================================
echo -e "${BLUE}TEST 2: Verificar 2026 es productivo${NC}"

if grep -q "^2026$" found.txt; then
    echo -e "${GREEN}✓ PASS${NC}: 2026 encontrado en found.txt"
    
    # Verificar splits de 2026
    echo "   Verificando splits:"
    
    # 2026 + 1 = 2027
    if factor 2027 2>/dev/null | grep -qE ": 2027$"; then
        echo -e "   ${GREEN}✓${NC} 2026+1 = 2027 (primo)"
    else
        echo -e "   ${RED}✗${NC} 2026+1 = 2027 NO ES PRIMO"
    fi
    
    # 2|026 = 2×26+1 = 53
    if factor 53 2>/dev/null | grep -qE ": 53$"; then
        echo -e "   ${GREEN}✓${NC} 2|026: (2×26)+1 = 53 (primo)"
    else
        echo -e "   ${RED}✗${NC} 2|026: 53 NO ES PRIMO"
    fi
    
    # 20|26 = 20×26+1 = 521
    if factor 521 2>/dev/null | grep -qE ": 521$"; then
        echo -e "   ${GREEN}✓${NC} 20|26: (20×26)+1 = 521 (primo)"
    else
        echo -e "   ${RED}✗${NC} 20|26: 521 NO ES PRIMO"
    fi
    
    # 202|6 = 202×6+1 = 1213
    if factor 1213 2>/dev/null | grep -qE ": 1213$"; then
        echo -e "   ${GREEN}✓${NC} 202|6: (202×6)+1 = 1213 (primo)"
    else
        echo -e "   ${RED}✗${NC} 202|6: 1213 NO ES PRIMO"
    fi
else
    echo -e "${RED}✗ FAIL${NC}: 2026 NO encontrado en found.txt"
fi
echo ""

# =============================================================================
# Test 3: Verificar que ningún impar > 1 está en la lista
# =============================================================================
echo -e "${BLUE}TEST 3: Verificar optimización (no impares > 1)${NC}"

odd_count=$(awk '$1>1 && $1%2==1' found.txt | wc -l)

if [[ $odd_count -eq 0 ]]; then
    echo -e "${GREEN}✓ PASS${NC}: No hay impares > 1"
else
    echo -e "${RED}✗ FAIL${NC}: Encontrados $odd_count impares > 1"
    echo "   Ejemplos:"
    awk '$1>1 && $1%2==1' found.txt | head -5
fi
echo ""

# =============================================================================
# Test 4: Verificar primos fuertes conocidos
# =============================================================================
echo -e "${BLUE}TEST 4: Verificar primos fuertes conocidos${NC}"

# Casos conocidos de primos fuertes pequeños
known_strong=(4 6 22 58 82 106 166 178 502 562 586 718 982 1018 2026 2998)

strong_found=0
strong_total=0

for n in "${known_strong[@]}"; do
    ((strong_total++))
    
    if ! grep -q "^$n$" found.txt; then
        echo -e "   ${YELLOW}⊘${NC} $n no está en found.txt (puede ser > límite)"
        continue
    fi
    
    np1=$((n + 1))
    q=$(( (np1 - 1) / 2 ))
    
    if factor "$q" 2>/dev/null | grep -qE "^$q: $q$"; then
        echo -e "   ${GREEN}✓${NC} $n es primo fuerte: ($np1-1)/2 = $q (primo)"
        ((strong_found++))
    else
        echo -e "   ${RED}✗${NC} $n NO es primo fuerte: $q no es primo"
    fi
done

echo ""
echo "   Resumen: $strong_found/$strong_total verificados como primos fuertes"
echo ""

# =============================================================================
# Test 5: Verificar ratio de primalidad en splits
# =============================================================================
echo -e "${BLUE}TEST 5: Verificar ratio de primalidad (debe ser ~99.89%)${NC}"

if [[ -f "splits_analysis.csv" ]]; then
    total_splits=$(wc -l < splits_analysis.csv)
    total_splits=$((total_splits - 1))  # Restar header
    
    prime_splits=$(awk -F';' '$6=="Sí"' splits_analysis.csv | wc -l)
    
    ratio=$(awk "BEGIN {printf \"%.2f\", ($prime_splits/$total_splits)*100}")
    
    if (( $(echo "$ratio >= 99.5" | bc -l) )); then
        echo -e "${GREEN}✓ PASS${NC}: Ratio = $ratio% (esperado ~99.89%)"
    else
        echo -e "${YELLOW}⚠ WARNING${NC}: Ratio = $ratio% (menor a lo esperado)"
    fi
    
    echo "   Total splits: $total_splits"
    echo "   Splits primos: $prime_splits"
else
    echo -e "${YELLOW}⊘ SKIP${NC}: splits_analysis.csv no encontrado"
fi
echo ""

# =============================================================================
# Test 6: Verificar números equilibrados conocidos
# =============================================================================
echo -e "${BLUE}TEST 6: Verificar números equilibrados (Coef.Var = 0%)${NC}"

if [[ -f "analysis_results_"*"/balance_table.txt" ]]; then
    balanced_file=$(ls -t analysis_results_*/balance_table.txt 2>/dev/null | head -1)
    
    if [[ -f "$balanced_file" ]]; then
        balanced_count=$(awk '$4 == "0.00%"' "$balanced_file" | wc -l)
        total_numbers=$(wc -l < found.txt)
        
        percent=$(awk "BEGIN {printf \"%.1f\", ($balanced_count/$total_numbers)*100}")
        
        echo -e "   Números equilibrados: $balanced_count de $total_numbers (${percent}%)"
        
        if [[ $balanced_count -gt 0 ]]; then
            echo -e "${GREEN}✓ PASS${NC}: Se encontraron números equilibrados"
            echo ""
            echo "   Ejemplos (primeros 5):"
            awk '$4 == "0.00%" {print "      • "$1}' "$balanced_file" | head -5
        else
            echo -e "${YELLOW}⚠ WARNING${NC}: No se encontraron números equilibrados"
        fi
    fi
else
    echo -e "${YELLOW}⊘ SKIP${NC}: balance_table.txt no encontrado"
fi
echo ""

# =============================================================================
# Test 7: Verificar total de números encontrados
# =============================================================================
echo -e "${BLUE}TEST 7: Verificar total de números encontrados${NC}"

total=$(wc -l < found.txt)

echo "   Números encontrados: $total"

# Comparar con valores esperados según límite
if [[ $total -eq 4 ]]; then
    echo -e "${GREEN}✓ PASS${NC}: Búsqueda hasta ~10 (esperado: 4)"
elif [[ $total -ge 200 && $total -le 210 ]]; then
    echo -e "${GREEN}✓ PASS${NC}: Búsqueda hasta ~10^10 (esperado: 203)"
elif [[ $total -gt 210 ]]; then
    echo -e "${YELLOW}⚠ WARNING${NC}: Más números de lo esperado (verificar duplicados)"
else
    echo -e "${BLUE}ℹ INFO${NC}: Búsqueda parcial o en progreso"
fi
echo ""

# =============================================================================
# Resumen Final
# =============================================================================
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║                      RESUMEN DE VERIFICACIÓN                  ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""
echo "Tests ejecutados: 7"
echo ""
echo -e "${GREEN}Para más detalles, ejecuta:${NC}"
echo "   • cat analysis_results_*/SUMMARY.txt"
echo "   • cat analysis_results_*/strong_primes.txt"
echo ""
echo "✨ Verificación completa"
echo ""