# ---------------------------------------------------------
# PROYECTO: Conversor de Sistemas Numéricos
# Empresa: Panita / UNIMET 
# ---------------------------------------------------------

# ---------------------------------------------------------
# 1. SECCIÓN DE MACROS
# ---------------------------------------------------------
.macro imprimir_hex_fraccionario(%reg_valor_total, %reg_num_decimales)
    abs $t0, %reg_valor_total
    div $t0, $t8
    mflo $t1 # Parte entera
    mfhi $t2 # Parte fraccionaria

    bgez %reg_valor_total, hex_f_pos
    li $a0, '-'
    li $v0, 11
    syscall
hex_f_pos:
    # Parte entera en hex
    move $a0, $t1
    jal sub_print_hex_simple 

    li $a0, '.'
    li $v0, 11
    syscall

    # Parte fraccionaria (Multiplicaciones por 16)
    li $t3, 4 # 4 dígitos hex de precisión
loop_hex_f:
    mul $t2, $t2, 16
    div $t2, $t8
    mflo $t4 # Dígito
    mfhi $t2 # Residuo
    
    blt $t4, 10, hex_f_dig
    addi $t4, $t4, 55 # A-F
    j hex_f_out
hex_f_dig:
    addi $t4, $t4, 48 # 0-9
hex_f_out:
    move $a0, $t4
    li $v0, 11
    syscall
    subi $t3, $t3, 1
    bnez $t3, loop_hex_f
.end_macro

.macro imprimir_octal_fraccionario(%reg_valor_total, %reg_num_decimales)
    # 1. Separar parte entera y fraccionaria
    # Usamos la potencia de 10 calculada antes ($t8 ya tiene 10^decimales)
    abs $t0, %reg_valor_total
    div $t0, $t8
    mflo $t1 # Parte entera absoluta
    mfhi $t2 # Parte fraccionaria absoluta

    # 2. Imprimir signo si el original era negativo
    bgez %reg_valor_total, oct_f_pos
    li $a0, '-'
    li $v0, 11
    syscall
oct_f_pos:
    # 3. Imprimir parte entera en Octal (reutilizando lógica de divisiones)
    move $a0, $t1
    jal sub_print_octal_simple # Subrutina para no repetir código

    # 4. Punto decimal
    li $a0, '.'
    li $v0, 11
    syscall

    # 5. Parte fraccionaria (Multiplicaciones sucesivas por 8)
    li $t3, 4 # Imprimiremos 4 dígitos octales de precisión
loop_oct_f:
    mul $t2, $t2, 8
    div $t2, $t8
    mflo $a0      # Dígito obtenido
    mfhi $t2      # Nuevo residuo
    addi $a0, $a0, 48
    li $v0, 11
    syscall
    subi $t3, $t3, 1
    bnez $t3, loop_oct_f
.end_macro

.macro imprimir_hexadecimal_entero(%reg_valor)

    move $t0, %reg_valor

    bgez $t0, es_pos_hex

    li $a0, '-'

    li $v0, 11

    syscall

    neg $t0, $t0

es_pos_hex:

    la $t1, buffer_bcd

    li $t2, 0

conv_hex_loop:

    div $t0, $t0, 16

    mfhi $t3

    sb $t3, 0($t1)

    addi $t1, $t1, 1

    addi $t2, $t2, 1

    bnez $t0, conv_hex_loop

print_hex_loop:

    subi $t1, $t1, 1

    lb $t3, 0($t1)

    blt $t3, 10, hex_digito

    addi $t3, $t3, 55    # Convertir 10-15 a 'A'-'F'

    j hex_out

hex_digito:

    addi $t3, $t3, 48    # Convertir 0-9 a '0'-'9'

hex_out:

    move $a0, $t3

    li $v0, 11

    syscall

    subi $t2, $t2, 1

    bnez $t2, print_hex_loop

.end_macro

.macro imprimir_octal_entero(%reg_valor)
    # 1. Manejo del signo
    move $t0, %reg_valor
    bgez $t0, es_pos_oct
    
    # Si es negativo, imprimimos el signo '-'
    li $a0, '-'
    li $v0, 11
    syscall
    
    # Convertimos a valor absoluto para la conversión
    neg $t0, $t0                

