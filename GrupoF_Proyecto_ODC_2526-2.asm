# ---------------------------------------------------------
# PROYECTO: Conversor de Sistemas Numéricos
# Empresa: Panita / UNIMET 
# ---------------------------------------------------------

.macro imprimir_texto(%label)
    li $v0, 4
    la $a0, %label
    syscall
.end_macro

.data
    bienvenida: .asciiz "Bienvenido al Conversor de Sistemas Numéricos de Panita\n"
    explicacion: .asciiz "Este programa convierte números a distintos formatos (Binario, Hex, etc.) \n"
    menu:        .asciiz "\n¿Que desea hacer?\n1) Introducir un numero entero\n2) Introducir un numero con parte fraccionaria\n3) Salir del programa\nElija una opcion: "
    msg_entero:  .asciiz "\nIngrese un numero entero (ej: 129, -5, +0): "
    msg_frac:    .asciiz "\nIngrese un numero con parte fraccionaria (ej: 1.4, -2.75): "
    msg_salir:   .asciiz "\nSaliendo del programa. ¡Hasta luego!\n"
    
    # Etiquetas para el Output 
    out_bin:     .asciiz "\n-Binario en complemento a 2: "
    out_dec:     .asciiz "\n-Decimal empaquetado: "
    out_b10:     .asciiz "\n-Base 10: "
    out_oct:     .asciiz "\n-Octal: "
    out_hex:     .asciiz "\n-Hexadecimal: \n"

    # Buffer para guardar lo que el usuario escriba (String) 
    buffer:      .space 64 

.text
main:
    # 1. Mostrar Bienvenida y Explicación
    imprimir_texto(bienvenida)
    imprimir_texto(explicacion)

menu_loop:
    # 2. Mostrar Menú
    imprimir_texto(menu)
    
    # Leer opción 
    li $v0, 5
    syscall
    move $t0, $v0

    # 3. Ramificar según la opción
    beq $t0, 1, leer_entero
    beq $t0, 2, leer_fraccionario
    beq $t0, 3, salir_programa
    j menu_loop 

leer_entero:
    imprimir_texto(msg_entero)
    jal leer_string_usuario
    j procesar_y_mostrar

leer_fraccionario:
    imprimir_texto(msg_frac)
    jal leer_string_usuario
    j procesar_y_mostrar
    
salir_programa:
    imprimir_texto(msg_salir)
    li $v0, 10
    syscall

# --- Subrutina para leer el número como STRING  ---
leer_string_usuario:
    li $v0, 8           # Syscall para leer string
    la $a0, buffer      # Donde se guarda
    li $a1, 64          # Tamaño máximo
    syscall
    jr $ra

# --- Lógica de conversión ---
procesar_y_mostrar:
    
    imprimir_texto(out_bin)
    # Lógica para binario... 
    
    imprimir_texto(out_dec)
    # Lógica para decimal empaquetado... 
    
    imprimir_texto(out_b10)
    # Lógica para Base 10 con signo... 
    
    imprimir_texto(out_oct)
    # Lógica para Octal con signo... 
    
    imprimir_texto(out_hex)
    # Lógica para Hexadecimal con signo... 

    j menu_loop