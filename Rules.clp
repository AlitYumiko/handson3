;; ------------------------------------------------
;; Reglas Recomender System
;; ------------------------------------------------

;; --- REGLAS DE CÁLCULO INICIAL (Prioridad Alta) ---

;; Regla 1: Calcular el total de la orden antes de aplicar descuentos
(defrule calcular-total-orden
   (declare (salience 10)) ; Alta prioridad
   ?o <- (orden-compra (orden-id ?oid) (total 0.0))
   (accumulate (bind ?suma 0)
               (progn (bind ?item-total (* ?p ?q)) (bind ?suma (+ ?suma ?item-total)))
               ?suma
               (linea-item (orden-id ?oid) (precio-unitario ?p) (cantidad ?q))
   )
   =>
   (modify ?o (total ?suma))
   (printout t "CÁLCULO (Orden " ?oid "): Total inicial calculado: $" ?suma crlf)
)

;; --- REGLAS DE OFERTAS Y PROMOCIONES (Ejemplos 1, 2 y 3) ---

;; Regla 2: [Ejemplo Usuario 1] iPhone 16 con Banamex -> 24 MSI
(defrule oferta-iPhone16-banamex
   (orden-compra (orden-id ?oid) (tipo-pago tarjeta) (tdc-id ?tidc))
   (linea-item (orden-id ?oid) (sku ?sku))
   (smartphone (sku ?sku) (marca apple) (modelo "iPhone16"))
   (tarjeta-credito (tdc-id ?tidc) (banco banamex))
   =>
   (printout t "OFERTA APLICADA (Orden " ?oid "): 24 meses sin intereses por iPhone 16 con Banamex." crlf)
)

;; Regla 3: [Ejemplo Usuario 2] Samsung Note 21 con Liverpool VISA -> 12 MSI
(defrule oferta-Note21-liverpool
   (orden-compra (orden-id ?oid) (tipo-pago tarjeta) (tdc-id ?tidc))
   (linea-item (orden-id ?oid) (sku ?sku))
   (smartphone (sku ?sku) (marca samsung) (modelo "Note 21"))
   (tarjeta-credito (tdc-id ?tidc) (banco liverpool) (grupo visa))
   =>
   (printout t "OFERTA APLICADA (Orden " ?oid "): 12 meses sin intereses por Samsung Note 21 con Liverpool VISA." crlf)
)

;; Regla 4: [Ejemplo Usuario 3] MacBook Air + iPhone 16 (contado) -> Vales
(defrule generar-vales-combo-apple-contado
   ?o <- (orden-compra (orden-id ?oid) (tipo-pago contado) (cliente-id ?cid) (total ?t & :(> ?t 0)))
   (linea-item (orden-id ?oid) (sku ?sku-mb))
   (computador (sku ?sku-mb) (marca apple) (modelo "MacBook Air"))
   (linea-item (orden-id ?oid) (sku ?sku-ip))
   (smartphone (sku ?sku-ip) (marca apple) (modelo "iPhone16"))
   =>
   (bind ?monto-vale (* (floor (/ ?t 1000)) 100))
   (if (> ?monto-vale 0) then
      (assert (vale (vale-id (str-cat "V-" ?oid)) (cliente-id ?cid) (monto ?monto-vale)))
      (printout t "PROMOCIÓN APLICADA (Orden " ?oid "): Se generó un vale por $" ?monto-vale " por la compra del combo Apple al contado." crlf)
   )
)

;; --- REGLAS DE RECOMENDACIÓN (Ejemplo 4 y más) ---

;; Regla 5: [Ejemplo Usuario 4] Compra Smartphone -> 15% desc en accesorios
(defrule recomienda-accesorios-smartphone
   (linea-item (orden-id ?oid) (sku ?sku))
   (smartphone (sku ?sku))
   ;; <-- CORREGIDO: Sintaxis (not (and ...)) y comillas en tipo
   (not (and (linea-item (orden-id ?oid) (sku ?sku-acc))
             (accesorio (sku ?sku-acc) (tipo ?tipo &:(or (eq ?tipo "funda") (eq ?tipo "mica"))))
        ))
   =>
   (printout t "RECOMENDACIÓN (Orden " ?oid "): ¡Protege tu nuevo Smartphone! Tienes 15% de descuento en fundas y micas." crlf)
)

;; Regla 6: Recomendación de Hub USB-C para MacBook
(defrule recomienda-hub-macbook
   (linea-item (orden-id ?oid) (sku ?sku))
   (computador (sku ?sku) (marca apple))
   ;; <-- CORREGIDO: Sintaxis (not (and ...))
   (not (and (linea-item (orden-id ?oid) (sku ?sku-acc))
             (accesorio (sku ?sku-acc) (tipo "hub usb-c"))
        ))
   =>
   (printout t "RECOMENDACIÓN (Orden " ?oid "): ¿Compraste una MacBook? Podrías necesitar un adaptador/hub USB-C." crlf)
)