es_pos_oct:
    # 2. Conversión a Octal (reversa)                
    la $t1, buffer_bcd          # Usamos el buffer temporal para guardar los dígitos
    li $t2, 0                   # Contador de dígitos

convertir_octal_loop:
    div $t0, $t0, 8             # Dividir por 8
    mfhi $t3                    # Obtener resto (dígito octal)
    
    sb $t3, 0($t1)              # Guardar dígito
    addi $t1, $t1, 1
    addi $t2, $t2, 1
    
    bnez $t0, convertir_octal_loop

    # 3. Impresión de dígitos (en orden correcto)
imprimir_octal_loop:
    subi $t1, $t1, 1
    lb $a0, 0($t1)
    
    # Convertir dígito (0-7) a ASCII ('0'-'7')
    addi $a0, $a0, 48
    li $v0, 11
    syscall
    
    subi $t2, $t2, 1
    bnez $t2, imprimir_octal_loop
.end_macro

.macro decimal_empaquetado_fraccional_hex(%reg_valor, %reg_signo, %reg_num_decimales)
    # %reg_valor: Valor absoluto completo (ej: 275)
    # %reg_signo: Bandera de signo (0 = pos, 1 = neg)
    # %reg_num_decimales: Cantidad de decimales ($s2)
    
    # 1. Convertir el valor absoluto total a BCD y guardarlo en el buffer
    move $t0, %reg_valor
    li $t1, 0           # Contador de dígitos
    la $t4, buffer_bcd  # Dirección del buffer temporal
    
conv_bcd_loop_f:
    div $t0, $t0, 10    # Dividir valor por 10
    mfhi $t3            # $t3 = resto (dígito actual)
    
    # Guardar dígito BCD (0-9) en buffer
    sb $t3, 0($t4)
    addi $t4, $t4, 1
    addi $t1, $t1, 1
    
    bnez $t0, conv_bcd_loop_f
    
    # 2. Imprimir BCD en binario (4 bits por dígito) desde el buffer (reversa)
    # $t1 = total de dígitos en el buffer
    
imprimir_bcd_loop:
    subi $t4, $t4, 1
    lb $t2, 0($t4)      # Cargar dígito BCD (0-9)
    
    # --- Imprimir 4 bits del dígito ---                
    li $t5, 4           # Contador de bits (4 bits)
    li $t6, 8           # Máscara inicial 1000 (2^3)
    
bits_loop:
    and $t7, $t2, $t6   # Comparar dígito con máscara
    beqz $t7, print_cero_bit
    li $a0, '1'
    j do_print_bit
print_cero_bit:
    li $a0, '0'
do_print_bit:
    li $v0, 11
    syscall
    
    srl $t6, $t6, 1     # Desplazar máscara a la derecha
    subi $t5, $t5, 1
    bnez $t5, bits_loop                
    
    subi $t1, $t1, 1
    bnez $t1, imprimir_bcd_loop
    # 3. Imprimir Signo en Binario (C = 1100, D = 1101)
    beq %reg_signo, 1, signo_negativo_f
    # Signo positivo: C = 1100
    li $a0, '1'
    syscall
    li $a0, '1'
    syscall
    li $a0, '0'
    syscall
    li $a0, '0'
    syscall
    j print_signo_f
    
signo_negativo_f:
    # Signo negativo: D = 1101
    li $a0, '1'
    syscall
    li $a0, '1'
    syscall
    li $a0, '0'
    syscall
    li $a0, '1'
    syscall
    
print_signo_f:
.end_macro


.macro decimal_empaquetado_entero_hex(%reg_valor)
    # 1. Obtener valor absoluto y guardar signo
    abs $t0, %reg_valor    # $t0 = |valor|
    
    # 2. Convertir el valor absoluto a BCD (Binary Coded Decimal)
    li $t1, 0           # Contador de dígitos
    la $t2, buffer_bcd  # Dirección del buffer temporal
    
