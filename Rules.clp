;; ------------------------------------------------
;; Reglas Recomender System
;; ------------------------------------------------

;; --- REGLAS DE OFERTAS Y PROMOCIONES ---

;; Regla 1: Oferta iPhone 16 con Banamex
(defrule oferta-iPhone16-banamex
   (orden-compra (orden-id ?oid) (tipo-pago tarjeta) (tdc-id ?tidc))
   (linea-item (orden-id ?oid) (sku ?sku))
   (smartphone (sku ?sku) (marca apple) (modelo "iPhone16"))
   (tarjeta-credito (tdc-id ?tidc) (banco banamex))
   =>
   (printout t "OFERTA APLICADA (Orden " ?oid "): 24 meses sin intereses por iPhone 16 con Banamex." crlf)
)

;; Regla 2: Oferta Note 21 con Liverpool
(defrule oferta-Note21-liverpool
   (orden-compra (orden-id ?oid) (tipo-pago tarjeta) (tdc-id ?tidc))
   (linea-item (orden-id ?oid) (sku ?sku))
   (smartphone (sku ?sku) (marca samsung) (modelo "Note 21"))
   (tarjeta-credito (tdc-id ?tidc) (banco liverpool) (grupo visa))
   =>
   (printout t "OFERTA APLICADA (Orden " ?oid "): 12 meses sin intereses por Samsung Note 21 con Liverpool VISA." crlf)
)

;; Regla 3: Generar Vales por Combo Apple Contado
(defrule generar-vales-combo-apple-contado
   ?o <- (orden-compra (orden-id ?oid) (tipo-pago contado) (cliente-id ?cid) (total ?t & :(> ?t 0)))
   (linea-item (orden-id ?oid) (sku ?sku-mb))
   (computador (sku ?sku-mb) (marca apple) (modelo "MacBook Air"))
   (linea-item (orden-id ?oid) (sku ?sku-ip))
   (smartphone (sku ?sku-ip) (marca apple) (modelo "iPhone16"))
   =>
   (bind ?monto-vale (* (integer (/ ?t 1000)) 100))
   (if (> ?monto-vale 0) then
      (assert (vale (vale-id (str-cat "V-" ?oid)) (cliente-id ?cid) (monto ?monto-vale)))
      (printout t "PROMOCIÓN APLICADA (Orden " ?oid "): Se generó un vale por $" ?monto-vale " por la compra del combo Apple al contado." crlf)
   )
)

;; --- REGLAS DE RECOMENDACIÓN ---

;; Regla 4: Recomendar Accesorios para Smartphone
(defrule recomienda-accesorios-smartphone
   (linea-item (orden-id ?oid) (sku ?sku))
   (smartphone (sku ?sku))
   (not (and (linea-item (orden-id ?oid) (sku ?sku-acc))
             (accesorio (sku ?sku-acc) (tipo ?tipo &:(or (eq ?tipo "funda") (eq ?tipo "mica"))))
        ))
   =>
   (printout t "RECOMENDACIÓN (Orden " ?oid "): ¡Protege tu nuevo Smartphone! Tienes 15% de descuento en fundas y micas." crlf)
)

;; Regla 5: Recomendar Hub para MacBook
(defrule recomienda-hub-macbook
   (linea-item (orden-id ?oid) (sku ?sku))
   (computador (sku ?sku) (marca apple))
   (not (and (linea-item (orden-id ?oid) (sku ?sku-acc))
             (accesorio (sku ?sku-acc) (tipo "hub usb-c"))
        ))
   =>
   (printout t "RECOMENDACIÓN (Orden " ?oid "): ¿Compraste una MacBook? Podrías necesitar un adaptador/hub USB-C." crlf)
)

;; Regla 6: Recomendar Cargador Apple
(defrule recomienda-cargador-apple
   (linea-item (orden-id ?oid) (sku ?sku))
   (smartphone (sku ?sku) (marca apple))
   (not (and (linea-item (orden-id ?oid) (sku ?sku-acc))
             (accesorio (sku ?sku-acc) (tipo "cargador"))
        ))
   =>
   (printout t "RECOMENDACIÓN (Orden " ?oid "): Recuerda que el iPhone no incluye cargador. ¡Agrega uno a tu carrito!" crlf)
)

;; --- REGLAS DE CLASIFICACIÓN DE CLIENTE (Mayorista/Menudista) ---