;; Regla 7: Recomendación de Cargador Apple
(defrule recomienda-cargador-apple
   (linea-item (orden-id ?oid) (sku ?sku))
   (smartphone (sku ?sku) (marca apple))
   ;; <-- CORREGIDO: Sintaxis (not (and ...))
   (not (and (linea-item (orden-id ?oid) (sku ?sku-acc))
             (accesorio (sku ?sku-acc) (tipo "cargador"))
        ))
   =>
   (printout t "RECOMENDACIÓN (Orden " ?oid "): Recuerda que el iPhone no incluye cargador. ¡Agrega uno a tu carrito!" crlf)
)

;; --- REGLAS DE CLASIFICACIÓN DE CLIENTE (Mayorista/Menudista) ---

;; Regla 8: Clasificación MAYORISTA (cantidad > 10)
(defrule clasificar-mayorista
   (linea-item (orden-id ?oid) (cantidad ?q & :(> ?q 10))) ;; 
   ?o <- (orden-compra (orden-id ?oid) (cliente-id ?cid))
   ?c <- (cliente (cliente-id ?cid) (nivel ?n &:(neq ?n oro)))
   =>
   (printout t "CLASIFICACIÓN (Cliente " ?cid "): Detectado como MAYORISTA (cantidad: " ?q "). Promovido a cliente ORO." crlf)
   (modify ?c (nivel oro))
)

;; Regla 9: Mensaje de bienvenida a Mayorista (si ya era oro)
(defrule mensaje-mayorista
   (linea-item (orden-id ?oid) (cantidad ?q & :(> ?q 10))) ;; 
   (orden-compra (orden-id ?oid) (cliente-id ?cid))
   (cliente (cliente-id ?cid) (nivel oro))
   =>
   (printout t "CLASIFICACIÓN (Cliente " ?cid "): Detectado como MAYORISTA (cantidad: " ?q "). Beneficios ORO aplicados." crlf)
)

;; Regla 10: Clasificación MENUDISTA (cantidad <= 10)
(defrule clasificar-menudista
   (orden-compra (orden-id ?oid) (cliente-id ?cid))
   (linea-item (orden-id ?oid) (cantidad ?q & :(< ?q 11)))
   ; (Se asume que la mayoría son menudistas, solo imprimimos si no es mayorista)
   (not (linea-item (orden-id ?oid) (cantidad ?q-m & :(> ?q-m 10))))
   =>
   (printout t "CLASIFICACIÓN (Cliente " ?cid "): Detectado como MENUDISTA (cantidad: " ?q ")." crlf)
)

;; --- REGLAS DE DESCUENTOS ---

;; Regla 11: Descuento 5% para Clientes ORO
(defrule descuento-cliente-oro
   (declare (salience -5)) ; Prioridad media-baja
   ?o <- (orden-compra (orden-id ?oid) (cliente-id ?cid) (total ?t & :(> ?t 0)))
   (cliente (cliente-id ?cid) (nivel oro))
   =>
   (bind ?descuento (* ?t 0.05))
   (modify ?o (total (- ?t ?descuento)))
   (printout t "DESCUENTO APLICADO (Orden " ?oid "): 5% ($" ?descuento ") para cliente ORO. Nuevo total: $" (- ?t ?descuento) crlf)
)

;; Regla 12: Descuento 10% en Computadoras Dell (Contado)
(defrule descuento-dell-contado
   (declare (salience -5))
   ?o <- (orden-compra (orden-id ?oid) (tipo-pago contado) (total ?t))
   (linea-item (orden-id ?oid) (sku ?sku) (precio-unitario ?p-u) (cantidad ?q))
   (computador (sku ?sku) (marca dell))
   =>
   (bind ?descuento (* ?p-u ?q 0.10))
   (modify ?o (total (- ?t ?descuento)))
   (printout t "DESCUENTO APLICADO (Orden " ?oid "): 10% ($" ?descuento ") en Dell XPS por pago de contado. Nuevo total: $" (- ?t ?descuento) crlf)
)

;; Regla 13: Aplicar descuento de 15% en Accesorios (si se compró smartphone)
(defrule aplicar-descuento-accesorios
   (declare (salience -5))
   ?o <- (orden-compra (orden-id ?oid) (total ?t))
   (linea-item (orden-id ?oid) (sku ?sku-sp)) ; Hay un smartphone en la orden
   (smartphone (sku ?sku-sp))
   ?li-acc <- (linea-item (orden-id ?oid) (sku ?sku-acc) (precio-unitario ?p-acc) (cantidad ?q-acc))
   (accesorio (sku ?sku-acc) (tipo ?tipo &:(or (eq ?tipo "funda") (eq ?tipo "mica")))) ;; 
   =>
   (bind ?descuento (* ?p-acc ?q-acc 0.15))
   (modify ?o (total (- ?t ?descuento)))
   (printout t "DESCUENTO APLICADO (Orden " ?oid "): 15% ($" ?descuento ") en " ?tipo ". Nuevo total: $" (- ?t ?descuento) crlf)
   ;; <-- CORREGIDO: Se eliminó el (retract ?li-acc) que causaba un error lógico.
)

;; --- OTRAS OFERTAS BANCARIAS Y ENVÍOS ---