conv_bcd_loop_h:
    div $t0, $t0, 10    # Dividir valor absoluto por 10
    mfhi $t3            # $t3 = resto (dígito actual)
    
    # Guardar dígito BCD (0-9) en buffer
    sb $t3, 0($t2)
    addi $t2, $t2, 1
    addi $t1, $t1, 1
    
    bnez $t0, conv_bcd_loop_h
    
    # 3. Imprimir BCD en binario (4 bits por dígito) desde el buffer (reversa)
    # $t1 ahora tiene la cantidad de dígitos
    
imprimir_bcd_hex:
    subi $t2, $t2, 1
    lb $t3, 0($t2)      # Cargar dígito BCD (0-9)
    
    # --- Imprimir 4 bits del dígito ---
    li $t5, 4           # Contador de bits (4 bits)
    li $t6, 8           # Máscara inicial 1000 (2^3)
    
bits_loop_h:
    and $t7, $t3, $t6   # Comparar dígito con máscara
    beqz $t7, print_cero_bit_h
    li $a0, '1'
    j do_print_bit_h
print_cero_bit_h:
    li $a0, '0'
do_print_bit_h:
    li $v0, 11
    syscall
    
    srl $t6, $t6, 1     # Desplazar máscara a la derecha
    subi $t5, $t5, 1
    bnez $t5, bits_loop_h
    
    subi $t1, $t1, 1
    bnez $t1, imprimir_bcd_hex
    
    # 4. Imprimir Signo en Binario (C=1100 para +, D=1101 para -)
    bltz %reg_valor, signo_negativo_h
    
    # Signo positivo: C = 1100
    li $a0, '1'
    syscall
    li $a0, '1'
    syscall
    li $a0, '0'
    syscall
    li $a0, '0'
    syscall
    j fin_macro_h
    
signo_negativo_h:
    # Signo negativo: D = 1101
    li $a0, '1'
    syscall
    li $a0, '1'
    syscall
    li $a0, '0'
    syscall
    li $a0, '1'
    syscall
    
fin_macro_h:
.end_macro

.macro imprimir_binario_entero_8bits(%reg_valor)
    # Imprime los 8 bits inferiores de un registro en complemento a 2
    li $t0, 8                # Contador de bits
    li $t1, 128              # Máscara inicial 10000000 (2^7)
    
loop_entera_f:
    and $t2, %reg_valor, $t1 # Comparar valor con máscara
    beqz $t2, print_cero_f
    li $a0, '1'
    j do_print_f
print_cero_f:
    li $a0, '0'
do_print_f:
    li $v0, 11
    syscall
    srl $t1, $t1, 1         # Desplazar máscara a la derecha
    subi $t0, $t0, 1
    bnez $t0, loop_entera_f
.end_macro

.macro imprimir_binario_punto_fijo(%reg_valor_crudo, %reg_num_decimales)
    # --- 1. Separación de partes ---
    # Calcular 10^%reg_num_decimales (divisor)
    li $t8, 1                # Usaremos $t8 como divisor
    li $t3, 0                # Contador para potencia
    li $t9, 10               # Base 10
pow_loop_bin:
    beq $t3, %reg_num_decimales, pow_fin_bin
    mul $t8, $t8, $t9
    addi $t3, $t3, 1
    j pow_loop_bin
pow_fin_bin:
    
    # Separar: $t5 = Parte Entera (con signo), $t6 = Parte Fraccionaria (con signo)
    div %reg_valor_crudo, $t8
    mflo $t5                # $t5 es Parte Entera (con signo)
    mfhi $t6                # $t6 es Parte Fraccionaria (con signo)
    
    # --- 2. Imprimir Parte Entera en binario manual (8 bits, Complemento a 2) ---
    li $t0, 8                # Contador de bits (8 bits entera)
    li $t1, 128              # Máscara inicial 10000000 (2^7)
    
loop_entera:
    and $t2, $t5, $t1       # Comparar parte entera con máscara
    beqz $t2, print_cero_e
    li $a0, '1'
    j do_print_e
print_cero_e:
    li $a0, '0'