;; Regla 7: Clasificar Cliente como Mayorista
(defrule clasificar-mayorista
   (linea-item (orden-id ?oid) (cantidad ?q & :(> ?q 10))) 
   ?o <- (orden-compra (orden-id ?oid) (cliente-id ?cid))
   ?c <- (cliente (cliente-id ?cid) (nivel ?n &:(neq ?n oro)))
   =>
   (printout t "CLASIFICACIÓN (Cliente " ?cid "): Detectado como MAYORISTA (cantidad: " ?q "). Promovido a cliente ORO." crlf)
   (modify ?c (nivel oro))
)

;; Regla 8: Mensaje de Bienvenida a Mayorista
(defrule mensaje-mayorista
   (linea-item (orden-id ?oid) (cantidad ?q & :(> ?q 10))) 
   (orden-compra (orden-id ?oid) (cliente-id ?cid))
   (cliente (cliente-id ?cid) (nivel oro))
   =>
   (printout t "CLASIFICACIÓN (Cliente " ?cid "): Detectado como MAYORISTA (cantidad: " ?q "). Beneficios ORO aplicados." crlf)
)

;; Regla 9: Clasificar Cliente como Menudista
(defrule clasificar-menudista
   (orden-compra (orden-id ?oid) (cliente-id ?cid))
   (linea-item (orden-id ?oid) (cantidad ?q & :(< ?q 11)))
   (not (linea-item (orden-id ?oid) (cantidad ?q-m & :(> ?q-m 10))))
   =>
   (printout t "CLASIFICACIÓN (Cliente " ?cid "): Detectado como MENUDISTA (cantidad: " ?q ")." crlf)
)

;; --- REGLAS DE DESCUENTOS ---

;; Regla 10: Descuento para Cliente ORO
(defrule descuento-cliente-oro
   (declare (salience -5)) ; Prioridad media-baja
   ;; Se añade la condición (descuento-oro-aplicado no)
   ?o <- (orden-compra (orden-id ?oid) (cliente-id ?cid) (total ?t & :(> ?t 0)) (descuento-oro-aplicado no))
   (cliente (cliente-id ?cid) (nivel oro))
   =>
   (bind ?descuento (* ?t 0.05))
   ;; Se modifica el total Y la bandera (descuento-oro-aplicado yes)
   (modify ?o (total (- ?t ?descuento)) (descuento-oro-aplicado yes))
   (printout t "DESCUENTO APLICADO (Orden " ?oid "): 5% ($" ?descuento ") para cliente ORO. Nuevo total: $" (- ?t ?descuento) crlf)
)

;; Regla 11: Descuento en Dell por Pago de Contado
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

;; Regla 12: Aplicar Descuento en Accesorios
(defrule aplicar-descuento-accesorios
   (declare (salience -5))
   ?o <- (orden-compra (orden-id ?oid) (total ?t))
   (linea-item (orden-id ?oid) (sku ?sku-sp)) ; Hay un smartphone en la orden
   (smartphone (sku ?sku-sp))
   ?li-acc <- (linea-item (orden-id ?oid) (sku ?sku-acc) (precio-unitario ?p-acc) (cantidad ?q-acc))
   (accesorio (sku ?sku-acc) (tipo ?tipo &:(or (eq ?tipo "funda") (eq ?tipo "mica")))) 
   =>
   (bind ?descuento (* ?p-acc ?q-acc 0.15))
   (modify ?o (total (- ?t ?descuento)))
   (printout t "DESCUENTO APLICADO (Orden " ?oid "): 15% ($" ?descuento ") en " ?tipo ". Nuevo total: $" (- ?t ?descuento) crlf)
)

;; --- OTRAS OFERTAS BANCARIAS Y ENVÍOS ---

;; Regla 13: Oferta Envío Gratis para Cliente ORO
(defrule oferta-envio-gratis-oro
   ;; Se añade la condición (promo-envio-aplicada no)
   ?o <- (orden-compra (orden-id ?oid) (cliente-id ?cid) (promo-envio-aplicada no))
   (cliente (cliente-id ?cid) (nivel oro))
   =>
   (printout t "OFERTA APLICADA (Orden " ?oid "): Envío estándar GRATIS para cliente ORO." crlf)
   ;; Se actualiza la bandera para que no se repita
   (modify ?o (promo-envio-aplicada yes))
)

;; Regla 14: Oferta Envío Gratis por Monto de Compra
(defrule oferta-envio-gratis-monto
   ;; Se añade la condición (promo-envio-aplicada no)
   ?o <- (orden-compra (orden-id ?oid) (total ?t & :(> ?t 4000.0)) (promo-envio-aplicada no))
   =>
   (printout t "OFERTA APLICADA (Orden " ?oid "): Envío estándar GRATIS por compra mayor a $4000." crlf)
   ;; Se actualiza la bandera para que no se repita
   (modify ?o (promo-envio-aplicada yes))
)

