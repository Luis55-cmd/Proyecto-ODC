# ---------------------------------------------------------
# PROYECTO: Conversor de Sistemas Numéricos
# Empresa: Panita / UNIMET 
# ---------------------------------------------------------

# ---------------------------------------------------------
# 1. SECCIÓN DE MACROS
# ---------------------------------------------------------

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
    
    # Si es entero:
    ascii_a_entero(buffer, $s0)
    j continuar_impresion

usar_fraccionario:
    # Si es fraccionario:
    ascii_a_fraccionario(buffer, $s0)
    contar_decimales(buffer, $s2)                
    
continuar_impresion:

    # Ahora $s0 tiene el número (ej: -125). 
    imprimir_texto(out_bin)
    # Lógica...
    
    imprimir_texto(out_dec)
    # Lógica...
    
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

    # 5. Imprimir punto
    li $a0, '.'
    li $v0, 11
    syscall

    # 6. Imprimir parte fraccionaria
    move $a0, $t6
    li $v0, 1
    syscall
    
    imprimir_texto(out_oct)
    # Lógica...
    
    imprimir_texto(out_hex)
    # Lógica...

    # Salto de línea estético antes de volver al menú
    li $v0, 4
    la $a0, salto
    syscall

    j menu_loop