do_print_e:
    li $v0, 11
    syscall
    srl $t1, $t1, 1         # Desplazar máscara a la derecha
    subi $t0, $t0, 1
    bnez $t0, loop_entera

    # --- 3. Imprimir Punto ---
    li $a0, '.'
    li $v0, 11
    syscall

    # --- 4. Imprimir Parte Fraccionaria (8 bits manual) ---
    abs $t0, $t6            # Trabajamos con la magnitud positiva
    li $t1, 8                # Contador de 8 bits
loop_fraccionaria:
    # Algoritmo: Fracción * 2
    mul $t0, $t0, 2
    
    # ¿Es mayor o igual que el divisor ($t8)?
    div $t0, $t8
    mflo $t2                # Bit es el cociente
    mfhi $t0                # Nuevo residuo es el resto
    
    # Imprimir bit
    move $a0, $t2
    addi $a0, $a0, 48       # Convertir 0/1 a '0'/'1'
    li $v0, 11
    syscall
    
    subi $t1, $t1, 1
    bnez $t1, loop_fraccionaria
.end_macro


.macro contar_decimales(%buffer, %reg_contador)
    la $t0, %buffer
    li %reg_contador, 0
    li $t2, 0 # Bandera de punto encontrado
loop_count:
    lb $t1, 0($t0)
    beq $t1, 10, fin_count
    beq $t1, 0, fin_count
    
    beq $t1, '.', punto_encontrado
    
    # Si ya pasamos el punto, contar
    beq $t2, 1, incrementar_contador
    j next_count

punto_encontrado:
    li $t2, 1
    j next_count

incrementar_contador:
    addi %reg_contador, %reg_contador, 1
    
next_count:
    addi $t0, $t0, 1
    j loop_count
fin_count:
.end_macro

.macro ascii_a_fraccionario(%buffer, %reg_resultado)
    la $t0, %buffer
    li %reg_resultado, 0
    li $t2, 0                   # Bandera de signo (0 = pos, 1 = neg)
    
    lb $t1, 0($t0)              # Leer primer carácter
    
    # Manejo de Signos
    beq $t1, '-', es_neg_f
    beq $t1, '+', es_pos_f
    j conv_loop_f

es_neg_f:
    li $t2, 1
    addi $t0, $t0, 1
    j conv_loop_f

es_pos_f:
    addi $t0, $t0, 1

conv_loop_f:
    lb $t1, 0($t0)
    
    # Verificar fin de cadena
    beq $t1, 10, aplicar_signo_f
    beq $t1, 0, aplicar_signo_f
    
    # SI ES PUNTO, IGNORARLO
    beq $t1, '.', punto_decimal
    
    # Convertir ASCII a número: valor = (valor * 10) + (caracter - '0')
    sub $t1, $t1, 48
    mul %reg_resultado, %reg_resultado, 10
    add %reg_resultado, %reg_resultado, $t1
    
punto_decimal:
    addi $t0, $t0, 1
    j conv_loop_f

aplicar_signo_f:
    beq $t2, 0, fin_macro_f
    neg %reg_resultado, %reg_resultado
fin_macro_f:
.end_macro

.macro ascii_a_entero(%buffer, %reg_resultado)
    la $t0, %buffer             # Puntero al inicio del buffer
    li %reg_resultado, 0        # Inicializar el acumulador en 0
    li $t2, 0                   # Bandera de signo (0 = pos, 1 = neg)

    lb $t1, 0($t0)              # Leer primer carácter
    
    # Manejo de Signos
    beq $t1, '-', es_neg        # Si es '-', marcar como negativo
    beq $t1, '+', es_pos        # Si es '+', saltar al siguiente
    j conversion_loop           # Si es número, empezar conversión directamente

es_neg:
    li $t2, 1                   # Marcar bandera como negativo
    addi $t0, $t0, 1            # Avanzar puntero
    j conversion_loop

es_pos:
    addi $t0, $t0, 1            # Solo avanzar puntero

conversion_loop:
    lb $t1, 0($t0)              # Leer carácter actual
    
    # Verificar fin de cadena (enter o nulo)
    beq $t1, 10, aplicar_signo  
    beq $t1, 0, aplicar_signo   

    # Convertir ASCII a número: valor = (valor * 10) + (caracter - '0')
    sub $t1, $t1, 48            # Restar 48 (ASCII de '0') para obtener el dígito
    mul %reg_resultado, %reg_resultado, 10
    add %reg_resultado, %reg_resultado, $t1
    
    addi $t0, $t0, 1            # Siguiente carácter
    j conversion_loop