;; Regla 15: Promoción Puntos Dobles BBVA
(defrule promo-banco-bbva
   (orden-compra (orden-id ?oid) (tipo-pago tarjeta) (tdc-id ?tidc))
   (tarjeta-credito (tdc-id ?tidc) (banco bbva))
   =>
   (printout t "OFERTA BANCARIA (Orden " ?oid "): ¡Tu compra con BBVA genera Puntos Dobles!" crlf)
)

;; Regla 16: Oferta 3x2 en Accesorios Genéricos
(defrule oferta-3x2-accesorios-genericos
   (linea-item (orden-id ?oid) (sku ?sku1) (cantidad ?q1 & :(>= ?q1 2)))
   (accesorio (sku ?sku1) (marca generico))
   =>
   (printout t "OFERTA APLICADA (Orden " ?oid "): En la compra de 2 accesorios genéricos, el 3ro es GRATIS (aplicar en caja)." crlf)
)


;; --- REGLAS DE MANEJO DE STOCK Y CÁLCULO DE TOTAL ---

;; Regla 17: Manejo de Falta de Stock
(defrule falta-stock
   (declare (salience 15)) ; Prioridad muy alta
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

;; Regla 18: Procesar Item Smartphone (Stock y Total)
(defrule procesar-item-smartphone
   (declare (salience 10))
   ?o <- (orden-compra (orden-id ?oid) (estado procesando) (total ?t))
   ?li <- (linea-item (orden-id ?oid) (sku ?sku) (cantidad ?q) (precio-unitario ?p))
   ?prod <- (smartphone (sku ?sku) (stock ?s & :(>= ?s ?q)))
   =>
   (bind ?subtotal (* ?p ?q))
   (printout t "CÁLCULO (Orden " ?oid "): Sumando $" ?subtotal crlf)
   (printout t "STOCK (Actualizando): " ?q " unidades de " ?sku " (Stock anterior: " ?s "). Nuevo stock: " (- ?s ?q) crlf)
   (modify ?o (total (+ ?t ?subtotal)))
   (modify ?prod (stock (- ?s ?q)))
   (retract ?li) ; Item procesado
)

;; Regla 19: Procesar Item Computador (Stock y Total)
(defrule procesar-item-computador
   (declare (salience 10))
   ?o <- (orden-compra (orden-id ?oid) (estado procesando) (total ?t))
   ?li <- (linea-item (orden-id ?oid) (sku ?sku) (cantidad ?q) (precio-unitario ?p))
   ?prod <- (computador (sku ?sku) (stock ?s & :(>= ?s ?q)))
   =>
   (bind ?subtotal (* ?p ?q))
   (printout t "CÁLCULO (Orden " ?oid "): Sumando $" ?subtotal crlf)
   (printout t "STOCK (Actualizando): " ?q " unidades de " ?sku " (Stock anterior: " ?s "). Nuevo stock: " (- ?s ?q) crlf)
   (modify ?o (total (+ ?t ?subtotal)))
   (modify ?prod (stock (- ?s ?q)))
   (retract ?li)
)

;; Regla 20: Procesar Item Accesorio (Stock y Total)
(defrule procesar-item-accesorio
   (declare (salience 10))
   ?o <- (orden-compra (orden-id ?oid) (estado procesando) (total ?t))
   ?li <- (linea-item (orden-id ?oid) (sku ?sku) (cantidad ?q) (precio-unitario ?p))
   ?prod <- (accesorio (sku ?sku) (stock ?s & :(>= ?s ?q)))
   =>
   (bind ?subtotal (* ?p ?q))
   (printout t "CÁLCULO (Orden " ?oid "): Sumando $" ?subtotal crlf)
   (printout t "STOCK (Actualizando): " ?q " unidades de " ?sku " (Stock anterior: " ?s "). Nuevo stock: " (- ?s ?q) crlf)
   (modify ?o (total (+ ?t ?subtotal)))
   (modify ?prod (stock (- ?s ?q)))
   (retract ?li)
)

;; Regla 21: Marcar Orden como Completada
(defrule completar-orden
   (declare (salience -20)) ; Prioridad más baja
   ?o <- (orden-compra (orden-id ?oid) (estado procesando) (total ?t))
   (not (linea-item (orden-id ?oid))) ; No quedan items por procesar
   =>
   (modify ?o (estado completada))
   (bind ?total-redondeado (/ (integer (* 100 ?t)) 100.0))
   (printout t "ESTADO (Orden " ?oid "): COMPLETADA. Total final: $" ?total-redondeado crlf)
)