;; Regla 14: Oferta Envío Gratis (Clientes ORO)
(defrule oferta-envio-gratis-oro
   (orden-compra (orden-id ?oid) (cliente-id ?cid))
   (cliente (cliente-id ?cid) (nivel oro))
   =>
   (printout t "OFERTA APLICADA (Orden " ?oid "): Envío estándar GRATIS para cliente ORO." crlf)
)

;; Regla 15: Oferta Envío Gratis (Compra > $4000)
(defrule oferta-envio-gratis-monto
   (orden-compra (orden-id ?oid) (total ?t & :(> ?t 4000.0)))
   =>
   (printout t "OFERTA APLICADA (Orden " ?oid "): Envío estándar GRATIS por compra mayor a $4000." crlf)
)

;; Regla 16: Promo Puntos Dobles BBVA
(defrule promo-banco-bbva
   (orden-compra (orden-id ?oid) (tipo-pago tarjeta) (tdc-id ?tidc))
   (tarjeta-credito (tdc-id ?tidc) (banco bbva))
   =>
   (printout t "OFERTA BANCARIA (Orden " ?oid "): ¡Tu compra con BBVA genera Puntos Dobles!" crlf)
)

;; Regla 17: 3x2 en Accesorios Genéricos
(defrule oferta-3x2-accesorios-genericos
   (linea-item (orden-id ?oid) (sku ?sku1) (cantidad ?q1 & :(>= ?q1 2)))
   (accesorio (sku ?sku1) (marca generico))
   =>
   (printout t "OFERTA APLICADA (Orden " ?oid "): En la compra de 2 accesorios genéricos, el 3ro es GRATIS (aplicar en caja)." crlf)
)


;; --- REGLAS DE MANEJO DE STOCK (Prioridad Baja) ---

;; Regla 18: Actualización de Stock (Smartphone)
(defrule actualizar-stock-smartphone
   (declare (salience -10))
   ?o <- (orden-compra (orden-id ?oid) (estado procesando))
   ?li <- (linea-item (orden-id ?oid) (sku ?sku) (cantidad ?q))
   ?p <- (smartphone (sku ?sku) (stock ?s & :(>= ?s ?q)))
   =>
   (printout t "STOCK (Actualizando): " ?q " unidades de " ?sku " (Stock anterior: " ?s "). Nuevo stock: " (- ?s ?q) crlf)
   (modify ?p (stock (- ?s ?q)))
   (retract ?li) ; Item procesado
)

;; Regla 19: Actualización de Stock (Computador)
(defrule actualizar-stock-computador
   (declare (salience -10))
   ?o <- (orden-compra (orden-id ?oid) (estado procesando))
   ?li <- (linea-item (orden-id ?oid) (sku ?sku) (cantidad ?q))
   ?p <- (computador (sku ?sku) (stock ?s & :(>= ?s ?q)))
   =>
   (printout t "STOCK (Actualizando): " ?q " unidades de " ?sku " (Stock anterior: " ?s "). Nuevo stock: " (- ?s ?q) crlf)
   (modify ?p (stock (- ?s ?q)))
   (retract ?li)
)

;; Regla 20: Actualización de Stock (Accesorio)
(defrule actualizar-stock-accesorio
   (declare (salience -10))
   ?o <- (orden-compra (orden-id ?oid) (estado procesando))
   ?li <- (linea-item (orden-id ?oid) (sku ?sku) (cantidad ?q))
   ?p <- (accesorio (sku ?sku) (stock ?s & :(>= ?s ?q)))
   =>
   (printout t "STOCK (Actualizando): " ?q " unidades de " ?sku " (Stock anterior: " ?s "). Nuevo stock: " (- ?s ?q) crlf)
   (modify ?p (stock (- ?s ?q)))
   (retract ?li)
)

;; Regla 21: Manejo de Falta de Stock
(defrule falta-stock
   (declare (salience -15)) ; Prioridad muy baja
   ?o <- (orden-compra (orden-id ?oid) (estado procesando))
   ?li <- (linea-item (orden-id ?oid) (sku ?sku) (cantidad ?q))
   (or (smartphone (sku ?sku) (stock ?s & :(< ?s ?q)))
       (computador (sku ?sku) (stock ?s & :(< ?s ?q)))
       (accesorio (sku ?sku) (stock ?s & :(< ?s ?q)))
   )
   =>
   (printout t "ERROR STOCK (Orden " ?oid "): No hay suficiente stock para " ?q " unidades de " ?sku ". Orden CANCELADA." crlf)
   (modify ?o (estado cancelada))
   (retract ?li)
)

;; Regla 22: Marcar Orden como Completada
(defrule completar-orden
   (declare (salience -20)) ; Prioridad más baja
   ?o <- (orden-compra (orden-id ?oid) (estado procesando))
   (not (linea-item (orden-id ?oid))) ; No quedan items por procesar
   =>
   (modify ?o (estado completada))
   (printout t "ESTADO (Orden " ?oid "): COMPLETADA. Total final: $" (round (* 100 (?o:total)) / 100) crlf)
)