aplicar_signo:
    beq $t2, 0, fin_macro       # Si no era negativo, terminar
    neg %reg_resultado, %reg_resultado # Si era negativo, multiplicar por -1

fin_macro:
.end_macro

.macro validar_fraccionario(%buffer, %registro_error)
    li %registro_error, 0       # 0 = OK, 1 = Error
    li $t2, 0                   # Contador de puntos decimales
    la $t0, %buffer
    lb $t1, 0($t0)              # Leer primer carácter

    # Caso especial: ¿Es un signo?
    beq $t1, '+', f_sig
    beq $t1, '-', f_sig
    j f_check_digit

f_sig:
    addi $t0, $t0, 1
    lb $t1, 0($t0)              # Leer el siguiente tras el signo

f_check_digit:
    # Si después del signo viene un enter o nulo, es error
    beq $t1, 10, f_error
    beq $t1, 0, f_error

f_loop:
    lb $t1, 0($t0)
    beq $t1, 10, f_fin          # Fin cadena
    beq $t1, 0, f_fin           
    
    # ¿Es un punto?
    beq $t1, '.', f_punto
    
    # ¿Es un dígito?
    blt $t1, '0', f_error
    bgt $t1, '9', f_error
    j f_next

f_punto:
    addi $t2, $t2, 1            # Incrementamos contador de puntos
    li $t3, 1
    bgt $t2, $t3, f_error       # Si hay más de 1 punto, error
    j f_next

f_next:
    addi $t0, $t0, 1
    j f_loop

f_error:
    li %registro_error, 1
f_fin:
.end_macro

.macro imprimir_texto(%label)
    li $v0, 4
    la $a0, %label
    syscall
.end_macro
.macro validar_entero(%buffer, %registro_error)
    li %registro_error, 0       # 0 = Todo bien, 1 = Error
    la $t0, %buffer             # Cargar dirección del buffer
    lb $t1, 0($t0)              # Leer el primer carácter

    # Caso especial: ¿Es un signo?
    beq $t1, '+', siguiente_char
    beq $t1, '-', siguiente_char
    
    # Si no es signo, debe ser un dígito
    blt $t1, '0', error_input
    bgt $t1, '9', error_input

siguiente_char:
    addi $t0, $t0, 1            # Mover al siguiente carácter
loop_v:
    lb $t1, 0($t0)
    
    # Si llegamos al final (salto de línea o nulo), terminar validación
    beq $t1, 10, fin_v          # 10 es '\n'
    beq $t1, 0, fin_v           # 0 es '\0'
    
    # Verificar si es dígito
    blt $t1, '0', error_input
    bgt $t1, '9', error_input
    
    addi $t0, $t0, 1
    j loop_v

error_input:
    li %registro_error, 1

fin_v:
.end_macro

# ---------------------------------------------------------
# 2. SECCIÓN DE DATOS (.data)
# ---------------------------------------------------------
.data
    bienvenida: .asciiz "Bienvenido al Conversor de Sistemas Numéricos de Panita\n"
    explicacion: .asciiz "Este programa convierte números a distintos formatos (Binario, Hex, etc.) \n"
    menu:        .asciiz "\n¿Que desea hacer?\n1) Introducir un numero entero\n2) Introducir un numero con parte fraccionaria\n3) Salir del programa\nElija una opcion: "
    msg_entero:  .asciiz "\nIngrese un numero entero (ej: 129, -5, +0): "
    msg_frac:    .asciiz "\nIngrese un numero con parte fraccionaria (ej: 1.4, -2.75): "
    msg_salir:   .asciiz "\nSaliendo del programa. ¡Hasta luego!\n"
    msg_error:   .asciiz "\nOpción inválida. Por favor, ingrese solo 1, 2 o 3.\n"
    msg_err_num: .asciiz "\nError: Formato de numero incorrecto. Intente de nuevo.\n"
    
    buffer_menu: .space 4        # Espacio para leer la opción como string
    buffer:      .space 64       # Buffer para el número ingresado [cite: 30]
    buffer_bcd: .space 32 # Espacio temporal para la conversión BCD

    # Etiquetas para el Output 
    out_bin:     .asciiz "\n-Binario en complemento a 2: "
    out_dec:     .asciiz "\n-Decimal empaquetado: "
    out_b10:     .asciiz "\n-Base 10: "
    out_oct:     .asciiz "\n-Octal: "
    out_hex:     .asciiz "\n-Hexadecimal: "
    salto:       .asciiz "\n"
