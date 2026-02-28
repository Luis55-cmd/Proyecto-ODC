# ---------------------------------------------------------
# PROYECTO: Conversor de Sistemas Numéricos
# Empresa: Panita / UNIMET 
# ---------------------------------------------------------

# ---------------------------------------------------------
# 1. SECCIÓN DE MACROS
# ---------------------------------------------------------
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

    j procesar_y_mostrar

error_en_numero:
    imprimir_texto(msg_err_num)
    j leer_entero 

leer_fraccionario:
    imprimir_texto(msg_frac)
    jal leer_string_usuario
    j procesar_y_mostrar
    
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

    imprimir_texto(out_bin)
    # Lógica...
    
    imprimir_texto(out_dec)
    # Lógica...
    
    imprimir_texto(out_b10)
    # Lógica...
    
    imprimir_texto(out_oct)
    # Lógica...
    
    imprimir_texto(out_hex)
    # Lógica...

    # Salto de línea estético antes de volver al menú
    li $v0, 4
    la $a0, salto
    syscall

    j menu_loop