# ---------------------------------------------------------
# 3. SECCIÓN DE CÓDIGO (.text)
# ---------------------------------------------------------
.text
main:
    imprimir_texto(bienvenida)
    imprimir_texto(explicacion)

menu_loop:
    imprimir_texto(menu)
    
    # 1. Leer opción como STRING (para evitar crasheos por letras)
    li $v0, 8
    la $a0, buffer_menu
    li $a1, 4
    syscall

    # 2. Cargar el primer carácter y validar
    lb $t0, buffer_menu
    
    li $t1, '1'
    beq $t0, $t1, leer_entero
    li $t1, '2'
    beq $t0, $t1, leer_fraccionario
    li $t1, '3'
    beq $t0, $t1, salir_programa

    # Si no es 1, 2 o 3, mostrar error
    imprimir_texto(msg_error)
    j menu_loop

leer_entero:
    imprimir_texto(msg_entero)
    jal leer_string_usuario
    
    # Validamos lo que el usuario escribió en 'buffer'
    validar_entero(buffer, $s1) 
    
    # Si $s1 es 1, hubo un error de caracteres
    beq $s1, 1, error_en_numero
    li $t9, 1 # <--- INDICAR QUE ES ENTERO
    j procesar_y_mostrar

error_en_numero:
    imprimir_texto(msg_err_num)
    j leer_entero 

leer_fraccionario:
    imprimir_texto(msg_frac)
    jal leer_string_usuario
    
    # Validamos lo que el usuario escribió en 'buffer'
    validar_fraccionario(buffer, $s1)
    
    # Si $s1 es 1, error. Volvemos a pedir el número fraccionario
    beq $s1, 1, error_en_frac
    li $t9, 2                    # <--- INDICAR QUE ES FRACCIÓN
    j procesar_y_mostrar

error_en_frac:
    imprimir_texto(msg_err_num)
    j leer_fraccionario  # Se queda aquí hasta que lo ponga bien
    
salir_programa:
    imprimir_texto(msg_salir)
    li $v0, 10
    syscall

# --- Subrutina para leer el número como STRING ---
leer_string_usuario:
    li $v0, 8
    la $a0, buffer
    li $a1, 64
    syscall
    jr $ra

# --- Lógica de conversión ---
procesar_y_mostrar:
    # Decidir qué macro usar basada en $t9
    beq $t9, 2, usar_fraccionario
    
    # --- SI ES ENTERO (Opción 1): ---
    ascii_a_entero(buffer, $s0)
    
    imprimir_texto(out_bin)
    imprimir_binario_entero_8bits($s0)
    
    li $s2, 0
    
    j continuar_impresion

usar_fraccionario:
    # --- SI ES FRACCIONARIO (Opción 2): ---
    ascii_a_fraccionario(buffer, $s0)
    contar_decimales(buffer, $s2) # Esto llena $s2 con la cant. de decimales
    
    imprimir_texto(out_bin)
    imprimir_binario_punto_fijo($s0, $s2)
    j continuar_impresion              
    
continuar_impresion:
    
    # --- DECIMAL EMPAQUETADO ---
    imprimir_texto(out_dec)
    
    # Decidir qué macro usar basada en $t9 (1=entero, 2=fraccion)
    beq $t9, 2, empaquetar_fraccion
    
    # Si es entero:
    decimal_empaquetado_entero_hex($s0)
    j continuar_base10

empaquetar_fraccion:
    # Si es fracción:
    # 1. Obtener valor absoluto absoluto total ($s0 viene de ascii_a_fraccionario)
    abs $t6, $s0
    
    # 2. Determinar signo de $s0 para la macro (0=pos, 1=neg)
    li $t7, 0 # Asumimos positivo
    bgtz $s0, es_pos_f_fin
    li $t7, 1 # Es negativo
es_pos_f_fin:
    
    decimal_empaquetado_fraccional_hex($t6, $t7, $s2)                
    j continuar_base10

continuar_base10:                
    # --- BASE 10 ---
    imprimir_texto(out_b10)
    
    # 0. Imprimir signo
    bltz $s0, print_neg
    li $a0, '+'
    j do_sign
print_neg:
    li $a0, '-'
do_sign:
    li $v0, 11
    syscall
    
    # 1. Calcular valor absoluto
    abs $t7, $s0  # El número sin punto
    
    # 2. Calcular la potencia de 10 basada en $s2 (número de decimales)
    li $t8, 1
    li $t3, 0
pow_loop:
    beq $t3, $s2, pow_fin
    mul $t8, $t8, 10
    addi $t3, $t3, 1
    j pow_loop
pow_fin:
    # $t8 ahora tiene 10, 100, 1000, etc.

    # 3. Separar parte entera y fraccionaria
    div $t7, $t8
    mflo $t5 # Parte entera
    mfhi $t6 # Parte fraccionaria

    # 4. Imprimir parte entera
    move $a0, $t5
    li $v0, 1
    syscall

    beqz $s2, saltar_fraccion_b10
    
    # 5. Imprimir punto
    li $a0, '.'
    li $v0, 11
    syscall

    # 6. Imprimir parte fraccionaria
    move $a0, $t6
    li $v0, 1
    syscall

saltar_fraccion_b10:
    # --- OCTAL ---
    imprimir_texto(out_oct)
    beq $t9, 1, oct_ent
    imprimir_octal_fraccionario($s0, $s2)
    j hex_label
oct_ent:
    imprimir_octal_entero($s0)

hex_label:
    # --- HEXADECIMAL ---
    imprimir_texto(out_hex)
    beq $t9, 1, hex_ent
    imprimir_hex_fraccionario($s0, $s2)
    j fin_loop
hex_ent:
    imprimir_hexadecimal_entero($s0)

fin_loop:
    imprimir_texto(salto)
    j menu_loop
    
# ---------------------------------------------------------
# 4. SUBRUTINAS AUXILIARES (¡Aquí van!)
# ---------------------------------------------------------

sub_print_octal_simple:
    # Recibe en $a0 el valor entero absoluto a convertir
    move $t0, $a0
    bnez $t0, oct_proc_sub
    li $a0, '0'
    li $v0, 11
    syscall
    jr $ra

oct_proc_sub:
    la $t4, buffer_bcd
    li $t5, 0
oct_loop_sub:
    div $t0, $t0, 8
    mfhi $t6
    sb $t6, 0($t4)
    addi $t4, $t4, 1
    addi $t5, $t5, 1
    bnez $t0, oct_loop_sub
oct_print_sub:
    subi $t4, $t4, 1
    lb $a0, 0($t4)
    addi $a0, $a0, 48
    li $v0, 11
    syscall
    subi $t5, $t5, 1
    bnez $t5, oct_print_sub
    jr $ra

sub_print_hex_simple:
    # Recibe en $a0 el valor entero absoluto a convertir
    move $t0, $a0
    bnez $t0, hex_proc_sub
    li $a0, '0'
    li $v0, 11
    syscall
    jr $ra

hex_proc_sub:
    la $t4, buffer_bcd
    li $t5, 0
hex_loop_sub:
    div $t0, $t0, 16
    mfhi $t6
    sb $t6, 0($t4)
    addi $t4, $t4, 1
    addi $t5, $t5, 1
    bnez $t0, hex_loop_sub
hex_print_sub:
    subi $t4, $t4, 1
    lb $t6, 0($t4)
    blt $t6, 10, hex_digit_sub
    addi $t6, $t6, 55    # A-F
    j hex_out_sub
hex_digit_sub:
    addi $t6, $t6, 48    # 0-9
hex_out_sub:
    move $a0, $t6
    li $v0, 11
    syscall
    subi $t5, $t5, 1
    bnez $t5, hex_print_sub
    jr $ra    
    